import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// ARB-backed localization facade. Additional locales can be added without
/// changing feature APIs.
class AppLocalizations {
  AppLocalizations(this.locale, this._values);

  final Locale locale;
  final Map<String, String> _values;

  static const supportedLocales = [Locale('en')];
  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  String get appTitle => _values['appTitle'] ?? 'Veloura';
  String get homeTab => _values['homeTab'] ?? 'Home';
  String get gamesTab => _values['gamesTab'] ?? 'Games';
  String get dailyTab => _values['dailyTab'] ?? 'Daily';
  String get favoritesTab => _values['favoritesTab'] ?? 'Favorites';
  String get profileTab => _values['profileTab'] ?? 'Profile';
  String get randomGame => _values['randomGame'] ?? 'Random game';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final raw = await rootBundle.loadString('lib/l10n/app_en.arb');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return AppLocalizations(
      locale,
      json.map((key, value) => MapEntry(key, '$value')),
    );
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
