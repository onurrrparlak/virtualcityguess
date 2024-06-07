import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:virtualcityguess/models/app_localizations.dart';
import 'package:virtualcityguess/views/game_screen.dart';
import 'package:virtualcityguess/services/firestore_service.dart';

class PlayerLobbyScreen extends StatefulWidget {
  final String roomId;
  final String currentPlayerName;

  const PlayerLobbyScreen(
      {super.key, required this.roomId, required this.currentPlayerName});

  @override
  State<PlayerLobbyScreen> createState() => _PlayerLobbyScreenState();
}

class _PlayerLobbyScreenState extends State<PlayerLobbyScreen> {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    final AppLocalizations? appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        constraints: const BoxConstraints.expand(),
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    '${appLocalizations!.translate('roomid')} ${widget.roomId}',
                    style: TextStyle(fontSize: screenWidth * 0.04),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.roomId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${appLocalizations.translate('roomidcopied')}')),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              '${appLocalizations.translate('joinedplayer')}',
              style: TextStyle(fontSize: screenWidth * 0.04),
            ),
            SizedBox(height: screenHeight * 0.015),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirestoreService().getRoomStream(widget.roomId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  Map<String, dynamic> roomData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  List<String> joinedPlayers =
                      roomData['players'].keys.toList();

                  String hostName = roomData['host'];
                  bool gameStarted = roomData['gameStarted'];
                  if (gameStarted) {
                    // Delay for 2 seconds before navigating
                    Future.delayed(const Duration(seconds: 2), () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameScreen(
                            roomId: widget.roomId,
                            playerName: widget.currentPlayerName,
                            isHost: false,
                          ),
                        ),
                      );
                    });
                  }

                  // Ensure the host is at the top and the current player is second
                  joinedPlayers.remove(hostName);
                  joinedPlayers.remove(widget.currentPlayerName);

                  joinedPlayers.insert(0, hostName);
                  joinedPlayers.insert(1, widget.currentPlayerName);

                  return Column(
                    children: [
                      Expanded(
                        flex: 7,
                        child: Scrollbar(
                          child: ListView.builder(
                            itemCount: joinedPlayers.length,
                            itemBuilder: (context, index) {
                              String playerName = joinedPlayers[index];
                              bool isHost = playerName == hostName;

                              return ListTile(
                                title: Text(playerName),
                                trailing: isHost
                                    ?  Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.circle,
                                              color: Colors.green),
                                          SizedBox(width: 5),
                                          Text('${appLocalizations.translate('host')}',
                                              style: TextStyle(
                                                  color: Colors.green)),
                                        ],
                                      )
                                    : Text(
                                        playerName == widget.currentPlayerName
                                            ? '${appLocalizations.translate('you')}'
                                            : '${appLocalizations.translate('player')}',
                                        style: TextStyle(
                                          color: playerName ==
                                                  widget.currentPlayerName
                                              ? Colors.blue
                                              : null,
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: gameStarted
                              ?  Text('${appLocalizations.translate('gamestarting')}')
                              :  Text(
                                  '${appLocalizations.translate('waitingforhost')}'),
                        ),
                      )
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
