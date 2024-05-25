import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:virtualcityguess/services/timer_service.dart';
import 'package:virtualcityguess/services/firestore_service.dart';

class GameSidebar extends StatelessWidget {
  final String roomId;
  static int _buildCount = 0;

  GameSidebar({required this.roomId});

  @override
  Widget build(BuildContext context) {
    _buildCount++; // Increment build count
    print('Build method called $_buildCount times');

    final FirestoreService firestoreService = FirestoreService();

    return Container(
      width: MediaQuery.of(context).size.width * 0.10,
      height: MediaQuery.of(context).size.height,
      color: Colors.blue,
      child: Column(
        children: [
          Consumer<TimerService>(
            builder: (context, timerService, child) {
              return Text(
                'Time Remaining: ${timerService.timerDuration}',
                style: TextStyle(color: Colors.white, fontSize: 24),
              );
            },
          ),
          Center(
            child: Text(
              'Scoreboard',
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: firestoreService.getRoomStream(roomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.hasError) {
                  return Center(child: Text('Error loading data'));
                }

                Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
                Map<String, int> players = Map<String, int>.from(data['players']);

                List<MapEntry<String, int>> sortedPlayers = players.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return ListView.builder(
                  itemCount: sortedPlayers.length,
                  itemBuilder: (context, index) {
                    var player = sortedPlayers[index];
                    return ListTile(
                      title: Text(
                        '${player.key}: ${player.value} points',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
