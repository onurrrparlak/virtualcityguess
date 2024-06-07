// language_selection_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:virtualcityguess/main.dart';
import 'package:virtualcityguess/models/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:virtualcityguess/models/user_model.dart';

class LanguageSelectionScreen extends StatefulWidget {
  @override
  _LanguageSelectionScreenState createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? selectedLanguageCode;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

   void _loadCurrentLanguage() async {
    var box = await Hive.openBox('settingsBox');
    setState(() {
      // Fallback to device language if not set
      selectedLanguageCode = box.get('languageCode') ?? window.locale.languageCode;
    });
  }

    void _changeLanguage(String languageCode) async {
    var box = await Hive.openBox('settingsBox');
    box.put('languageCode', languageCode);
    setState(() {
      selectedLanguageCode = languageCode;
    });

    // Apply the language change immediately
    MyApp.setLocale(context, Locale(languageCode));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('change_language') ?? 'Change Language'),
      ),
      body: ListView(
        children: [
          _buildLanguageOption('English', 'en'),
          _buildLanguageOption('中文', 'zh'),
          _buildLanguageOption('हिंदी', 'hi'),
          _buildLanguageOption('Español', 'es'),
          _buildLanguageOption('Français', 'fr'),
          _buildLanguageOption('العربية', 'ar'),
          _buildLanguageOption('Русский', 'ru'),
          _buildLanguageOption('Português', 'pt'),
          _buildLanguageOption('Deutsch', 'de'),
          _buildLanguageOption('日本語', 'ja'),
          _buildLanguageOption('Türkçe', 'tr'),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String language, String languageCode) {
    return ListTile(
      title: Text(language),
      trailing: selectedLanguageCode == languageCode ? Icon(Icons.check) : null,
      onTap: () {
        _changeLanguage(languageCode);
      },
    );
  }
}
