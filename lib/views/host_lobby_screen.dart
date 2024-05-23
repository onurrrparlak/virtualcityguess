import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:virtualcityguess/services/game_service.dart';
import 'package:virtualcityguess/views/game_screen.dart';
import 'package:virtualcityguess/services/firestore_service.dart';



class HostLobbyScreen extends StatelessWidget {
  final String roomId;

  HostLobbyScreen({required this.roomId});

  void _startGame(BuildContext context) async {
  
  await GameService().startGame(roomId);
  
  // Navigate to the GameScreen
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => GameScreen(
        roomId: roomId,
        playerName: 'Host', // Assuming 'Host' is the host's player name
        isHost: true,
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
     
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

                  return Column(
                    children: [
                      Expanded(
                        flex: 7, // 70% of the available space
                        child: ListView.builder(
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
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            String playerName = joinedPlayers[index];
                                            FirestoreService()
                                                .kickPlayer(roomId, playerName);
                                          },
                                          child: SizedBox(
                                            width: screenWidth * 0.15,
                                            height: screenHeight * 0.05,
                                            child: Center(child: Text('Kick')),
                                          ),
                                        ),
                                        SizedBox(width: screenWidth * 0.02),
                                        ElevatedButton(
                                          onPressed: () {
                                            // Logic to ban player
                                            String playerName = joinedPlayers[index];
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text('Ban Player'),
                                                  content: Text(
                                                      'Are you sure you want to ban $playerName?'),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop(); // Close the dialog
                                                      },
                                                      child: Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        FirestoreService().banPlayer(
                                                            roomId, playerName);
                                                        Navigator.of(context)
                                                            .pop(); // Close the dialog
                                                      },
                                                      child: Text('Ban'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          child: SizedBox(
                                            width: screenWidth * 0.15,
                                            height: screenHeight * 0.05,
                                            child: Center(child: Text('Ban')),
                                          ),
                                        ),
                                      ],
                                    ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        flex: 3, // 30% of the available space
                        child: ElevatedButton(
                          onPressed: () {
                           _startGame(context);
                          },
                          child: Text('Start Game'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
