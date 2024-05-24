import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:virtualcityguess/models/locations.dart';

import 'package:latlong2/latlong.dart';

class GameService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _currentTarget;
  String? _videoUrl;
  String? get currentTarget => _currentTarget;
  String? get videoUrl => _videoUrl;

 Future<void> listenToRoomUpdates(String roomId) async {
  _firestore.collection('rooms').doc(roomId).snapshots().listen((snapshot) async {
    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;


      _currentTarget = data['currentTarget'];
     
      notifyListeners();
      await fetchVideoUrl();

      // Check if 'submittedPlayers' exists and is a list
      List<dynamic> submittedPlayers = [];
      if (data.containsKey('submittedPlayers') && data['submittedPlayers'] is List) {
        submittedPlayers = data['submittedPlayers'];
      } else {
       
      }

      // Check if 'players' exists and is a list
      List<dynamic> players = [];
      if (data.containsKey('players') && data['players'] is List) {
        players = data['players'];
      } else {
        
      }

   

      if (submittedPlayers.length == players.length && players.isNotEmpty) {
       
        // Notify listeners or take any other action you need
        notifyListeners();
      }
    } else {
    
    }
  });
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

      // Check if any document is found
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

      // Update roomId document with the selected random document ID
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
      await roomRef.update({
        'currentTarget': randomDocument.id,
        'usedLocations': FieldValue.arrayUnion([randomDocument.id])
      });

      // You can continue with your logic here...

     
    } catch (e) {
    
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
      String roomId, String playerName, LatLng userLocation) async {
    try {
      // Update the submittedPlayers field
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
      await roomRef.update({
        'submittedPlayers': FieldValue.arrayUnion([playerName])
      });

      // Calculate distance, etc. if needed

      print("$playerName submitted location successfully!");
    } catch (e) {
      print("An error occurred while submitting location: $e");
      throw e;
    }
  }
}
