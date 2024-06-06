import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  // Email validation
                  String pattern = r'^[^@]+@[^@]+\.[^@]+';
                  RegExp regex = RegExp(pattern);
                  if (!regex.hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _playerNameController,
                decoration: const InputDecoration(labelText: 'Player Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your player name';
                  }
                  if (value.contains(' ')) {
                    return 'Player name cannot contain spaces';
                  }
                  if (value.length > 32) {
                    return 'Player name cannot be more than 32 characters';
                  }
                  if (value.length < 4){
                     return 'Player name cannot be less than 4 characters';
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
                        const SnackBar(content: Text('Player name already exists')),
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
                        const SnackBar(content: Text('Registration successful, please verify your email')),
                      );
                    } else {
                      // Registration failed
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Registration failed')),
                      );
                    }
                  }
                },
                child: const Text('Register'),
              ),
              const SizedBox(height: 20),
              const Text(
                'By signing up to create an account I accept Terms of use and Privacy Policy',
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
