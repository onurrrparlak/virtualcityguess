import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/services/game_service.dart';
import 'package:virtualcityguess/services/timer_service.dart';
import 'package:virtualcityguess/views/game_screen.dart';
import 'package:virtualcityguess/services/firestore_service.dart';
import 'package:virtualcityguess/views/host_game_screen.dart';

class HostLobbyScreen extends StatefulWidget {
  final String roomId;
  final String playerName;

  HostLobbyScreen({required this.roomId, required this.playerName});

  @override
  State<HostLobbyScreen> createState() => _HostLobbyScreenState();
}

class _HostLobbyScreenState extends State<HostLobbyScreen> {
  bool _isButtonDisabled = false;
  void _startGame(BuildContext context) async {
    await GameService().startGame(widget.roomId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerService = Provider.of<TimerService>(context, listen: false);
      timerService.startTimer();
    });

    // Navigate to the GameScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HostGameScreen(
          roomId: widget.roomId,
          playerName: widget.playerName, // Assuming 'Host' is the host's player name
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
                    'Room ID: ${widget.roomId}',
                    style: TextStyle(fontSize: screenWidth * 0.04),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.roomId));
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
                stream: FirestoreService().getRoomStream(widget.roomId),
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
                                            style:
                                                TextStyle(color: Colors.green)),
                                      ],
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            String playerName =
                                                joinedPlayers[index];
                                            FirestoreService()
                                                .kickPlayer(widget.roomId, playerName);
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
                                            String playerName =
                                                joinedPlayers[index];
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
                                                        FirestoreService()
                                                            .banPlayer(widget.roomId,
                                                                playerName);
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
                          onPressed: _isButtonDisabled
                              ? null
                              : () {
                                 setState(() {
                                    // Disable the button after it's clicked
                                    _isButtonDisabled = true;
                                  });
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
