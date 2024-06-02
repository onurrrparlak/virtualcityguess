import 'dart:async';
import 'package:flutter/material.dart';

class TimerService extends ChangeNotifier {
  int _timerDuration = 10; // Default value
  int _defaultDuration = 10; // Default value to reset to
  Timer? _timer;
  bool _timerExpired = false;

  int get timerDuration => _timerDuration;
  bool get timerExpired => _timerExpired;

  void updateTimerDuration(int roundDuration) {
    _timerDuration = roundDuration;
    _defaultDuration = roundDuration; // Update the default duration
  }

  void startTimer() {
    print('start $_timerExpired');
    const oneSecond = Duration(seconds: 1);
    _timer?.cancel();
    _timer = Timer.periodic(oneSecond, (timer) {
      if (_timerDuration < 1) {
        _timer?.cancel();
        if (!_timerExpired) {
          _timerExpired = true;
          print('bitti $_timerExpired');
          notifyListeners();
        }
      } else {
        _timerDuration--;
        notifyListeners();
      }
    });
  }

  void resetTimer() {
    print('Girdi $_timerExpired');
    if (_timerDuration != _defaultDuration || _timerExpired) {
      _timerDuration = _defaultDuration; // Reset to default value
      _timerExpired = false;
      startTimer();
      notifyListeners();
      print('Çıktı $_timerExpired');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
