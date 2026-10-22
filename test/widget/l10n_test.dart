import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tldr/data/models/models.dart';
import 'package:tldr/features/settings/language_picker.dart';
import 'package:tldr/l10n/app_language.dart';

import '../helpers.dart';

const _en = FixedLanguage(Locale('en'));

Future<void> _tearDownApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

/// Words that only appear in the French copy.
final _french = RegExp(r'Réglages|Résume|Récents|Coller|clé|Voir un exemple|Annuler|Réessayer|'
    r'Traduire|En bref|Points de vue|commentaires|Étape|Choisis|Fournisseur|Modèle|Effacer|Langue');

/// Every text on screen.
List<String> _texts(WidgetTester tester) => [
      for (final w in tester.widgetList<Text>(find.byType(Text)))
        if (w.data != null) w.data! else if (w.textSpan != null) w.textSpan!.toPlainText(),
    ];

Future<String> _storeEnglishThread(TestDeps deps, {bool translated = false}) async {
  final result = SummaryResult.fromJson(
      jsonDecode(await fileFixture('summary_en_long.json')) as Map<String, dynamic>);
  final entry = await deps.dao.upsert(result, sourceUrl: result.thread.permalink);
  if (translated) {
    final fr = SummaryResult.fromJson(
            jsonDecode(await fileFixture('summary_fr.json')) as Map<String, dynamic>)
        .analysis;
    await deps.dao.saveTranslation(entry.id, fr);
    await deps.dao.setDisplayLang(entry.id, 'fr');
  }
  return entry.id;
}

