import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/services/game_service.dart';
import 'package:virtualcityguess/services/timer_service.dart';

class GameScreen extends StatefulWidget {
  final String roomId;
  final String playerName;
  final bool isHost;

  const GameScreen({Key? key, required this.roomId, required this.playerName, required this.isHost}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();

    final gameService = Provider.of<GameService>(context, listen: false);
    gameService.listenToRoomUpdates(widget.roomId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerService = Provider.of<TimerService>(context, listen: false);
      timerService.startTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
   

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Room ID: ${widget.roomId}',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              'Player Name: ${widget.playerName}',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              'Is Host: ${widget.isHost ? 'Yes' : 'No'}',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Consumer<TimerService>(
              builder: (context, timerService, child) {
                if (timerService.timerExpired) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Time expired')),
                    );
                  });
                }
                return Text(
                  'Time Remaining: ${timerService.timerDuration}',
                  style: TextStyle(fontSize: 24),
                );
              },
            ),
            SizedBox(height: 20),
            Consumer<GameService>(
              builder: (context, gameService, child) {
                if (gameService.currentTarget == null) {
                  return CircularProgressIndicator();
                }
                return Text(
                  'Current Target: ${gameService.currentTarget}',
                  style: TextStyle(fontSize: 24),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
