import 'package:flutter/material.dart';

class UserModel with ChangeNotifier {
  String? email;
  String? playerName;
  int? rating;
  bool? premium;

  UserModel({this.email, this.playerName, this.rating, this.premium});

  void setUser(String email, String playerName, int rating, bool premium) {
    this.email = email;
    this.playerName = playerName;
    this.rating = rating;
    this.premium = premium;
    notifyListeners();
  }

  void updatePlayerName(String playerName) {
    this.playerName = playerName;
    notifyListeners();
  }

  void updateRating(int rating) {
    this.rating = rating;
    notifyListeners();
  }

  void updatePremium(bool premium) {
    this.premium = premium;
    notifyListeners();
  }
}
