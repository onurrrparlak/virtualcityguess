
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/models/app_localizations.dart';
import 'package:virtualcityguess/provider/location_notifier_provider.dart';
import 'package:virtualcityguess/services/game_service.dart';
import 'package:virtualcityguess/services/timer_service.dart';
import 'package:virtualcityguess/widgets/game_sidebar.dart';
import 'package:virtualcityguess/widgets/custom_dialog_sheet.dart';
import 'package:virtualcityguess/widgets/videoplayer.dart';

class GameScreen extends StatefulWidget {
  final String roomId;
  final String playerName;
  final bool isHost;

  const GameScreen({
    super.key,
    required this.roomId,
    required this.playerName,
    required this.isHost,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static int _buildCount = 0;

@override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final timerService = Provider.of<TimerService>(context, listen: false);
    final gameService = Provider.of<GameService>(context, listen: false);
    gameService.listenToRoomUpdates(context, widget.roomId);
    

    // Start the timer with the timerDuration from TimerService
    timerService.startTimer();
  });
}





  @override
  Widget build(BuildContext context) {
    final locationNotifier = Provider.of<LocationNotifier>(context);
      int? currentRound = Provider.of<GameService>(context).currentRound;
        final AppLocalizations? appLocalizations = AppLocalizations.of(context);


    _buildCount++; // Increment build count
   
    print(currentRound);

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

              // Bottom Section with Buttons
              SizedBox(
                height: constraints.maxHeight * 0.1,
                // Add your buttons here
                child: Selector<TimerService, bool>(
                  selector: (_, timerService) => timerService.timerExpired,
                  builder: (_, timerExpired, __) {
                    return Column(
                      children: [
                        /* if (Provider.of<GameService>(context).gameShouldEnd)
                          ElevatedButton(
                            onPressed: () async {
                              // Navigate to the game result screen
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GameResultsScreen(roomId: roomId,),
                                ),
                              );
                            },
                            child: Text('End The Game'),
                          ),*/
                       
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
                                  ?  Text('${appLocalizations!.translate('showresults')}')
                                  : Text('${appLocalizations!.translate('guesslocation')}');
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
