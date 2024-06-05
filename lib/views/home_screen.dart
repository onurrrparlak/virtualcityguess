import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/services/auth_service.dart';
import 'package:virtualcityguess/services/firestore_service.dart';
import 'package:virtualcityguess/views/edit_profile.dart';
import 'package:virtualcityguess/views/host_lobby_screen.dart';
import 'package:virtualcityguess/views/player_lobby_screen.dart';
import 'package:virtualcityguess/views/room_settings_screen.dart';
import 'package:virtualcityguess/models/user_model.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  String _roomId = '';

  Future<void> _logout() async {
    await _authService.signOut(context);
    Navigator.pushReplacementNamed(context, '/login');
  }


  void _joinRoom() async {
    final userModel = Provider.of<UserModel>(context, listen: false);
    if (_roomId.isNotEmpty && userModel.playerName!.isNotEmpty) {
      try {
        await _firestoreService.joinRoom(
            context, _roomId, userModel.playerName!);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerLobbyScreen(
              roomId: _roomId,
              currentPlayerName: userModel.playerName!,
            ),
          ),
        );
      } catch (e) {
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
    final userModel = Provider.of<UserModel>(context);
    print('Email: ${userModel.email}');
    print('Player Name: ${userModel.playerName}');
    print('Rating: ${userModel.rating}');
    print('Premium: ${userModel.premium}');

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: 0.1 * MediaQuery.of(context).size.height),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${userModel.playerName}'),
            TextField(
              decoration: InputDecoration(labelText: 'Room ID'),
              onChanged: (value) {
                setState(() {
                  _roomId = value;
                });
              },
            ),
            SizedBox(height: 0.1 * MediaQuery.of(context).size.height),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RoomSettingsScreen()),
                );
              },
              child: Text('Create Room'),
            ),
            SizedBox(height: 0.05 * MediaQuery.of(context).size.height),
            ElevatedButton(
              onPressed: _joinRoom,
              child: Text('Join Room'),
            ),
             ElevatedButton(
              onPressed: () {
                Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EditProfilePage()),
            );
              },
              child: Text('Edit Profile'),
              
            ),
            ElevatedButton(
              onPressed: _logout,
              child: Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
