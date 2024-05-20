import 'package:flutter/material.dart';
import 'package:virtualcityguess/main.dart';
import 'package:virtualcityguess/services/room.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _playerName = '';
  String _roomId = '';

 void _createRoom() async {
  if (_playerName.isNotEmpty) {
    String roomId = await _firestoreService.createRoom();
    await _firestoreService.joinRoom(roomId, _playerName);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(roomId: roomId, playerName: _playerName, isHost: true,),
      ),
    );
  }
}



void _joinRoom() async {
  if (_roomId.isNotEmpty && _playerName.isNotEmpty) {
    try {
      await _firestoreService.joinRoom(_roomId, _playerName);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapScreen(roomId: _roomId, playerName: _playerName, isHost: false),
        ),
      );
    } on Exception catch (e) {
      if (e.toString() == 'Exception: Room does not exist') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Room does not exist'),
        ));
      } else if (e.toString() == 'Exception: Game has already started, you cannot join.') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Game has already started, you cannot join.'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('An error occurred'),
        ));
      }
    }
  }
}










  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
            TextField(
              decoration: InputDecoration(labelText: 'Room ID'),
              onChanged: (value) {
                setState(() {
                  _roomId = value;
                });
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createRoom,
              child: Text('Create Room'),
            ),
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
