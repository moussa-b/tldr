import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The app's texts live in lib/l10n/app_*.arb only (spec « Langues »).
void main() {
  Map<String, dynamic> arb(String lang) =>
      jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;
  Iterable<String> keys(Map<String, dynamic> m) => m.keys.where((k) => !k.startsWith('@'));
  List<String> placeholders(String text) =>
      RegExp(r'\{(\w+)\}').allMatches(text).map((m) => m.group(1)!).toList()..sort();

  // protects=every text exists in every language with the same placeholders;
  // fails_when=a key or a {placeholder} is missing in one language; no_claim=the wording.
  test('every language has the same texts and placeholders', () {
    final en = arb('en');
    final files = Directory('lib/l10n')
        .listSync()
        .map((f) => f.path)
        .where((p) => RegExp(r'app_\w+\.arb$').hasMatch(p));
    for (final path in files) {
      final other = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      expect(keys(other).toSet(), keys(en).toSet(), reason: path);
      for (final key in keys(en)) {
        expect(placeholders(other[key] as String), placeholders(en[key] as String),
            reason: '$path $key');
      }
    }
  });

  // protects=no screen text is written in code (spec criterion 11); fails_when=a literal with
  // letters is passed to a text-showing parameter; no_claim=texts built in other ways (string
  // variables, interpolation without a leading literal).
  test('no text shown to the user is written in the code', () {
    final shown = RegExp(
        r"""(?:Text\(|label:\s*|title:\s*|content:\s*|tooltip:\s*|semanticsLabel:\s*|hintText:\s*|labelText:\s*|SnackBar\()\s*(?:const\s+)?(?:Text\()?\s*'((?:[^'\\]|\\.)*)'""");
    const allowed = {'TL;DR+', 'NSFW'};
    final offenders = <String>[];
    for (final dir in ['lib/features', 'lib/core', 'lib/app']) {
      for (final file in Directory(dir).listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        final source = file.readAsStringSync();
        for (final m in shown.allMatches(source)) {
          final text = m.group(1)!;
          final bare = text.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '');
          if (allowed.contains(text) || bare.startsWith('r/') && bare.length == 2) continue;
          if (RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(bare)) offenders.add('${file.path}: $text');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
