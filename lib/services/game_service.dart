import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:virtualcityguess/models/locations.dart';

class GameService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _currentTarget;
  String? get currentTarget => _currentTarget;

  Future<void> listenToRoomUpdates(String roomId) async {
    _firestore.collection('rooms').doc(roomId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        _currentTarget = snapshot.data()?['currentTarget'];
        notifyListeners();
      }
    });
  }

  Future<void> startGame(String roomId) async {
    try {
      print("Starting game with roomId: $roomId");

      // Get a snapshot of your collection
      QuerySnapshot collectionSnapshot =
          await FirebaseFirestore.instance.collection('locations').get();

      // Check if any document is found
      if (collectionSnapshot.docs.isEmpty) {
        throw Exception('No documents found in the collection');
      }

      // Generate a random index
      int randomIndex = Random().nextInt(collectionSnapshot.docs.length);

      // Get the document that falls under the random index
      DocumentSnapshot randomDocument = collectionSnapshot.docs[randomIndex];

      print("Random document selected: ${randomDocument.id}");

      // Extract data from the randomly selected document
      // Replace 'LocationModel' with the actual model you're using
      LocationModel randomLocation =
          LocationModel.fromDocumentSnapshot(randomDocument);

      // Update roomId document with the selected random document ID
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
      await roomRef.update({
        'currentTarget': randomDocument.id,
        'usedLocations': FieldValue.arrayUnion([randomDocument.id])
      });

      // You can continue with your logic here...

      print("Game started successfully!");
    } catch (e) {
      print("An error occurred while starting the game: $e");
      throw e; // Rethrow the exception to propagate it upwards
    }
  }
}