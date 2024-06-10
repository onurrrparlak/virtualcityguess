// lib/services/matchmaking_service.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:virtualcityguess/models/locations.dart';
import 'package:virtualcityguess/views/1v1_game_screen.dart';

class MatchmakingService with ChangeNotifier{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> startSearching(
      BuildContext context, String playerName, int rating) async {
    print('Searching for match for player: $playerName');

    // Add player to matchmaking collection
    await _firestore.collection('matchmaking').doc(playerName).set({
      'playerName': playerName,
      'rating': rating,
    });

    // Set up listener for roomId updates
    _listenForRoomId(context, playerName);

    // Find opponent
    await _findOpponent(context, playerName, rating);
  }

  Future<void> _findOpponent(
      BuildContext context, String playerName, int rating) async {
    print('Looking for opponent for player: $playerName');

    int minRating = rating - 200;
    int maxRating = rating + 200;

    QuerySnapshot<Map<String, dynamic>> potentialMatches = await _firestore
        .collection('matchmaking')
        .where('rating', isGreaterThanOrEqualTo: minRating)
        .where('rating', isLessThanOrEqualTo: maxRating)
        .get();

    for (var doc in potentialMatches.docs) {
      if (doc.id != playerName) {
        print('Found a potential match for $playerName: ${doc.id}');
        var matchedPlayer = doc.data();
        String matchedPlayerId = doc.id;

        // Generate a room ID
        String roomId = _generateRoomId();
        print('Generated Room ID: $roomId');

        // Create a room with the matched players
        await _createRoom(roomId, playerName, matchedPlayer['playerName']);

        // Update both players' documents with roomId
        await _firestore.collection('matchmaking').doc(playerName).update({
          'roomId': roomId,
        });

        await _firestore.collection('matchmaking').doc(matchedPlayerId).update({
          'roomId': roomId,
        });

        // Remove both players from matchmaking collection
        await _firestore.collection('matchmaking').doc(playerName).delete();
        await _firestore.collection('matchmaking').doc(matchedPlayerId).delete();

        return;
      }
    }

    // If no match found immediately, wait and try again
    print('No immediate match found for $playerName. Retrying in 5 seconds.');
    Future.delayed(
        Duration(seconds: 5), () => _findOpponent(context, playerName, rating));
  }

  void _listenForRoomId(BuildContext context, String playerName) {
    _firestore.collection('matchmaking').doc(playerName).snapshots().listen(
      (snapshot) {
        if (snapshot.exists) {
          var data = snapshot.data();
          if (data != null && data.containsKey('roomId')) {
            String roomId = data['roomId'];
            print('Room ID $roomId received for player $playerName');

            // Navigate to game screen with room ID
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OneonONeGameScreen(
                  roomId: roomId,
                  playerName: playerName,
                  isHost: false,
                ),
              ),
            );
          }
        }
      },
    );
  }

  String _generateRoomId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      List.generate(10, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  Future<void> _createRoom(
    String roomId, String playerName1, String playerName2) async {
  print('Creating room with players: $playerName1, $playerName2');

  try {
    // Get a snapshot of the locations collection
    QuerySnapshot collectionSnapshot = await _firestore.collection('locations').get();

    // Check if any document is found in the collection
    if (collectionSnapshot.docs.isEmpty) {
      throw Exception('No documents found in the collection');
    }

    // Generate a random index
    int randomIndex = Random().nextInt(collectionSnapshot.docs.length);

    // Get the document that falls under the random index
    DocumentSnapshot randomDocument = collectionSnapshot.docs[randomIndex];

    // Extract data from the randomly selected document
    LocationModel randomLocation = LocationModel.fromDocumentSnapshot(randomDocument);

    // Initialize submittedPlayers map
    Map<String, bool> submittedPlayers = {
      playerName1: false,
      playerName2: false,
    };

    // Create the room data with the randomly selected target
    Map<String, dynamic> data = {
      'players': {playerName1: 0, playerName2: 0},
      'numberOfRounds': 5,
      'roundDuration': 60,
      'currentTarget': randomDocument.id,
      'gameStarted': true,
      'submittedPlayers': submittedPlayers,
      'usedLocations': [randomDocument.id],
    };

    // Set the room data in Firestore
    await _firestore.collection('rooms').doc(roomId).set(data);
    

    print('Room created successfully with random target: ${randomDocument.id}');
  } catch (e) {
    print('Error creating room: $e');
    rethrow; // Rethrow the exception to propagate it upwards
  }
}

 Future<void> nextRound(String roomId) async {
    try {
      // Get the current room data
      DocumentSnapshot roomSnapshot =
          await _firestore.collection('rooms').doc(roomId).get();
      var roomData = roomSnapshot.data() as Map<String, dynamic>;
      List<dynamic> usedLocations = roomData['usedLocations'] ?? [];

      // Get the current round number and total number of rounds
      int currentRound = roomData['currentRound'] ?? 0;
      int numberOfRounds = roomData['numberOfRounds'] ?? 0;

      // Check if the current round exceeds the total number of rounds
      if (currentRound >= numberOfRounds) {
        // If the current round exceeds or equals the total number of rounds,
        // you can stop the game or take any other necessary actions.
        // For example, you can set the 'gameEnded' field to true.
        print("gameendedbrom");
        await _firestore.collection('rooms').doc(roomId).update({
          'gameEnded': true,
        });
        return; // Exit the function since the game has ended
      }

      // Get a snapshot of your collection
      QuerySnapshot collectionSnapshot =
          await FirebaseFirestore.instance.collection('locations').get();

      // Check if any document is found
      if (collectionSnapshot.docs.isEmpty) {
        throw Exception('No documents found in the collection');
      }

      // Find a new unused location
      DocumentSnapshot? newLocation;
      do {
        int randomIndex = Random().nextInt(collectionSnapshot.docs.length);
        DocumentSnapshot potentialLocation =
            collectionSnapshot.docs[randomIndex];
        if (!usedLocations.contains(potentialLocation.id)) {
          newLocation = potentialLocation;
        }
      } while (newLocation == null);

      // Extract data from the randomly selected document
      LocationModel randomLocation =
          LocationModel.fromDocumentSnapshot(newLocation);

      // Update roomId document with the selected random document ID and increment the current round
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
      // Reset submitted players
      Map<String, dynamic> submittedPlayersReset = {};
      Map<String, dynamic>? submittedPlayers = roomData['submittedPlayers'];
      if (submittedPlayers != null) {
        submittedPlayers.forEach((playerId, _) {
          submittedPlayersReset[playerId] = false;
        });
      }
      await roomRef.update({
        'currentTarget': newLocation.id,
        'usedLocations': FieldValue.arrayUnion([newLocation.id]),
        'submittedPlayers': submittedPlayersReset,
        'currentRound': currentRound + 1, // Increment the current round
      });
     


      // Wait for 3 seconds before notifying listeners
      await Future.delayed(const Duration(seconds: 3));

      // Notify listeners or take any other action you need
      notifyListeners();
    } catch (e) {
      rethrow; // Rethrow the exception to propagate it upwards
    }
  }

}
