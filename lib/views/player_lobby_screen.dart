import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:virtualcityguess/services/room.dart';

class PlayerLobbyScreen extends StatelessWidget {
  final String roomId;
  final String currentPlayerName;

  PlayerLobbyScreen({required this.roomId, required this.currentPlayerName});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Player Lobby'),
      ),
      body: Container(
        constraints: BoxConstraints.expand(),
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    'Room ID: $roomId',
                    style: TextStyle(fontSize: screenWidth * 0.04),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: roomId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Room ID copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
           
            SizedBox(height: screenHeight * 0.03),
            Text(
              'Joined Players:',
              style: TextStyle(fontSize: screenWidth * 0.04),
            ),
            SizedBox(height: screenHeight * 0.015),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirestoreService().getRoomStream(roomId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  Map<String, dynamic> roomData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  List<String> joinedPlayers =
                      roomData['players'].keys.toList();

                  String hostName = roomData['host'];

                  if (joinedPlayers.contains(hostName)) {
                    joinedPlayers.remove(hostName);
                    joinedPlayers.insert(0, hostName);
                  }

                  return ListView.builder(
                    itemCount: joinedPlayers.length,
                    itemBuilder: (context, index) {
                      String playerName = joinedPlayers[index];
                      bool isHost = playerName == hostName;

                      return ListTile(
                        title: Text(playerName),
                        trailing: isHost
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle, color: Colors.green),
                                  SizedBox(width: 5),
                                  Text('(Host)',
                                      style: TextStyle(color: Colors.green)),
                                ],
                              )
                            : Text(
                                playerName == currentPlayerName
                                    ? 'You'
                                    : 'Player',
                                style: TextStyle(
                                  color: playerName == currentPlayerName
                                      ? Colors.blue
                                      : null,
                                ),
                              ),
                      );
                    },
                  );
                },
              ),
            ),
            Center(child: Text('Waiting for host to start the game')),
          ],
        ),
      ),
    );
  }
}
