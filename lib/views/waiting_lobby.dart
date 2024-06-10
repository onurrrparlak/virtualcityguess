import 'package:flutter/material.dart';
import 'package:virtualcityguess/models/user_model.dart';
import 'package:virtualcityguess/services/matchmaking_service.dart';

class WaitingLobby extends StatefulWidget {
  final UserModel userModel;

  WaitingLobby({required this.userModel});

  @override
  _WaitingLobbyState createState() => _WaitingLobbyState();
}

class _WaitingLobbyState extends State<WaitingLobby> {
  @override
  void initState() {
    super.initState();
    _startSearchingForGame();
  }

  Future<void> _startSearchingForGame() async {
    print('Starting search for game for player: ${widget.userModel.playerName}');
    MatchmakingService matchmakingService = MatchmakingService();
    await matchmakingService.startSearching(context, widget.userModel.playerName!, widget.userModel.rating!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Waiting Lobby'),
      ),
      body: Center(
        child: CircularProgressIndicator(), // Add loading indicator or other UI feedback
      ),
    );
  }
}
