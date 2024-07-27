import 'package:flutter/material.dart';
import 'package:week7_institute_project_2/generated/l10n.dart';

class SettingsScreen extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;

  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SettingsScreenState createState() => _SettingsScreenState();
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

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.of(context).privacyPolicy),
          content: const SingleChildScrollView(
            child: Column(
              children: [
                Text('Sample Privacy Policy\n\n'
                    'We respect your privacy and are committed to protecting your personal data. '
                    'This privacy policy will inform you about how we look after your personal data when you use our app '
                    'and tell you about your privacy rights and how the law protects you.\n\n'
                    '1. Information We Collect\n'
                    'We collect information to provide better services to our users. This includes:\n'
                    '- Personal identification information (Name, email address, phone number, etc.)\n\n'
                    '2. How We Use Information\n'
                    'We use the information we collect in various ways, including to:\n'
                    '- Provide, operate, and maintain our app\n'
                    '- Improve, personalize, and expand our app\n'
                    '- Understand and analyze how you use our app\n'
                    '- Develop new products, services, features, and functionality\n\n'
                    '3. Sharing Information\n'
                    'We do not share your personal information with any third parties except in the following cases:\n'
                    '- With your consent\n'
                    '- For external processing (e.g., with our service providers)\n'
                    '- For legal reasons\n\n'
                    '4. Data Security\n'
                    'We implement security measures to protect your information. However, no security system is impenetrable '
                    'and we cannot guarantee the security of our systems 100%.\n\n'
                    '5. Your Rights\n'
                    'You have the right to access, correct, or delete your personal data. If you wish to exercise these rights, '
                    'please contact us.\n\n'
                    '6. Changes to This Policy\n'
                    'We may update our privacy policy from time to time. We will notify you of any changes by posting the new '
                    'privacy policy on this page.\n\n'
                    'Contact Us\n'
                    'If you have any questions or concerns about this privacy policy, please contact us at younusv@gmail.com.\n\n'
                    'This privacy policy is effective as of 01/08/2024.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
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
            onTap: () => _showPrivacyPolicy(context),
          ),
          // Additional settings can be added here
        ],
      ),
    );
  }
}
