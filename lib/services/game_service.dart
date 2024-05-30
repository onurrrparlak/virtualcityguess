import 'dart:async'; // Added for delay
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/models/locations.dart';
import 'package:latlong2/latlong.dart';
import 'package:virtualcityguess/provider/location_notifier_provider.dart';
import 'package:virtualcityguess/services/timer_service.dart';
import 'package:virtualcityguess/views/game_result.dart';

class GameService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _currentRound = 1;

  String? _currentTarget;
  String? _videoUrl;

  String? get currentTarget => _currentTarget;
  int? get currentRound => _currentRound;
  String? get videoUrl => _videoUrl;

  Future<void> listenToRoomUpdates(BuildContext context, String roomId) async {
    _firestore
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;

        _currentTarget = data['currentTarget'];

        await fetchVideoUrl();

        // Check if 'submittedPlayers' exists and is a list
        List<dynamic> submittedPlayers = [];
        if (data.containsKey('submittedPlayers') &&
            data['submittedPlayers'] is List) {
          submittedPlayers = data['submittedPlayers'];
        }

        // Check if 'players' exists and is a list
        List<dynamic> players = [];
        if (data.containsKey('players') && data['players'] is List) {
          players = data['players'];
        }

        if (submittedPlayers.length == players.length && players.isNotEmpty) {}


        
        int newRound = data['currentRound'];
        print(newRound);
        if (newRound != _currentRound) {
          print('yeniround: $newRound');
          print('şuanki round: $_currentRound');
          _currentRound = newRound;
          // Reset location submission
          Provider.of<LocationNotifier>(context, listen: false)
              .resetLocationSubmission();
          Provider.of<LocationNotifier>(context, listen: false)
              .resetCurrentLocation();
          Provider.of<TimerService>(context, listen: false).resetTimer();

          Provider.of<LocationNotifier>(context, listen: false).resetMapState();
        }

        // Check if gameStarted changed to false
          bool gameEnded = data['gameEnded'] ?? false;
        if (gameEnded) {
          // Navigate to game result screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => GameResultsScreen(roomId: roomId,),
            ),
          );
        }
      }
    });
  }



  Future<bool> checkAllPlayersSubmitted(String roomId) async {
    DocumentSnapshot roomSnapshot =
        await _firestore.collection('rooms').doc(roomId).get();
    if (!roomSnapshot.exists) {
      throw Exception('Room does not exist');
    }
    Map<String, dynamic> submittedPlayers =
        Map<String, dynamic>.from(roomSnapshot['submittedPlayers']);
    if (submittedPlayers.length == 0) {
      return false; // No players have submitted
    }
    bool allSubmitted =
        submittedPlayers.values.every((submitted) => submitted == true);

    notifyListeners();

    return allSubmitted;
  }

  Future<void> fetchVideoUrl() async {
    if (_currentTarget != null) {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection('locations').doc(_currentTarget).get();
      if (documentSnapshot.exists) {
        var data = documentSnapshot.data() as Map<String, dynamic>;
        _videoUrl = data['videoUrl'];
        notifyListeners();
      }
    }
  }

  Future<void> startGame(String roomId) async {
    try {
      // Get a snapshot of your collection
      QuerySnapshot collectionSnapshot =
          await FirebaseFirestore.instance.collection('locations').get();

      DocumentSnapshot<Object?> roomSnapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .get();

      if (!roomSnapshot.exists) {
        print('Room document does not exist');
        throw Exception('Room document does not exist');
      }

      // Retrieve and print the data in the roomSnapshot, casting it to the correct type
      Map<String, dynamic>? roomData =
          roomSnapshot.data() as Map<String, dynamic>?;
      if (roomData != null) {
        print('Room data: $roomData');
      } else {
        print('Room data is null');
      }

      // Initialize submittedPlayers map
      Map<String, bool> submittedPlayers = {};

      // Populate submittedPlayers with players from roomData
      if (roomData != null && roomData.containsKey('players')) {
        Map<String, dynamic> players = roomData['players'];
        players.forEach((key, value) {
          submittedPlayers[key] = false;
        });
      }

      // Check if any document is found in the collection
      if (collectionSnapshot.docs.isEmpty) {
        throw Exception('No documents found in the collection');
      }

      // Generate a random index
      int randomIndex = Random().nextInt(collectionSnapshot.docs.length);

      // Get the document that falls under the random index
      DocumentSnapshot randomDocument = collectionSnapshot.docs[randomIndex];

      // Extract data from the randomly selected document
      LocationModel randomLocation =
          LocationModel.fromDocumentSnapshot(randomDocument);

      // Update roomId document with the selected random document ID and submittedPlayers
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
      await roomRef.update({
        'currentTarget': randomDocument.id,
        'currentRound': 1,
        'submittedPlayers': submittedPlayers,
        'usedLocations': FieldValue.arrayUnion([randomDocument.id]),
        'gameStarted': true,
      });
    } catch (e) {
      print('Error starting game: $e');
      throw e; // Rethrow the exception to propagate it upwards
    }
  }

  Future<LatLng?> fetchCurrentTargetLatLng() async {
    if (_currentTarget != null) {
      try {
        DocumentSnapshot documentSnapshot =
            await _firestore.collection('locations').doc(_currentTarget).get();
        if (documentSnapshot.exists) {
          var data = documentSnapshot.data() as Map<String, dynamic>;
          double latitude = data['latitude'];
          double longitude = data['longitude'];
          return LatLng(latitude, longitude);
        } else {
          print("Document does not exist");
          return null;
        }
      } catch (e) {
        print("An error occurred while fetching the target's coordinates: $e");
        return null;
      }
    } else {
      print("Current target is null");
      return null;
    }
  }

  Future<void> userSubmitLocation(
      String roomId, String playerName, bool submitted) async {
    DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
    await roomRef.update({
      'submittedPlayers.$playerName': submitted,
    });
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
      await Future.delayed(Duration(seconds: 3));

      // Notify listeners or take any other action you need
      notifyListeners();
    } catch (e) {
      throw e; // Rethrow the exception to propagate it upwards
    }
  }
}
