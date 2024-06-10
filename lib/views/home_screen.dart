import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/models/app_localizations.dart';
import 'package:virtualcityguess/services/auth_service.dart';
import 'package:virtualcityguess/services/firestore_service.dart';
import 'package:virtualcityguess/services/matchmaking_service.dart';
import 'package:virtualcityguess/views/app_settings.dart';
import 'package:virtualcityguess/views/custom_room_screen.dart';
import 'package:virtualcityguess/views/edit_profile.dart';
import 'package:virtualcityguess/views/game_screen.dart';
import 'package:virtualcityguess/views/player_lobby_screen.dart';
import 'package:virtualcityguess/views/room_settings_screen.dart';
import 'package:virtualcityguess/models/user_model.dart';
import 'package:virtualcityguess/views/waiting_lobby.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
              title: const Text('Error'),
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
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
    final AppLocalizations? appLocalizations = AppLocalizations.of(context);
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
            Text(
                '${appLocalizations!.translate('welcome')}, ${userModel.playerName}'), // Use translated string for welcome message
            TextField(
              decoration: InputDecoration(
                  labelText: '${appLocalizations.translate('roomid')}'),
              onChanged: (value) {
                setState(() {
                  _roomId = value;
                });
              },
            ),
           ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WaitingLobby(userModel: userModel),
      ),
    );
  },
  child: Text('1v1 Ranked'),
),


            SizedBox(height: 0.1 * MediaQuery.of(context).size.height),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RoomSettingsScreen()),
                );
              },
              child: Text('${appLocalizations!.translate('createroom')}'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CustomRoomsScreen()),
                );
              },
              child: Text('${appLocalizations.translate('customrooms')}'),
            ),
            SizedBox(height: 0.05 * MediaQuery.of(context).size.height),
            ElevatedButton(
              onPressed: _joinRoom,
              child: Text('${appLocalizations.translate('joinroom')}'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EditProfilePage()),
                );
              },
              child: Text('${appLocalizations.translate('editprofile')}'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LanguageSelectionScreen()),
                );
              },
              child: Text('${appLocalizations!.translate('changelanguage')}'),
            ),
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              child: Text('${appLocalizations.translate('logout')}'),
            ),
          ],
        ),
      ),
    );
  }
}
