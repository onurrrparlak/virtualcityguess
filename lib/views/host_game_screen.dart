import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/provider/location_notifier_provider.dart';
import 'package:virtualcityguess/services/game_service.dart';
import 'package:virtualcityguess/services/timer_service.dart';
import 'package:virtualcityguess/views/game_result.dart';
import 'package:virtualcityguess/widgets/game_sidebar.dart';
import 'package:virtualcityguess/widgets/custom_dialog_sheet.dart';
import 'package:virtualcityguess/widgets/videoplayer.dart';

class HostGameScreen extends StatefulWidget {
  final String roomId;
  final String playerName;

  const HostGameScreen({
    Key? key,
    required this.roomId,
    required this.playerName,
  }) : super(key: key);

  @override
  State<HostGameScreen> createState() => _HostGameScreenState();
}

class _HostGameScreenState extends State<HostGameScreen> {
  static int _buildCount = 0;
  bool _allPlayersSubmitted = false;

  @override
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerService = Provider.of<TimerService>(context, listen: false);
      timerService.startTimer();

      void startTimer() {
        Timer timer = Timer.periodic(Duration(seconds: 5), (Timer t) {
          if (timerService.timerDuration <= 0) {
            t.cancel(); // Cancel the timer if the condition is no longer met
          } else {
            checkAllPlayersSubmitted();
          }
        });
      }
    });

    final gameService = Provider.of<GameService>(context, listen: false);
    gameService.listenToRoomUpdates(context, widget.roomId);
  }

  Future<void> checkAllPlayersSubmitted() async {
    final gameService = Provider.of<GameService>(context, listen: false);
    final allSubmitted =
        await gameService.checkAllPlayersSubmitted(widget.roomId);
    setState(() {
      _allPlayersSubmitted = allSubmitted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationNotifier = Provider.of<LocationNotifier>(context);
    int? _currentRound = Provider.of<GameService>(context).currentRound;

    _buildCount++; // Increment build count
    print('build sayısı $_buildCount');
   
    print(_currentRound);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = constraints.biggest;
          final isSmallScreen = screenSize.width < 800;

          final scoreboardWidth = isSmallScreen
              ? constraints.maxWidth * 0.25
              : constraints.maxWidth * 0.10;
          final videoWidth = constraints.maxWidth - scoreboardWidth;

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
                              return CircularProgressIndicator();
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

              // Bottom Section with Buttons
              Container(
                height: constraints.maxHeight * 0.1,
                // Add your buttons here
                child: Selector<TimerService, bool>(
                  selector: (_, timerService) => timerService.timerExpired,
                  builder: (_, timerExpired, __) {
                    print('Timer Value 1:  $timerExpired');
                    if (timerExpired) {
                    
                      Provider.of<GameService>(context, listen: false)
                          .updateRoundEndedInFirestore(widget.roomId);
                      
                    }
                    return Column(
                      children: [
                       
                        if (timerExpired || _allPlayersSubmitted)
                          ElevatedButton(
                            onPressed: () async {
                            //  print('Timer Value 2 : $timerExpired');
                              final gameService = Provider.of<GameService>(
                                  context,
                                  listen: false);
                             /* Provider.of<TimerService>(context, listen: false)
                                  .resetTimer();*/
                              await gameService.nextRound(widget.roomId);
                            },
                            child: locationNotifier.locationSubmitted ||
                                    timerExpired
                                ? Text('Next Round')
                                : Text(''),
                          ),
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
                          child: Consumer2<LocationNotifier, TimerService>(
                            builder: (context, locationNotifier, timerService,
                                child) {
                              return locationNotifier.locationSubmitted ||
                                      timerService.timerExpired
                                  ? Text('Show Results')
                                  : Text('Guess Location');
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
