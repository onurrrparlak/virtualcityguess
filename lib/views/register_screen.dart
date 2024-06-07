import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:virtualcityguess/models/app_localizations.dart';
import 'package:virtualcityguess/services/auth_service.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
      final AppLocalizations? appLocalizations = AppLocalizations.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration:  InputDecoration(labelText: '${appLocalizations!.translate('email')}'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '${appLocalizations.translate('pleaseenteremail')}';
                  }
                  // Email validation
                  String pattern = r'^[^@]+@[^@]+\.[^@]+';
                  RegExp regex = RegExp(pattern);
                  if (!regex.hasMatch(value)) {
                    return '${appLocalizations.translate('entervalidemail')}';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration:  InputDecoration(labelText: '${appLocalizations.translate('password')}'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '${appLocalizations.translate('enterpassword')}';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration:  InputDecoration(labelText: '${appLocalizations.translate('confirmpassword')}'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '${appLocalizations.translate('pleaseconfirmpassword')}';
                  }
                  if (value != _passwordController.text) {
                    return '${appLocalizations.translate('passwordsdonotmatch')}';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _playerNameController,
                decoration:  InputDecoration(labelText: '${appLocalizations.translate('playername')}'),
                validator: (value)  {
                  if (value == null || value.isEmpty) {
                    return '${appLocalizations!.translate('enterplayername')}';
                  }
                  if (value.contains(' ')) {
                    return '${appLocalizations!.translate('playernamespace')}';
                  }
                  if (value.length > 32) {
                    return '${appLocalizations!.translate('playername32')}';
                  }
                  if (value.length < 4){
                     return '${appLocalizations!.translate('playernamelessthan4')}';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    String email = _emailController.text;
                    String password = _passwordController.text;
                    String playerName = _playerNameController.text;

                    bool isPlayerNameAvailable = await _authService.isPlayerNameAvailable(playerName);
                    if (!isPlayerNameAvailable) {
                      ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('${appLocalizations.translate('playernameexists')}')),
                      );
                      return;
                    }

                    User? user = await _authService.registerWithEmailAndPassword(
                      context,
                      email,
                      password,
                      playerName,
                    );

                    if (user != null) {
                      // Registration successful
                      ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('${appLocalizations.translate('verifyemail')}')),
                      );
                    } else {
                      // Registration failed
                      ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('${appLocalizations.translate('registrationfailed')}')),
                      );
                    }
                  }
                },
                child: const Text('Register'),
              ),
              const SizedBox(height: 20),
               Text(
                '${appLocalizations.translate('termsofuseandprivacypolicy')}',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
