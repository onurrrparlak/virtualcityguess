import 'package:flutter/material.dart';
import 'package:virtualcityguess/services/firestore_service.dart';
import 'package:virtualcityguess/views/host_lobby_screen.dart';
import 'package:virtualcityguess/views/player_lobby_screen.dart';

class RoomSettingsScreen extends StatefulWidget {
  @override
  _RoomSettingsScreenState createState() => _RoomSettingsScreenState();
}

class _RoomSettingsScreenState extends State<RoomSettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _playerName = '';
  String _roomId = '';
  int _numberOfRounds = 1;
  int _timerDuration = 30;

  void _createRoom() async {
    if (_playerName.isNotEmpty) {
      String roomId = await _firestoreService.createRoom(
        context,
        _playerName,
        _numberOfRounds,
        _timerDuration,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HostLobbyScreen(
            roomId: roomId,
            playerName: _playerName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
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
            DropdownButton<int>(
              value: _numberOfRounds,
              onChanged: (value) {
                setState(() {
                  _numberOfRounds = value!;
                });
              },
              items: List.generate(10, (index) => index + 1).map((rounds) {
                return DropdownMenuItem<int>(
                  value: rounds,
                  child: Text('$rounds Rounds'),
                );
              }).toList(),
            ),
            SizedBox(height: 0.05 * screenHeight),
            DropdownButton<int>(
              value: _timerDuration,
              onChanged: (value) {
                setState(() {
                  _timerDuration = value!;
                });
              },
              items: [5,30, 60, 90].map((duration) {
                return DropdownMenuItem<int>(
                  value: duration,
                  child: Text('$duration Seconds'),
                );
              }).toList(),
            ),
            SizedBox(height: 0.1 * screenHeight),
            ElevatedButton(
              onPressed: _createRoom,
              child: Text('Create Room'),
            ),
          ],
        ),
      ),
    );
  }
}
