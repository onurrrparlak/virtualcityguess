import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/models/user_model.dart';
import 'package:virtualcityguess/services/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
   final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  String? _email;
  String? _playerName;
  int? _rating;
  bool? _premium;

  @override
  void initState() {
    super.initState();
    UserModel userModel = Provider.of<UserModel>(context, listen: false);
    _email = userModel.email;
    _playerName = userModel.playerName;
    _rating = userModel.rating;
    _premium = userModel.premium;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                onSaved: (value) {
                  _email = value;
                },
              ),
               TextFormField(
                initialValue: _playerName,
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
                onSaved: (value) async {
                   bool isPlayerNameAvailable = await _authService.isPlayerNameAvailable(value!);
                    if (!isPlayerNameAvailable) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Player name already exists')),
                      );
                      return;
                    }
                  _playerName = value;
                },
              ),
             
              TextFormField(
                readOnly: true,
                initialValue: _rating?.toString(),
                decoration: const InputDecoration(labelText: 'Rating'),
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  _rating = int.tryParse(value ?? '');
                },
              ),
              IgnorePointer(
                ignoring: true,
                child: SwitchListTile(
                  title: const Text('Premium'),
                  value: _premium ?? false,
                  onChanged: null,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    Provider.of<UserModel>(context, listen: false).setUser(
                      _email!,
                      _playerName!,
                      _rating!,
                      _premium!,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
