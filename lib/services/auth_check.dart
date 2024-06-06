import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/models/user_model.dart';

void checkAuthAndNavigate(BuildContext context, Widget homeScreen, Widget loginScreen) {
  final userModel = Provider.of<UserModel>(context);

  if (userModel.email != null && userModel.email!.isNotEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => homeScreen));
    });
  } else {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => loginScreen));
    });
  }
}
