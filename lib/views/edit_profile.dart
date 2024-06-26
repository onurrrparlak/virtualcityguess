import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _avatarUrl;
  File? _avatarImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    UserModel userModel = Provider.of<UserModel>(context, listen: false);
    _email = userModel.email;
    _playerName = userModel.playerName;
    _rating = userModel.rating;
    _premium = userModel.premium;
    _avatarUrl = userModel.avatarUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatarImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadAvatar() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_avatarImage != null) {
        String? uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          _avatarUrl = await _authService.uploadAvatar(uid, _avatarImage!);
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${appLocalizations!.translate('editprofile')}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              InkWell(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _avatarImage != null
                          ? FileImage(_avatarImage!)
                          : (_avatarUrl?.isNotEmpty ?? false)
                              ? NetworkImage(_avatarUrl!) as ImageProvider
                              : const AssetImage('assets/images/default_avatar.png'),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.edit,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${appLocalizations.translate('uploadavatar')}',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              if (_isLoading) CircularProgressIndicator(),
              TextFormField(
                initialValue: _email,
                decoration: InputDecoration(labelText: '${appLocalizations.translate('email')}'),
                onSaved: (value) {
                  _email = value;
                },
              ),
              TextFormField(
                initialValue: _playerName,
                decoration: InputDecoration(labelText: '${appLocalizations.translate('playername')}'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '${appLocalizations.translate('enterplayername')}';
                  }
                  if (value.contains(' ')) {
                    return '${appLocalizations.translate('playernamespace')}';
                  }
                  if (value.length > 32) {
                    return '${appLocalizations.translate('playername32')}';
                  }
                  if (value.length < 4) {
                    return '${appLocalizations.translate('playernamelessthan4')}';
                  }
                  return null;
                },
                onSaved: (value) async {
                  bool isPlayerNameAvailable = await _authService.isPlayerNameAvailable(value!);
                  if (!isPlayerNameAvailable) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${appLocalizations.translate('playernameexists')}')),
                    );
                    return;
                  }
                  _playerName = value;
                },
              ),
              TextFormField(
                readOnly: true,
                initialValue: _rating?.toString(),
                decoration: InputDecoration(labelText: '${appLocalizations.translate('rating')}'),
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  _rating = int.tryParse(value ?? '');
                },
              ),
              IgnorePointer(
                ignoring: true,
                child: SwitchListTile(
                  title: Text('${appLocalizations.translate('premium')}'),
                  value: _premium ?? false,
                  onChanged: null,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    await _uploadAvatar();
                    Provider.of<UserModel>(context, listen: false).setUser(
                      _email!,
                      _playerName!,
                      _rating!,
                      _premium!,
                      _avatarUrl!,
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text('${appLocalizations.translate('save')}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
