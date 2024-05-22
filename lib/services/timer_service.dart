import 'dart:async';
import 'package:flutter/material.dart';

class TimerService extends ChangeNotifier {
  int _timerDuration = 10;
  Timer? _timer;
  bool _timerExpired = false;

  int get timerDuration => _timerDuration;
  bool get timerExpired => _timerExpired;

  void startTimer() {
    const oneSecond = Duration(seconds: 1);
    _timer?.cancel();
    _timer = Timer.periodic(oneSecond, (timer) {
      if (_timerDuration < 1) {
        _timer?.cancel();
        if (!_timerExpired) {
          _timerExpired = true;
          notifyListeners();
        }
      } else {
        _timerDuration--;
        notifyListeners();
      }
    });
  }

  void resetTimer() {
    _timer?.cancel();
    _timerDuration = 60;
    _timerExpired = false;
    notifyListeners();
  }

  void cancelTimer() {
    _timer?.cancel();
    _timerDuration = 0;
    _timerExpired = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
