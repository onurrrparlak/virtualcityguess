import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/services/timer_service.dart';

class GameSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.10,
      height: MediaQuery.of(context).size.height,
      color: Colors.blue,
      child: Column(
        children: [
           Consumer<TimerService>(
              builder: (context, timerService, child) {
                if (timerService.timerExpired) {
                 
                }
                return Text(
                  'Time Remaining: ${timerService.timerDuration}',
                  style: TextStyle(color: Colors.white,fontSize: 24),
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
        ],
      ),
    );
  }
}
