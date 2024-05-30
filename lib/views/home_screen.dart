import 'package:flutter/material.dart';
import 'package:virtualcityguess/services/firestore_service.dart';
import 'package:virtualcityguess/views/host_lobby_screen.dart';
import 'package:virtualcityguess/views/player_lobby_screen.dart';
import 'package:virtualcityguess/views/room_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _playerName = '';
  String _roomId = '';

  void _joinRoom() async {
    if (_roomId.isNotEmpty && _playerName.isNotEmpty) {
      try {
        await _firestoreService.joinRoom(context, _roomId, _playerName);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerLobbyScreen(
              roomId: _roomId,
              currentPlayerName: _playerName,
            ),
          ),
        );
      } catch (e) {
        // Handle the exception here
        print('Error joining room: $e');
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('${e.toString().replaceFirst('Exception: ', '')}'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual City Guess'),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 0.1 * screenHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Player Name'),
              onChanged: (value) {
                setState(() {
                  _playerName = value;
                });
              },
            ),
            SizedBox(height: 0.05 * screenHeight),
            TextField(
              decoration: InputDecoration(labelText: 'Room ID'),
              onChanged: (value) {
                setState(() {
                  _roomId = value;
                });
              },
            ),
            SizedBox(height: 0.1 * screenHeight),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RoomSettingsScreen()),
                );
              },
              child: Text('Create Room'),
            ),
            SizedBox(height: 0.05 * screenHeight),
            ElevatedButton(
              onPressed: _joinRoom,
              child: Text('Join Room'),
            ),
          ],
        ),
      ),
    );
  }
}
