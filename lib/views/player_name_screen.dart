import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerNameScreen extends StatefulWidget {
  final User user;

  PlayerNameScreen({required this.user});

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
                  await _firestore.collection('users').doc(widget.user.uid).update({
                    'playerName': playerName,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

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
