import 'package:flutter/material.dart';
import 'package:week7_institute_project_2/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;

  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkTheme = false;
  String _selectedLanguage = 'en';

  void _changeTheme(bool isDark) {
    setState(() {
      _isDarkTheme = isDark;
    });
    widget.onThemeChanged(isDark);
  }

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
    widget.onLanguageChanged(language);
  }

  Future<void> _launchPrivacyPolicy() async {
    final url = Uri.parse(
        'https://www.freeprivacypolicy.com/live/d13644bb-1a64-41b2-a629-9f4d8b379f0a');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: Text(S.of(context).language),
            subtitle: Text(_selectedLanguage == 'en' ? 'English' : 'Malayalam'),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _changeLanguage(newValue);
                }
              },
              items: <String>['en', 'ml']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value == 'en' ? 'English' : 'Malayalam'),
                );
              }).toList(),
            ),
          ),
          SwitchListTile(
            title: Text(S.of(context).darkTheme),
            value: _isDarkTheme,
            onChanged: _changeTheme,
          ),
          ListTile(
            title: Text(S.of(context).privacyPolicy),
            trailing: const Icon(Icons.arrow_forward),
            onTap: _launchPrivacyPolicy,
          ),
          // Additional settings can be added here
        ],
      ),
    );
  }
}
