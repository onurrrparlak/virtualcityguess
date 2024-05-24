import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/services/game_service.dart';
import 'package:virtualcityguess/services/timer_service.dart';
import 'package:virtualcityguess/widgets/game_sidebar.dart';
import 'package:virtualcityguess/widgets/custom_dialog_sheet.dart';
import 'package:virtualcityguess/widgets/videoplayer.dart';

class GameScreen extends StatefulWidget {
  final String roomId;
  final String playerName;
  final bool isHost;

  const GameScreen(
      {Key? key,
      required this.roomId,
      required this.playerName,
      required this.isHost})
      : super(key: key);

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
    final locationNotifier = Provider.of<LocationNotifier>(context);
    final timerNotifier = Provider.of<TimerService>(context);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = constraints.biggest;
          final isSmallScreen =
              screenSize.width < 800; // Define your threshold for small screen
      
          final scoreboardWidth = isSmallScreen
              ? constraints.maxWidth * 0.25
              : constraints.maxWidth * 0.10;
          final videoWidth = constraints.maxWidth - scoreboardWidth;
      
        //  print('Room ID: ${widget.roomId}');
          //print('Player Name: ${widget.playerName}');
          //print('Is Host: ${widget.isHost ? 'Yes' : 'No'}');
      
          return Column(
            children: [
              // Top Section with Scoreboard and VideoPlayer
              Expanded(
                child: Row(
                  children: [
                    // Scoreboard
                    Container(
                      width: scoreboardWidth,
                      color: Colors.blue, // Just for visibility
                      child: GameSidebar(),
                    ),
                    // VideoPlayer
                    Expanded(
                      child: Container(
                        color: Colors.black,
                        child: Consumer<GameService>(
                          builder: (context, gameService, child) {
                            if (gameService.currentTarget == null) {
                              return CircularProgressIndicator();
                            }
                          //  print('Current Target: ${gameService.currentTarget}');
                            return Column(
                              children: [
                                Expanded(
                                  child: VideoPlayerWidget(
                                      videoUrl: gameService.videoUrl!),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom Section with Buttons
              Container(
                height: constraints.maxHeight * 0.1,
                // Add your buttons here
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return CustomDialogSheet(
                              roomId: widget.roomId,
                              playerName: widget.playerName,
                            );
                          },
                        );
                      },
                      child: locationNotifier.locationSubmitted || timerNotifier.timerExpired
                          ? Text('Show Results')
                          : Text('Guess Location'),
                    ),
                    // Adjust spacing between buttons if needed
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
