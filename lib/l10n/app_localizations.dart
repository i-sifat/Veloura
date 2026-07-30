import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Localization facade whose source-of-truth keys are mirrored in app_en.arb.
/// Additional generated locales can replace this base delegate without changing
/// feature call sites.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en')];
  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  String get appTitle => 'Veloura';
  String get homeTab => 'Home';
  String get gamesTab => 'Games';
  String get dailyTab => 'Daily';
  String get favoritesTab => 'Favorites';
  String get profileTab => 'Profile';
  String get randomGame => 'Random game';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
