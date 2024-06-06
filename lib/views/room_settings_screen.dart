import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/models/user_model.dart';
import 'package:virtualcityguess/services/firestore_service.dart';
import 'package:virtualcityguess/views/host_lobby_screen.dart';

class RoomSettingsScreen extends StatefulWidget {
  const RoomSettingsScreen({super.key});

  @override
  _RoomSettingsScreenState createState() => _RoomSettingsScreenState();
}
class _RoomSettingsScreenState extends State<RoomSettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _roomId = '';
  bool _isButtonEnabled = true;
  int _numberOfRounds = 1;
  int _timerDuration = 30;
  bool _isPrivateRoom = false; // Add this line

void _createRoom() async {
  final userModel = Provider.of<UserModel>(context, listen: false);
  if (userModel.playerName != null && userModel.playerName!.isNotEmpty) {
    String roomId = await _firestoreService.createRoom(
      context,
      userModel.playerName!,
      _numberOfRounds,
      _timerDuration,
      _isPrivateRoom ? true : null, // Pass true only if _isPrivateRoom is true
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HostLobbyScreen(
          roomId: roomId,
          playerName: userModel.playerName!,
        ),
      ),
    );
  }
}




  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final userModel = Provider.of<UserModel>(context);

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 0.1 * screenHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Player Name: ${userModel.playerName ?? 'Loading...'}'),
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
              items: [5, 30, 60, 90].map((duration) {
                return DropdownMenuItem<int>(
                  value: duration,
                  child: Text('$duration Seconds'),
                );
              }).toList(),
            ),
            SizedBox(height: 0.05 * screenHeight), // Adjust the spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Make Room Private'),
                Checkbox(
                  value: _isPrivateRoom,
                  onChanged: (value) {
                    setState(() {
                      _isPrivateRoom = value!;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 0.1 * screenHeight),
            ElevatedButton(
              onPressed: _isButtonEnabled ? () {
                setState(() {
                  _isButtonEnabled = false;
                });
                _createRoom();
              } : null,
              child: const Text('Create Room'),
            ),
          ],
        ),
      ),
    );
  }
}
