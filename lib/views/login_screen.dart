import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/models/app_localizations.dart';
import 'package:virtualcityguess/models/user_model.dart';
import 'package:virtualcityguess/services/auth_service.dart';
import 'package:virtualcityguess/views/player_name_screen.dart'; // Import the PlayerNameScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);
final AppLocalizations? appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration:  InputDecoration(labelText: '${appLocalizations!.translate('email')}'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: '${appLocalizations.translate('password')}'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: () async {
                String email = emailController.text;
                String password = passwordController.text;
                try {
                  dynamic result = await _auth.signInWithEmailAndPassword(
                      context, email, password);
                  if (result != null) {
                    print("Logged in");
                    Navigator.pushReplacementNamed(context, '/home');
                  } else {
                    print("Error logging in");
                  }
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.message!),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          "An unexpected error occurred. Please try again later."),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              child:  Text('${appLocalizations.translate('login')}'),
            ),
            ElevatedButton(
              onPressed: () async {
try {
                  final result = await _auth.signInWithGoogle(context);
                  User? user = result['user'];
                  bool isNewUser = result['isNewUser'];

                  if (user != null) {
                    if (isNewUser) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PlayerNameScreen(user: user, userModel: userModel,)),
                      );
                    } else {
                      print("Logged in with Google");
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  } else {
                    print("Error logging in with Google");
                  }
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.message!),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          "An unexpected error occurred. Please try again later."),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              child:  Text('${appLocalizations.translate('loginwithgoogle')}'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child:  Text('${appLocalizations.translate('donthaveanaccountregister')}'),
            ),
          ],
        ),
      ),
    );
  }
}
