import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

 Future<String> createRoom(String hostName) async {
  String roomId = _generateRoomId();
  await _firestore.collection('rooms').doc(roomId).set({
    'host': hostName, // Include the name of the host
    'players': {
      hostName: 0 // Initialize host's score with 0
    },
    'currentTargetIndex': 0,
    'gameStarted': false,
    'submittedPlayers': {}, // Initialize submittedPlayers
  });
  return roomId;
}


 Future<void> kickPlayer(String roomId, String playerName) async {
    DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
    await roomRef.update({
      'players.$playerName': FieldValue.delete(), // Remove player from the list
    });
  }

  Future<void> banPlayer(String roomId, String playerName) async {
    DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
    await roomRef.update({
      'bannedPlayers.$playerName': true, // Add player to the banned list
      'players.$playerName': FieldValue.delete(), // Remove player from the list
    });
  }

  Future<void> joinRoom(String roomId, String playerName) async {
    DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
    DocumentSnapshot roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      throw Exception('Room does not exist');
    }

    bool gameStarted = roomSnapshot['gameStarted'];
    if (gameStarted) {
      throw Exception('Game has already started, you cannot join.');
    }

    Map<String, int> players = Map<String, int>.from(roomSnapshot['players']);
    if (!players.containsKey(playerName)) {
      players[playerName] = 0; // Start the player with 0 points
      await roomRef.update({'players': players});
    }
  }

  Future<void> updatePoints(
      String roomId, String playerName, int points) async {
    DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) {
        throw Exception('Room does not exist');
      }
      Map<String, int> players = Map<String, int>.from(roomSnapshot['players']);
      if (players.containsKey(playerName)) {
        players[playerName] = points;
        transaction.update(roomRef, {'players': players});
      }
    });
  }

  // Update the startGame function to reset submittedPlayers
  Future<void> startGame(String roomId) async {
    DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
    await roomRef.update({
      'gameStarted': true,
      'submittedPlayers': {}, // Reset submittedPlayers when the game starts
    });
  }

  Future<List<String>> getJoinedPlayers(String roomId) async {
    DocumentSnapshot roomSnapshot =
        await _firestore.collection('rooms').doc(roomId).get();

    if (!roomSnapshot.exists) {
      throw Exception('Room does not exist');
    }

    Map<String, dynamic> players = Map<String, dynamic>.from(roomSnapshot['players']);
    return players.keys.toList();
  }

  // Add a new function to update player submission status
Future<void> updatePlayerSubmissionStatus(String roomId, String playerName, bool submitted) async {
  DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
  await roomRef.update({
    'submittedPlayers.$playerName': submitted,
  });
}

// Add a new function to check if all players have submitted their locations
Future<bool> checkAllPlayersSubmitted(String roomId) async {
  DocumentSnapshot roomSnapshot = await _firestore.collection('rooms').doc(roomId).get();
  if (!roomSnapshot.exists) {
    throw Exception('Room does not exist');
  }
  Map<String, dynamic> submittedPlayers = Map<String, dynamic>.from(roomSnapshot['submittedPlayers']);
  if (submittedPlayers.length == 0) {
    return false; // No players have submitted
  }
  return submittedPlayers.values.every((submitted) => submitted == true);
}

  Stream<DocumentSnapshot> getRoomStream(String roomId) {
    return _firestore.collection('rooms').doc(roomId).snapshots();
  }

  Future<void> deleteRoom(String roomId) async {
    await _firestore.collection('rooms').doc(roomId).delete();
  }

  String _generateRoomId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      List.generate(10, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
}
