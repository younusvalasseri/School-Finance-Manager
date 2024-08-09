import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:week7_institute_project_2/generated/intl/messages_all.dart';

class AppLocalizations {
  static Future<AppLocalizations> load(Locale locale) {
    final String name = locale.countryCode?.isEmpty ?? false
        ? locale.languageCode
        : locale.toString();
    final String localeName = Intl.canonicalizedLocale(name);

    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      return AppLocalizations();
    });
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get appTitle {
    return Intl.message('Institute Management App', name: 'appTitle');
  }

  String get home {
    return Intl.message('Home', name: 'home');
  }

  String get reports {
    return Intl.message('Reports', name: 'reports');
  }

  String get settings {
    return Intl.message('Settings', name: 'settings');
  }

  String get add {
    return Intl.message('Add', name: 'add');
  }

  String get language {
    return Intl.message('Language', name: 'language');
  }

  String get darkTheme {
    return Intl.message('Dark Theme', name: 'darkTheme');
  }

  String get privacyPolicy {
    return Intl.message('Privacy Policy', name: 'privacyPolicy');
  }

  String get adminPanel {
    return Intl.message('Admin Panel', name: 'adminPanel');
  }

  String get passwordReset {
    return Intl.message('Password Reset', name: 'passwordReset');
  }

  String get categories {
    return Intl.message('Categories', name: 'categories');
  }

  String get courses {
    return Intl.message('Courses', name: 'courses');
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ml'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
