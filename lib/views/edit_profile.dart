import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/models/user_model.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
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
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _email,
                decoration: InputDecoration(labelText: 'Email'),
                onSaved: (value) {
                  _email = value;
                },
              ),
              TextFormField(
                initialValue: _playerName,
                decoration: InputDecoration(labelText: 'Player Name'),
                onSaved: (value) {
                  _playerName = value;
                },
              ),
              TextFormField(
                readOnly: true,
                initialValue: _rating?.toString(),
                decoration: InputDecoration(labelText: 'Rating'),
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  _rating = int.tryParse(value ?? '');
                },
              ),
              IgnorePointer(
                ignoring: true,
                child: SwitchListTile(
                  title: Text('Premium'),
                  value: _premium ?? false,
                  onChanged: null,
                ),
              ),
              SizedBox(height: 20),
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
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
