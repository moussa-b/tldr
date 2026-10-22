import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tldr/data/db/summaries_dao.dart';
import 'package:tldr/data/models/models.dart';
import 'package:tldr/l10n/app_language.dart';

import '../helpers.dart';

void main() {
  setUpAll(initTestEnv);

  // protects=the device-language rule (fr* → fr, anything else → en) and the forced choice;
  // fails_when=a French variant, a second device language or a fixed choice is ignored;
  // no_claim=what the platform reports as device languages.
  group('resolveAppLocale', () {
    const system = AppLanguage.system;
    test('a French device gets French, whatever its country', () {
      expect(resolveAppLocale(system, const [Locale('fr', 'FR')]), const Locale('fr'));
      expect(resolveAppLocale(system, const [Locale('fr', 'CA')]), const Locale('fr'));
    });

    test('any other device gets English', () {
      expect(resolveAppLocale(system, const [Locale('en', 'US')]), const Locale('en'));
      expect(resolveAppLocale(system, const [Locale('es', 'ES')]), const Locale('en'));
      expect(resolveAppLocale(system, const []), const Locale('en'));
    });

    test('the first device language the app has wins', () {
      expect(resolveAppLocale(system, const [Locale('es'), Locale('fr')]), const Locale('fr'));
    });

    test('a fixed choice overrides the device', () {
      expect(resolveAppLocale(const FixedLanguage(Locale('fr')), const [Locale('en', 'US')]),
          const Locale('fr'));
      expect(resolveAppLocale(const FixedLanguage(Locale('en')), const [Locale('fr', 'FR')]),
          const Locale('en'));
      // A fixed language the app no longer has follows the device.
      expect(resolveAppLocale(const FixedLanguage(Locale('de')), const [Locale('fr', 'FR')]),
          const Locale('fr'));
    });

    // Spec criterion 8: a language added to the ARB files is picked up without code changes.
    test('a language the app gains is picked up from the device', () {
      const supported = [Locale('en'), Locale('fr'), Locale('de')];
      expect(resolveAppLocale(system, const [Locale('de', 'DE')], supported: supported),
          const Locale('de'));
    });
  });

  // protects=the stored « Langue » setting; fails_when=a missing or stale value breaks startup
  // or a choice is not kept; no_claim=the settings screen itself.
  group('SettingsRepository.appLanguage', () {
    test('follows the device when unset or unknown', () async {
      final deps = await testDeps();
      expect(await deps.settings.appLanguage(), AppLanguage.system);
      await deps.settings.setAppLanguage(const FixedLanguage(Locale('xx')));
      expect(await deps.settings.appLanguage(), AppLanguage.system);
    });

    test('keeps French, English and device', () async {
      final deps = await testDeps();
      for (final language in [
        const FixedLanguage(Locale('fr')),
        const FixedLanguage(Locale('en')),
        AppLanguage.system,
      ]) {
        await deps.settings.setAppLanguage(language);
        expect(await deps.settings.appLanguage(), language);
      }
    });
  });

  // protects=1.0.x users (French only) keep French after the update; fails_when=an upgrader on
  // an English phone is switched to English, or a new install is forced to French;
  // no_claim=the platform's device languages.
  group('SettingsRepository.appLanguageAtStartup', () {
    Future<void> addSummary(TestDeps deps) async => deps.dao.upsert(
        SummaryResult.fromJson(
            jsonDecode(await fileFixture('summary_en_long.json')) as Map<String, dynamic>),
        sourceUrl: 'https://redd.it/1xyz98q');

    test('a new install follows the device', () async {
      final deps = await testDeps();
      expect(await deps.settings.appLanguageAtStartup(const [Locale('en', 'US')]),
          AppLanguage.system);
    });

    test('an upgrade on a non-French phone keeps French, once and for all', () async {
      final deps = await testDeps();
      await addSummary(deps);
      expect(await deps.settings.appLanguageAtStartup(const [Locale('en', 'US')]),
          const FixedLanguage(Locale('fr')));
      expect(await deps.settings.appLanguage(), const FixedLanguage(Locale('fr')));
    });

    test('an upgrade on a French phone keeps following the device', () async {
      final deps = await testDeps();
      await addSummary(deps);
      expect(await deps.settings.appLanguageAtStartup(const [Locale('fr', 'FR')]),
          AppLanguage.system);
    });

    test('a stored choice wins', () async {
      final deps = await testDeps();
      await addSummary(deps);
      await deps.settings.setAppLanguage(AppLanguage.system);
      expect(await deps.settings.appLanguageAtStartup(const [Locale('en', 'US')]),
          AppLanguage.system);
    });
  });

  // protects=the French translation exists only in the French app; fails_when=the English app
  // shows or offers it, or the French app loses it; no_claim=the translation call itself.
  group('SummaryEntry in each app language', () {
    Future<SummaryEntry> entry({String displayLang = 'orig', bool translated = false}) async {
      final result = SummaryResult.fromJson(
          jsonDecode(await fileFixture('summary_en_long.json')) as Map<String, dynamic>);
      final fr = SummaryResult.fromJson(
              jsonDecode(await fileFixture('summary_fr.json')) as Map<String, dynamic>)
          .analysis;
      return SummaryEntry(
        id: 'e',
        sourceUrl: result.thread.permalink,
        thread: result.thread,
        provider: result.meta.provider,
        model: result.meta.model,
        analysis: result.analysis,
        analysisFr: translated ? fr : null,
        displayLang: displayLang,
        commentsAnalyzed: result.meta.commentsAnalyzed,
        commentsTotal: result.meta.commentsTotal,
        createdAt: DateTime(2026, 10, 1),
      );
    }

    test('an English thread can be translated in the French app only', () async {
      final e = await entry();
      expect(e.analysis.language, 'en');
      expect(e.canTranslateIn('fr'), isTrue);
      expect(e.canTranslateIn('en'), isFalse);
    });

    test('a translated summary shows French in the French app', () async {
      final e = await entry(displayLang: 'fr', translated: true);
      expect(e.displayedIn('fr').language, 'fr');
    });

    test('the English app shows the original even when French was chosen', () async {
      final e = await entry(displayLang: 'fr', translated: true);
      expect(e.displayedIn('en').language, 'en');
    });

    test('the original is shown until a translation exists', () async {
      final e = await entry(displayLang: 'fr');
      expect(e.displayedIn('fr').language, 'en');
    });
  });
}
