import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/models/app_localizations.dart';
import 'package:virtualcityguess/services/firestore_service.dart';

class GameResultsScreen extends StatelessWidget {
  final String roomId;

  const GameResultsScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? appLocalizations = AppLocalizations.of(context);
    return Scaffold(
      body: FutureBuilder<List<MapEntry<String, int>>>(
        future: Provider.of<FirestoreService>(context)
            .fetchAndSortPlayersByPoints(roomId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            final players = snapshot.data!;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text(
                    '${appLocalizations!.translate('gameover')}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // Display ranking with rewards
                  RewardRanking(players: players),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate back to home or any other screen
                      Navigator.pop(context);
                    },
                    child: Text('${appLocalizations!.translate('backtohome')}'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class RewardRanking extends StatelessWidget {
  final List<MapEntry<String, int>> players;

  const RewardRanking({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
      final AppLocalizations? appLocalizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       Text(
          '${appLocalizations!.translate('ranking')}',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        // Display player rankings with rewards
        ListView.builder(
          shrinkWrap: true,
          itemCount: players.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Text('${index + 1}.'),
              title: Text(players[index].key),
              trailing: Text('${players[index].value}  ${appLocalizations!.translate('backtohome')}'),
              // Add rewards or icons based on ranking if needed
            );
          },
        ),
      ],
    );
  }
}
