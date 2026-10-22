import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/app_language.dart';
import '../../l10n/l10n.dart';

/// « Langue de l'appareil », then every language the app has, each written
/// in itself (spec « Langues »). A new `app_xx.arb` shows up here on its own.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.locales = AppLocalizations.supportedLocales,
  });

  final AppLanguage selected;
  final ValueChanged<AppLanguage> onSelected;
  final List<Locale> locales;

  /// A language's name in that language (its code if the app lacks it).
  static String nameOf(Locale locale) {
    try {
      return lookupAppLocalizations(locale).languageName;
    } on FlutterError {
      return locale.languageCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final languages = [
      for (final locale in locales) FixedLanguage(Locale(locale.languageCode)),
    ]..sort((a, b) => nameOf(a.locale).toLowerCase().compareTo(nameOf(b.locale).toLowerCase()));
    return RadioGroup<AppLanguage>(
      groupValue: selected,
      onChanged: (value) {
        if (value != null) onSelected(value);
      },
      // Scrolls when the languages or the text size outgrow the sheet.
      child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        RadioListTile<AppLanguage>(
          value: AppLanguage.system,
          title: Text(context.l10n.settingsDeviceLanguage, style: context.text.body),
        ),
        for (final language in languages)
          RadioListTile<AppLanguage>(
            value: language,
            title: Text(nameOf(language.locale), style: context.text.body),
          ),
      ])),
    );
  }
}
