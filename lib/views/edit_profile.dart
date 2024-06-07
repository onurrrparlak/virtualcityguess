import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/models/app_localizations.dart';
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
    final AppLocalizations? appLocalizations = AppLocalizations.of(context);
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _email,
                decoration: InputDecoration(labelText: '${appLocalizations!.translate('email')}'),
                onSaved: (value) {
                  _email = value;
                },
              ),
               TextFormField(
                initialValue: _playerName,
                decoration:  InputDecoration(labelText: '${appLocalizations!.translate('playername')}'),
                validator: (value) {
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
                onSaved: (value) async {
                   bool isPlayerNameAvailable = await _authService.isPlayerNameAvailable(value!);
                    if (!isPlayerNameAvailable) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${appLocalizations!.translate('playernameexists')}')),
                      );
                      return;
                    }
                  _playerName = value;
                },
              ),
             
              TextFormField(
                readOnly: true,
                initialValue: _rating?.toString(),
                decoration:  InputDecoration(labelText: '${appLocalizations!.translate('rating')}'),
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  _rating = int.tryParse(value ?? '');
                },
              ),
              IgnorePointer(
                ignoring: true,
                child: SwitchListTile(
                  title:  Text('${appLocalizations!.translate('premium')}'),
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
                child: Text('${appLocalizations!.translate('save')}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
