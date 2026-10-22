import 'dart:ui';

import 'app_localizations.dart';

/// What the « Langue » setting stores: follow the device, or one language.
sealed class AppLanguage {
  const AppLanguage();

  static const system = SystemLanguage();

  /// The stored value: `system`, or a language code such as `fr`.
  String get code;

  /// Reads a stored value; anything absent or unknown follows the device.
  static AppLanguage parse(String? code,
      {List<Locale> supported = AppLocalizations.supportedLocales}) {
    for (final locale in supported) {
      if (locale.languageCode == code) return FixedLanguage(Locale(locale.languageCode));
    }
    return system;
  }
}

/// Follow the device's languages.
class SystemLanguage extends AppLanguage {
  const SystemLanguage();

  @override
  String get code => 'system';

  @override
  bool operator ==(Object other) => other is SystemLanguage;

  @override
  int get hashCode => 0;
}

/// One language, whatever the device's.
class FixedLanguage extends AppLanguage {
  const FixedLanguage(this.locale);

  final Locale locale;

  @override
  String get code => locale.languageCode;

  @override
  bool operator ==(Object other) =>
      other is FixedLanguage && other.locale.languageCode == locale.languageCode;

  @override
  int get hashCode => locale.languageCode.hashCode;
}

/// The locale the app shows for [setting] on a device whose languages are
/// [device], among the languages the app has ([supported]): always a bare
/// language (`fr`, never `fr_CA`), English when the device has none of them.
Locale resolveAppLocale(AppLanguage setting, List<Locale> device,
    {List<Locale> supported = AppLocalizations.supportedLocales}) {
  final codes = {for (final l in supported) l.languageCode};
  switch (setting) {
    case FixedLanguage(:final locale) when codes.contains(locale.languageCode):
      return Locale(locale.languageCode);
    case _:
      for (final locale in device) {
        if (codes.contains(locale.languageCode)) return Locale(locale.languageCode);
      }
      return const Locale('en');
  }
}
