import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tldr/data/models/models.dart';

import '../helpers.dart';

Future<void> tearDownApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(initTestEnv);

  testWidgets('home empty state teaches the share gesture', (tester) async {
    final deps = await tester.runAsync(testDeps);
    await pumpApp(tester, deps!);
    expect(find.text('Résume un thread en 3 gestes'), findsOneWidget);
    expect(find.text('Voir un exemple'), findsOneWidget);
    expect(find.text('Ajoute ta clé IA pour commencer'), findsNothing);
    await tearDownApp(tester);
  });

  testWidgets('first launch without any key opens the setup', (tester) async {
    final deps = await tester.runAsync(() => testDeps(keys: {}));
    await pumpApp(tester, deps!);
    expect(find.text('Choisis ton fournisseur'), findsOneWidget);
    await tester.tap(find.text('Continuer'));
    await settle(tester);
    expect(find.text('Colle ta clé Gemini'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('typing a link summarizes it and back returns to a filled history', (tester) async {
    final deps = await tester.runAsync(testDeps);
    await pumpApp(tester, deps!);
    await tester.enterText(find.byType(TextField), 'https://www.reddit.com/r/france/comments/1abc23d/x/');
    await tester.pump();
    await tester.tap(find.text('Résumer'));
    await settle(tester, rounds: 40);
    expect(find.text('En bref'), findsOneWidget);
    expect(find.text('L\'avis de l\'IA'), findsOneWidget);
    expect(find.textContaining('commentaires analysés sur'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.text('Récents'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('a non-Reddit link shows a helper error and does not navigate', (tester) async {
    final deps = await tester.runAsync(testDeps);
    await pumpApp(tester, deps!);
    await tester.enterText(find.byType(TextField), 'https://example.com/article');
    await tester.pump();
    await tester.tap(find.text('Résumer'));
    await tester.pump();
    expect(find.text('Ce lien n\'est pas un thread Reddit'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('a shared link opens the summary on top of home', (tester) async {
    final deps = await tester.runAsync(testDeps);
    await pumpApp(tester, deps!,
        initialShare: 'Regarde https://www.reddit.com/r/AskReddit/comments/1xyz98q/x/');
    await settle(tester, rounds: 40);
    expect(find.text('En bref'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.text('Récents'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('an error shows its French copy with a home action', (tester) async {
    final deps = await tester.runAsync(testDeps);
    await pumpApp(tester, deps!, initialShare: 'https://www.reddit.com/r/x/comments/notfound/');
    await settle(tester, rounds: 40);
    expect(find.text('Thread introuvable'), findsOneWidget);
    expect(find.text('Retour à l\'accueil'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('a key error offers the settings', (tester) async {
    final deps = await tester.runAsync(() => testDeps(keys: {ProviderId.gemini: 'invalid'}));
    await pumpApp(tester, deps!, initialShare: 'https://www.reddit.com/r/x/comments/1abc23d/');
    await settle(tester, rounds: 40);
    expect(find.text('Ta clé Gemini est refusée'), findsOneWidget);
    expect(find.text('Ouvrir les réglages'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('sharing the same thread twice reopens it with a banner', (tester) async {
    final deps = await tester.runAsync(testDeps);
    const url = 'https://www.reddit.com/r/france/comments/1abc23d/x/';
    final share = await pumpApp(tester, deps!, initialShare: url);
    await settle(tester, rounds: 40);
    final calls = (deps.api as dynamic).summarizeCalls as int;
    share.share(url);
    await settle(tester, rounds: 40);
    expect(find.textContaining('Déjà résumé'), findsOneWidget);
    expect((deps.api as dynamic).summarizeCalls, calls);
    await tearDownApp(tester);
  });

  testWidgets('summary survives 200 % text scale and meets tap/contrast guidelines', (tester) async {
    final deps = await tester.runAsync(testDeps);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester, deps!, initialShare: 'https://www.reddit.com/r/france/comments/1abc23d/x/');
    await settle(tester, rounds: 40);
    expect(tester.takeException(), isNull);
    expect(find.text('En bref'), findsOneWidget);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.pump();
    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
    await tearDownApp(tester);
  });

  testWidgets('long press on a history row opens delete and share', (tester) async {
    final deps = await tester.runAsync(testDeps);
    await tester.runAsync(() => deps!.service.summarize('https://www.reddit.com/r/france/comments/1abc23d/x/'));
    await pumpApp(tester, deps!);
    expect(find.text('Récents'), findsOneWidget);
    await tester.longPress(find.byType(Dismissible).first);
    await settle(tester);
    expect(find.text('Supprimer'), findsOneWidget);
    await tester.tap(find.text('Supprimer'));
    await settle(tester);
    expect(find.text('Résumé supprimé'), findsOneWidget);
    expect(find.text('Résume un thread en 3 gestes'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('demo summary needs no key and no network', (tester) async {
    final deps = await tester.runAsync(testDeps);
    await pumpApp(tester, deps!);
    await tester.tap(find.text('Voir un exemple'));
    await settle(tester, rounds: 40);
    expect(find.textContaining('Exemple'), findsOneWidget);
    expect(find.text('En bref'), findsOneWidget);
    await tearDownApp(tester);
  });
}
