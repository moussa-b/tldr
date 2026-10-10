import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tldr/features/summary/dust_veil.dart';

Widget _veil(bool covered, {String child = 'page', bool reduceMotion = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: DustVeil(covered: covered, child: Text(child)),
      ),
    );

Finder get _dust =>
    find.descendant(of: find.byType(DustVeil), matching: find.byType(CustomPaint));

void main() {
  testWidgets('no dust while uncovered', (tester) async {
    await tester.pumpWidget(_veil(false));
    expect(find.text('page'), findsOneWidget);
    expect(_dust, findsNothing);
  });

  testWidgets('dust covers the page, then lifts off the new child', (tester) async {
    await tester.pumpWidget(_veil(false));
    await tester.pumpWidget(_veil(true));
    await tester.pump(const Duration(milliseconds: 1000));
    expect(_dust, findsOneWidget);

    await tester.pumpWidget(_veil(false, child: 'summary'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(_dust, findsOneWidget, reason: 'the reveal is still playing');
    expect(find.text('summary'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(_dust, findsNothing);
  });

  testWidgets('starts covered when built covered', (tester) async {
    await tester.pumpWidget(_veil(true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_dust, findsOneWidget);
  });

  testWidgets('reduced motion: still dust, instant reveal', (tester) async {
    await tester.pumpWidget(_veil(false, reduceMotion: true));
    await tester.pumpWidget(_veil(true, reduceMotion: true));
    await tester.pump();
    expect(_dust, findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(_veil(false, child: 'summary', reduceMotion: true));
    await tester.pump();
    expect(_dust, findsNothing);
    expect(find.text('summary'), findsOneWidget);
  });
}
