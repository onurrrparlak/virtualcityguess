import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createRoom() async {
    String roomId = _generateRoomId();
    await _firestore.collection('rooms').doc(roomId).set({
      'players': {}, // Change to an empty map
      'currentTargetIndex': 0,
      'gameStarted': false,
    });
    return roomId;
  }

  Future<void> joinRoom(String roomId, String playerName) async {
    DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) {
        throw Exception('Room does not exist');
      }
      Map<String, int> players = Map<String, int>.from(roomSnapshot['players']);
      if (!players.containsKey(playerName)) {
        players[playerName] = 0; // Start the player with 0 points
        transaction.update(roomRef, {'players': players});
      }
    });
  }

  Future<void> updatePoints(String roomId, String playerName, int points) async {
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


  Future<void> startGame(String roomId) async {
    DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
    await roomRef.update({'gameStarted': true});
  }

  Stream<DocumentSnapshot> getRoomStream(String roomId) {
    return _firestore.collection('rooms').doc(roomId).snapshots();
  }

  String _generateRoomId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      List.generate(10, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
}
