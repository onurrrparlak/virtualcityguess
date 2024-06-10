
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/models/app_localizations.dart';
import 'package:virtualcityguess/provider/location_notifier_provider.dart';
import 'package:virtualcityguess/services/game_service.dart';
import 'package:virtualcityguess/services/matchmaking_service.dart';
import 'package:virtualcityguess/services/timer_service.dart';
import 'package:virtualcityguess/widgets/game_sidebar.dart';
import 'package:virtualcityguess/widgets/custom_dialog_sheet.dart';
import 'package:virtualcityguess/widgets/videoplayer.dart';
class OneonONeGameScreen extends StatefulWidget {
  final String roomId;
  final String playerName;
  final bool isHost;

  const OneonONeGameScreen({
    super.key,
    required this.roomId,
    required this.playerName,
    required this.isHost,
  });

  @override
  State<OneonONeGameScreen> createState() => _OneonONeGameScreenState();
}

class _OneonONeGameScreenState extends State<OneonONeGameScreen> {
  @override
  void initState() {
    super.initState();

    // Initialize services after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerService = Provider.of<TimerService>(context, listen: false);
      timerService.updateTimerDuration(60); // Set round duration
      timerService.startTimer(); // Start the timer

      final gameService = Provider.of<GameService>(context, listen: false);
      gameService.listenToRoomUpdates(context, widget.roomId);
    });

    // Listen to timer expiration and trigger next round
    Provider.of<TimerService>(context, listen: false).addListener(_onTimerExpired);
  }

  @override
  void dispose() {
    // Clean up listener
    Provider.of<TimerService>(context, listen: false).removeListener(_onTimerExpired);
    super.dispose();
  }

  // Function to handle timer expiration
  void _onTimerExpired() async {
    final timerService = Provider.of<TimerService>(context, listen: false);
    if (timerService.timerExpired) {
      // Call next round when the timer expires
      await Provider.of<MatchmakingService>(context, listen: false).nextRound(widget.roomId);
      // Reset the timer for the next round
      timerService.resetTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = constraints.biggest;
          final isSmallScreen = screenSize.width < 800;

          final scoreboardWidth = isSmallScreen
              ? constraints.maxWidth * 0.25
              : constraints.maxWidth * 0.10;

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
                      child: GameSidebar(
                        roomId: widget.roomId,
                      ),
                    ),
                    // VideoPlayer
                    Expanded(
                      child: Container(
                        color: Colors.black,
                        child: Consumer<GameService>(
                          builder: (context, gameService, child) {
                            if (gameService.currentTarget == null) {
                              return const CircularProgressIndicator();
                            }
                            return Column(
                              children: [
                                Expanded(
                                  child: VideoPlayerWidget(
                                    videoUrl: gameService.videoUrl!,
                                  ),
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

              // Bottom Section with Timer and Buttons
              SizedBox(
                height: constraints.maxHeight * 0.1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Timer Display
                    Selector<TimerService, int>(
                      selector: (_, timerService) => timerService.timerDuration,
                      builder: (context, timerDuration, child) {
                        return Text(
                          timerDuration.toString(),
                          style: const TextStyle(fontSize: 24),
                        );
                      },
                    ),

                    const SizedBox(width: 20),

                    // Action Button
                    Consumer2<LocationNotifier, TimerService>(
                      builder: (context, locationNotifier, timerService, child) {
                        return ElevatedButton(
                          onPressed: () {
                            if (!timerService.timerExpired) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return CustomDialogSheet(
                                    roomId: widget.roomId,
                                    playerName: widget.playerName,
                                  );
                                },
                              );
                            }
                          },
                          child: Text(
                            locationNotifier.locationSubmitted || timerService.timerExpired
                                ? 'Show Results'
                                : 'Guess Location',
                          ),
                        );
                      },
                    ),
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
