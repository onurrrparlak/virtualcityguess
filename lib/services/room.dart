import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createRoom() async {
    String roomId = _generateRoomId();
    await _firestore.collection('rooms').doc(roomId).set({
      'players': [],
      'currentTargetIndex': 0,
      'gameStarted': false, // Add this line
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
      List players = roomSnapshot['players'];
      if (!players.contains(playerName)) {
        players.add(playerName);
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