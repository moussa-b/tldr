import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tldr/data/models/models.dart';
import 'package:tldr/features/summary/summary_widgets.dart';
import '../helpers.dart';

void main() {
  testWidgets('the « +N » emotions button stays inline', (tester) async {
    // Regression: ISSUE-003 — « +1 » took a whole line and pushed the toxicity below it
    // Found by /qa on 2026-10-11
    // Report: docs/qa/2026-10-11/qa-report-tldr-2026-10-11.md
    await tester.pumpWidget(localized(
      const Scaffold(
        body: SizedBox(
          width: 400,
          child: VerdictLine(
            analysis: Analysis(
              language: 'en',
              shortSummary: 's',
              detailedSummary: 'd',
              sentiment: Sentiment.positive,
              emotions: ['fear', 'relief', 'hope'],
              toxicity: 0.1,
              aiTake: 'a',
            ),
          ),
        ),
      ),
    ));

    final more = tester.getSize(find.ancestor(of: find.text(' +1'), matching: find.byType(InkWell)));
    expect(more.width, lessThan(100));
    expect(more.height, greaterThanOrEqualTo(48));
    expect(find.text('+1'), findsNothing);
  });
}