void main() {
  setUpAll(initTestEnv);

  // protects=the English app has no French text (spec criterion 1); fails_when=a French string
  // is left on home or in settings; no_claim=screens not opened here.
  testWidgets('home and settings are in English', (tester) async {
    final deps = await tester.runAsync(() => testDeps(language: _en));
    await pumpApp(tester, deps!);
    expect(find.text('Summarize a thread in 3 steps'), findsOneWidget);
    expect(find.text('See an example'), findsOneWidget);
    expect(_texts(tester).where(_french.hasMatch), isEmpty);
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await tester.pump();
    expect(find.text('Version 1.1.0'), findsOneWidget);
    expect(_texts(tester).where(_french.hasMatch), isEmpty);
    await _tearDownApp(tester);
  });

  // protects=choosing French switches the whole app at once and is saved (criterion 3);
  // fails_when=a restart is needed or the choice is lost; no_claim=a real app restart.
  testWidgets('choosing Français switches the app without a restart', (tester) async {
    final deps = await tester.runAsync(() => testDeps(language: AppLanguage.system));
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpApp(tester, deps!);
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester);
    expect(find.text('Device language'), findsOneWidget);
    await tester.tap(find.text('Language'));
    await settle(tester);
    await tester.tap(find.text('Français'));
    await settle(tester);
    expect(find.text('Réglages'), findsOneWidget);
    expect(find.text('Langue'), findsOneWidget);
    expect(await tester.runAsync(deps.settings.appLanguage), const FixedLanguage(Locale('fr')));
    await _tearDownApp(tester);
  });

  // protects=the device language is followed when the setting says so (criteria 1, 2);
  // fails_when=a French device shows English or a Spanish one shows French;
  // no_claim=the OS per-app language setting (checked by hand).
  testWidgets('the device language decides in « Device language » mode', (tester) async {
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    for (final (device, expected) in [
      (const Locale('fr', 'CA'), 'Résume un thread en 3 gestes'),
      (const Locale('es', 'ES'), 'Summarize a thread in 3 steps'),
    ]) {
      final deps = await tester.runAsync(() => testDeps(language: AppLanguage.system));
      tester.platformDispatcher.localesTestValue = [device];
      await pumpApp(tester, deps!);
      expect(find.text(expected), findsOneWidget, reason: '$device');
      await _tearDownApp(tester);
      tester.platformDispatcher.clearLocalesTestValue();
    }
  });

  // protects=a device language change while the app runs switches it, and wins over a
  // language chosen in the app; fails_when=the observer is not wired or the in-app choice
  // ignores the system; no_claim=what each platform reports.
  testWidgets('a device language change while running switches the app', (tester) async {
    final deps = await tester.runAsync(() => testDeps(language: AppLanguage.system));
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpApp(tester, deps!);
    expect(find.text('Summarize a thread in 3 steps'), findsOneWidget);
    tester.platformDispatcher.localesTestValue = const [Locale('fr', 'FR')];
    await settle(tester);
    expect(find.text('Résume un thread en 3 gestes'), findsOneWidget);
    await _tearDownApp(tester);

    final fixed = await tester.runAsync(() => testDeps(language: _en));
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    await pumpApp(tester, fixed!);
    expect(find.text('Summarize a thread in 3 steps'), findsOneWidget);
    tester.platformDispatcher.localesTestValue = const [Locale('fr', 'FR')];
    await settle(tester);
    expect(find.text('Résume un thread en 3 gestes'), findsOneWidget);
    expect(await tester.runAsync(fixed.settings.appLanguage), AppLanguage.system);
    await _tearDownApp(tester);
  });

  // protects=a language added to the ARB files shows up in the picker, sorted by name, and a
  // tap returns that language (criterion 8); fails_when=the picker hard-codes or misorders its
  // languages; no_claim=the added language's texts.
  testWidgets('the picker lists the device option plus every language', (tester) async {
    AppLanguage? picked;
    await tester.pumpWidget(localized(Scaffold(
      body: LanguagePicker(
        selected: AppLanguage.system,
        onSelected: (language) => picked = language,
        locales: const [Locale('fr'), Locale('en'), Locale('de')],
      ),
    )));
    final titles = [
      for (final tile in tester.widgetList<RadioListTile<AppLanguage>>(
          find.byType(RadioListTile<AppLanguage>)))
        (tile.title! as Text).data,
    ];
    expect(titles, ['Langue de l\'appareil', 'de', 'English', 'Français']);
    await tester.tap(find.text('English'));
    expect(picked, const FixedLanguage(Locale('en')));
  });

  // protects=the English app does not warn about a translation it never shows;
  // fails_when=« The French translation will be deleted » shows in English; no_claim=the
  // regeneration itself.
  testWidgets('regenerating in English asks nothing about the translation', (tester) async {
    final deps = await tester.runAsync(() => testDeps(language: _en));
    await tester.runAsync(() => _storeEnglishThread(deps!, translated: true));
    await pumpApp(tester, deps!);
    await tester.tap(find.byType(Dismissible).first);
    await settle(tester, rounds: 30);
    await tester.tap(find.byTooltip('More options'));
    await settle(tester);
    await tester.tap(find.text('Regenerate'));
    await settle(tester);
    expect(find.text('Regenerate this summary?'), findsNothing);
    await _tearDownApp(tester);
  });

  // protects=« Traduire en français » in the French app only (criteria 4, 5); fails_when=the
  // English app offers it, or the French app loses it; no_claim=the translation call.
  testWidgets('the French translation is offered in the French app only', (tester) async {
    for (final (language, offered) in [(const FixedLanguage(Locale('fr')), true), (_en, false)]) {
      final deps = await tester.runAsync(() => testDeps(language: language));
      final id = await tester.runAsync(() => _storeEnglishThread(deps!));
      await pumpApp(tester, deps!);
      await tester.tap(find.byType(Dismissible).first);
      await settle(tester, rounds: 30);
      expect(find.text('Traduire en français'), offered ? findsOneWidget : findsNothing,
          reason: '$language $id');
      expect(find.text('Translate to French'), findsNothing);
      await _tearDownApp(tester);
    }
  });

  // protects=a summary translated earlier shows its original in English, and the French toggle
  // comes back in French (criterion 5); fails_when=English shows French text or a VO|FR toggle;
  // no_claim=none beyond protects.
  testWidgets('a translated summary shows its original in the English app', (tester) async {
    final deps = await tester.runAsync(() => testDeps(language: _en));
    await tester.runAsync(() => _storeEnglishThread(deps!, translated: true));
    await pumpApp(tester, deps!);
    await tester.tap(find.byType(Dismissible).first);
    await settle(tester, rounds: 30);
    expect(find.text('In short'), findsOneWidget);
    expect(find.byType(SegmentedButton<String>), findsNothing);
    expect(find.text('En bref'), findsNothing);
    await _tearDownApp(tester);

    // Back in French, the stored translation and its toggle are there again.
    final frDeps = await tester.runAsync(testDeps);
    await tester.runAsync(() => _storeEnglishThread(frDeps!, translated: true));
    await pumpApp(tester, frDeps!);
    await tester.tap(find.byType(Dismissible).first);
    await settle(tester, rounds: 30);
    expect(find.byType(SegmentedButton<String>), findsOneWidget);
    expect(find.text('En bref'), findsOneWidget);
    await _tearDownApp(tester);
  });

  // protects=the example follows the app's language (criterion 7); fails_when=English shows the
  // French example; no_claim=the example's wording.
  testWidgets('the example is in the app language', (tester) async {
    final deps = await tester.runAsync(() => testDeps(language: _en));
    await pumpApp(tester, deps!);
    await tester.tap(find.text('See an example'));
    await settle(tester, rounds: 40);
    expect(find.textContaining('Example: this summary'), findsOneWidget);
    expect(find.text('What do you think of the 4-day work week?'), findsOneWidget);
    await _tearDownApp(tester);
  });

  // protects=the example follows a language change made while it is on screen;
  // fails_when=a French example stays under an English app or the reverse; no_claim=none.
  testWidgets('the example follows a language change on screen', (tester) async {
    final deps = await tester.runAsync(() => testDeps(language: AppLanguage.system));
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpApp(tester, deps!);
    await tester.tap(find.text('See an example'));
    await settle(tester, rounds: 40);
    expect(find.text('What do you think of the 4-day work week?'), findsOneWidget);
    tester.platformDispatcher.localesTestValue = const [Locale('fr', 'FR')];
    await settle(tester, rounds: 40);
    expect(find.text('Votre avis sur la semaine de 4 jours ?'), findsOneWidget);
    await _tearDownApp(tester);
  });

  // protects=English copy fits a 360 dp phone at 100 % and 200 % text (criterion 9);
  // fails_when=any screen overflows; no_claim=visual quality, other widths.
  for (final scale in [1.0, 2.0]) {
    testWidgets('English screens fit 360 dp at ${(scale * 100).round()} % text', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      // Home, then settings.
      var deps = await tester.runAsync(() => testDeps(language: _en));
      await pumpApp(tester, deps!);
      expect(tester.takeException(), isNull, reason: 'home');
      await tester.tap(find.byTooltip('Settings'));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'settings');
      await _tearDownApp(tester);

      // Key setup, both steps.
      deps = await tester.runAsync(() => testDeps(language: _en, keys: {}));
      await pumpApp(tester, deps!);
      expect(tester.takeException(), isNull, reason: 'setup 1');
      await tester.dragUntilVisible(
          find.text('Continue'), find.byType(ListView).last, const Offset(0, -200));
      await tester.tap(find.text('Continue'));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'setup 2');
      await _tearDownApp(tester);

      // A summary, then an error.
      deps = await tester.runAsync(() => testDeps(language: _en));
      await pumpApp(tester, deps!,
          initialShare: 'https://www.reddit.com/r/france/comments/1abc23d/x/');
      await settle(tester, rounds: 40);
      expect(tester.takeException(), isNull, reason: 'summary');
      await _tearDownApp(tester);
      deps = await tester.runAsync(() => testDeps(language: _en));
      await pumpApp(tester, deps!,
          initialShare: 'https://www.reddit.com/r/x/comments/notfound/');
      await settle(tester, rounds: 40);
      expect(find.text('Thread not found'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'error');
      await _tearDownApp(tester);
    });
  }
}
