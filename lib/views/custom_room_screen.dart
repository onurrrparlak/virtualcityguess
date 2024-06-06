import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/services/firestore_service.dart';
import 'package:virtualcityguess/views/player_lobby_screen.dart';
import 'package:virtualcityguess/models/user_model.dart';

class CustomRoomsScreen extends StatefulWidget {
  const CustomRoomsScreen({Key? key}) : super(key: key);

  @override
  _CustomRoomsScreenState createState() => _CustomRoomsScreenState();
}

class _CustomRoomsScreenState extends State<CustomRoomsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    try {
      List<Map<String, dynamic>> rooms = await _firestoreService.fetchAvailableRooms();
      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching rooms: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _joinRoom(String roomId) async {
    final userModel = Provider.of<UserModel>(context, listen: false);
    if (roomId.isNotEmpty && userModel.playerName!.isNotEmpty) {
      try {
        await _firestoreService.joinRoom(context, roomId, userModel.playerName!);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerLobbyScreen(
              roomId: roomId,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Rooms'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _rooms.length,
              itemBuilder: (context, index) {
                final room = _rooms[index];
                return ListTile(
                  title: Text('Room ID: ${room['roomId']}'),
                  subtitle: Text('Host: ${room['host']}'),
                  trailing: ElevatedButton(
                    onPressed: () => _joinRoom(room['roomId']),
                    child: const Text('Join Room'),
                  ),
                );
              },
            ),
    );
  }
}
