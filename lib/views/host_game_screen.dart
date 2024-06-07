
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/models/app_localizations.dart';
import 'package:virtualcityguess/provider/location_notifier_provider.dart';
import 'package:virtualcityguess/services/firestore_service.dart';
import 'package:virtualcityguess/services/game_service.dart';
import 'package:virtualcityguess/services/timer_service.dart';
import 'package:virtualcityguess/widgets/game_sidebar.dart';
import 'package:virtualcityguess/widgets/custom_dialog_sheet.dart';
import 'package:virtualcityguess/widgets/videoplayer.dart';

class HostGameScreen extends StatefulWidget {
  final String roomId;
  final String playerName;

  const HostGameScreen({
    super.key,
    required this.roomId,
    required this.playerName,
  });

  @override
  State<HostGameScreen> createState() => _HostGameScreenState();
}

class _HostGameScreenState extends State<HostGameScreen> {
  static int _buildCount = 0;



  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerService = Provider.of<TimerService>(context, listen: false);
      timerService.startTimer();
    });

    final gameService = Provider.of<GameService>(context, listen: false);
    gameService.listenToRoomUpdates(context, widget.roomId);
  }

  @override
  Widget build(BuildContext context) {
    final locationNotifier = Provider.of<LocationNotifier>(context);
    int? currentRound = Provider.of<GameService>(context).currentRound;
    final AppLocalizations? appLocalizations = AppLocalizations.of(context);

    _buildCount++; // Increment build count
    print('build sayısı $_buildCount');

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
                    bool allSubmitted =
                        Provider.of<GameService>(context).allSubmitted;
                          print('Süre: $timerExpired');
                          print('Herkes: $allSubmitted');
                    //   print('Timer Value 1:  $timerExpired');
                    /*   if (timerExpired) {
                    
                      Provider.of<GameService>(context, listen: false)
                          .updateRoundEndedInFirestore(widget.roomId);
                      
                    }*/
                    return Column(
                      children: [
                      
                        if (timerExpired || allSubmitted)
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
                                ?  Text('${appLocalizations!.translate('nextround')}')
                                : const Text(''),
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
                                  ?  Text('${appLocalizations!.translate('showresults')}')
                                  :  Text('${appLocalizations!.translate('guesslocation')}');
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
