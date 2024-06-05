import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:virtualcityguess/models/user_model.dart';
 // Import the UserModel

class PlayerNameScreen extends StatefulWidget {
  final User user;
  final UserModel userModel; // Add UserModel here

  PlayerNameScreen({required this.user, required this.userModel}); // Add UserModel to constructor

  @override
  _PlayerNameScreenState createState() => _PlayerNameScreenState();
}

class _PlayerNameScreenState extends State<PlayerNameScreen> {
  final TextEditingController playerNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: playerNameController,
              decoration: InputDecoration(labelText: "Player Name"),
            ),
            ElevatedButton(
              onPressed: () async {
                String playerName = playerNameController.text;
                if (playerName.isNotEmpty) {
                  // Update Firestore
                  await _firestore.collection('users').doc(widget.user.uid).update({
                    'playerName': playerName,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  // Update the UserModel
                  await widget.userModel.updatePlayerName(playerName);

                  // Navigate to home screen after setting player name
                  Navigator.pushReplacementNamed(context, '/home');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Player name cannot be empty"),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
