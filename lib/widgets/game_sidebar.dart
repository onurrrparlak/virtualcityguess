import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:virtualcityguess/models/app_localizations.dart';
import 'package:virtualcityguess/services/timer_service.dart';
import 'package:virtualcityguess/services/firestore_service.dart';

class GameSidebar extends StatelessWidget {
  final String roomId;
  static int _buildCount = 0;

  const GameSidebar({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    _buildCount++; // Increment build count
    final AppLocalizations? appLocalizations = AppLocalizations.of(context);
  

    final FirestoreService firestoreService = FirestoreService();

    return Container(
      width: MediaQuery.of(context).size.width * 0.10,
      height: MediaQuery.of(context).size.height,
      color: Colors.black,
      child: Column(
        children: [
          Consumer<TimerService>(
            builder: (context, timerService, child) {
              return Text(
                '${appLocalizations!.translate('timeremaining')}: ${timerService.timerDuration}',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              );
            },
          ),
           Center(
            child: Text(
              '${appLocalizations!.translate('scoreboard')}',
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: firestoreService.getRoomStream(roomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.hasError) {
                  return const Center(child: Text('Error loading data'));
                }

                Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
                Map<String, int> players = Map<String, int>.from(data['players']);
                Map<String, bool> submittedPlayers = Map<String, bool>.from(data['submittedPlayers'] ?? {});

                List<MapEntry<String, int>> sortedPlayers = players.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return ListView.builder(
                  itemCount: sortedPlayers.length,
                  itemBuilder: (context, index) {
                    var player = sortedPlayers[index];
                    bool submitted = submittedPlayers[player.key] ?? false;

                    return ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${player.key}: ${player.value}  ${appLocalizations.translate('points')}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          if (submitted)
                            const Icon(
                              Icons.check,
                              color: Colors.green,
                            ),
                        ],
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
