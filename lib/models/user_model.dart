import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel with ChangeNotifier {
  @HiveField(0)
  String? email;
  @HiveField(1)
  String? playerName;
  @HiveField(2)
  int? rating;
  @HiveField(3)
  bool? premium;

    UserModel({this.email, this.playerName, this.rating, this.premium}) {
    // Set default values to null if not provided
    email ??= null;
    playerName ??= null;
    rating ??= null;
    premium ??= null;
  }

  Box<UserModel>? _userBox;

  Future<void> _openBox() async {
    _userBox = await Hive.openBox<UserModel>('userBox');
  }

  

  Future<void> setUser(String email, String playerName, int rating, bool premium) async {
    this.email = email;
    this.playerName = playerName;
    this.rating = rating;
    this.premium = premium;
    await _saveToHive();
    notifyListeners();
  }

  Future<void> updatePlayerName(String playerName) async {
    this.playerName = playerName;
    await _saveToHive();
    notifyListeners();
  }

  Future<void> updateRating(int rating) async {
    this.rating = rating;
    await _saveToHive();
    notifyListeners();
  }

  Future<void> updatePremium(bool premium) async {
    this.premium = premium;
    await _saveToHive();
    notifyListeners();
  }

  Future<void> _saveToHive() async {
    if (_userBox == null) {
      await _openBox();
    }
    _userBox?.put('user', this);
  }

  Future<void> loadFromHive() async {
    await _openBox();
    UserModel? userModel = _userBox?.get('user');
    if (userModel != null) {
      email = userModel.email;
      playerName = userModel.playerName;
      rating = userModel.rating;
      premium = userModel.premium;
      notifyListeners();
    }
  }
}
