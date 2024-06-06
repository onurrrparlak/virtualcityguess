import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/services/timer_service.dart';

class FirestoreService {
  int _roundDuration = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createRoom(BuildContext context,
      String hostName, int numberOfRounds, int roundDuration) async {
    String roomId = _generateRoomId();
    await _firestore.collection('rooms').doc(roomId).set({
      'host': hostName,
      'players': {hostName: 0},
      'numberOfRounds': numberOfRounds,
      'roundDuration': roundDuration,
      'currentTarget': 0,
      'gameStarted': false,
      'submittedPlayers': {},
    });
    Provider.of<TimerService>(context, listen: false).updateTimerDuration(roundDuration);
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

  Future<void> joinRoom(BuildContext context, roomId, String playerName) async {
    DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
    DocumentSnapshot roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      throw Exception('Room does not exist');
    }

    _roundDuration = roomSnapshot['roundDuration'];

    Provider.of<TimerService>(context, listen: false).updateTimerDuration(_roundDuration);

   

    bool gameStarted = roomSnapshot['gameStarted'];
    if (gameStarted) {
      throw Exception('Game has already started, you cannot join.');
    }

    Map<String, dynamic> bannedPlayers = Map<String, dynamic>.from(
      (roomSnapshot.data() as Map<String, dynamic>? ?? {})['bannedPlayers'] ??
          {},
    );

    if (bannedPlayers.isNotEmpty && bannedPlayers.containsKey(playerName)) {
      throw Exception('You are banned from joining this room');
    }

    Map<String, int> players = Map<String, int>.from(roomSnapshot['players']);
    if (players.length >= 16) {
      throw Exception('The room is already full, you cannot join.');
    }

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
      Map<String, dynamic> roomData =
          roomSnapshot.data() as Map<String, dynamic>;
      Map<String, dynamic> players =
          Map<String, dynamic>.from(roomData['players']);
      if (players.containsKey(playerName)) {
        // Add points earned in this round to the total points
     
        int totalPoints = players[playerName] + points;
     
        players[playerName] = totalPoints;
        // Update total points in Firestore
        transaction.update(roomRef, {'players.$playerName': totalPoints});
      }
    });
  }

  Future<List<MapEntry<String, int>>> fetchAndSortPlayersByPoints(
      String roomId) async {
    DocumentSnapshot roomSnapshot =
        await _firestore.collection('rooms').doc(roomId).get();

    if (!roomSnapshot.exists) {
      throw Exception('Room does not exist');
    }

    // Fetch players and their points
    Map<String, int> players = Map<String, int>.from(roomSnapshot['players']);

    // Sort players by points in descending order
    List<MapEntry<String, int>> sortedPlayers = players.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedPlayers;
  }

  Future<String?> fetchCurrentTarget(String roomId) async {
    try {
      // Get room document reference
      DocumentReference roomRef =
          FirebaseFirestore.instance.collection('rooms').doc(roomId);

      // Get room snapshot
      DocumentSnapshot roomSnapshot = await roomRef.get();

      // Check if room exists
      if (!roomSnapshot.exists) {
        throw Exception('Room does not exist');
      }

      // Get current target from room snapshot
      String? currentTarget = roomSnapshot['currentTarget'];

      return currentTarget;
    } catch (e) {
      print("An error occurred while fetching current target: $e");
      return null; // Return null if there's any error
    }
  }

  Future<List<String>> getJoinedPlayers(String roomId) async {
    DocumentSnapshot roomSnapshot =
        await _firestore.collection('rooms').doc(roomId).get();

    if (!roomSnapshot.exists) {
      throw Exception('Room does not exist');
    }

    Map<String, dynamic> players =
        Map<String, dynamic>.from(roomSnapshot['players']);
    return players.keys.toList();
  }

  // Add a new function to update player submission status
  Future<void> updatePlayerSubmissionStatus(
      String roomId, String playerName, bool submitted) async {
    DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
    await roomRef.update({
      'submittedPlayers.$playerName': submitted,
    });
  }

// Add a new function to check if all players have submitted their locations

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
