import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nX on BuildContext {
  /// The app's texts, in its current language.
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// The app's current language (`fr`, `en`), for code that depends on it.
  String get appLanguageCode => Localizations.localeOf(this).languageCode;
}
