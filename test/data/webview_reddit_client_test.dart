import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tldr/core/errors.dart';
import 'package:tldr/data/engine/reddit_client.dart';
import 'package:tldr/data/engine/reddit_page.dart';
import 'package:tldr/data/engine/thread_script.dart';
import 'package:tldr/data/engine/webview_reddit_client.dart';

Matcher apiError(String code, {String? reason}) => isA<ApiError>()
    .having((e) => e.code, 'code', code)
    .having((e) => e.reason, 'reason', reason);

void main() {
  test('rejects non-Reddit and non-post links before opening a page', () async {
    final client = WebViewRedditClient();
    await expectLater(client.fetch('https://example.com/x'), throwsA(apiError('INVALID_URL')));
    await expectLater(
        client.fetch('https://www.reddit.com/r/france/'), throwsA(apiError('UNSUPPORTED_URL')));
  });

  group('decodeListingBody', () {
    test('returns the [post, comments] listing', () {
      final listing = decodeListingBody(200, '[{"kind":"Listing"},{"kind":"Listing"}]');
      expect(listing, hasLength(2));
    });

    test('maps a JSON 404 to THREAD_NOT_FOUND', () {
      expect(() => decodeListingBody(404, '{"message":"Not Found","error":404}'),
          throwsA(apiError('THREAD_NOT_FOUND')));
    });

    test('maps a JSON 403 to THREAD_UNAVAILABLE with its reason', () {
      expect(
          () => decodeListingBody(
              403, '{"reason":"quarantined","message":"Forbidden","error":403}'),
          throwsA(apiError('THREAD_UNAVAILABLE', reason: 'quarantined')));
      expect(() => decodeListingBody(403, '{"reason":"private","error":403}'),
          throwsA(apiError('THREAD_UNAVAILABLE', reason: 'private')));
    });

    test('maps an HTML 403 to Reddit blocking the client', () {
      expect(() => decodeListingBody(403, '<html>blocked</html>'),
          throwsA(apiError('REDDIT_UNAVAILABLE', reason: 'blocked')));
    });

    test('treats any other non-JSON body as Reddit unavailable', () {
      expect(() => decodeListingBody(200, '<html></html>'),
          throwsA(apiError('REDDIT_UNAVAILABLE')));
    });

    test('maps the error bodies of the page script', () {
      expect(() => decodeListingBody(404, '{"error":404}'), throwsA(apiError('THREAD_NOT_FOUND')));
    });

    test('rejects JSON that is not a listing', () {
      expect(() => decodeListingBody(200, '{"kind":"Listing"}'),
          throwsA(apiError('THREAD_NOT_FOUND')));
    });
  });

  test('a thread read by the page script parses into a thread', () {
    // test/fixtures/reddit_thread_founder.json: threadScript's answer on a real
    // thread, captured with tool/live_summary (DUMP_LISTING).
    final text = File('test/fixtures/reddit_thread_founder.json').readAsStringSync();
    final t = parseThreadListing(decodeListingBody(200, text));
    expect(t.thread.id, '1x1wi5n');
    expect(t.thread.subreddit, 'founder');
    expect(t.thread.title, isNotEmpty);
    expect(t.selftext, isNotEmpty);
    expect(t.comments.length, greaterThan(100));
    expect(t.comments.every((c) => c.depth <= 4), isTrue);
    expect(t.comments.where((c) => c.parentId != null), isNotEmpty);
    expect(t.comments.map((c) => c.id).toSet(), hasLength(t.comments.length));
  });

  group('threadScript', () {
    final script =
        threadScript(channel: 'TldrListing', nonce: 'abc123', postId: '1x1wi5n', deadlineMs: 42);

    test('fills in the channel, nonce, post and deadline', () {
      expect(script, contains('const channel = TldrListing,'));
      expect(script, contains('nonce: "abc123"'));
      expect(script, contains('shreddit-post[id="t3_1x1wi5n"]'));
      expect(script, contains('const left = () => 42 - Date.now();'));
      expect(script, isNot(contains(RegExp(r'\$[_a-zA-Z{]'))),
          reason: 'a Dart interpolation left as text');
    });

    test('keeps the JavaScript escapes the Dart string must not eat', () {
      expect(script, contains(r'TABLE|TR)$/;'));
      expect(script, contains(r'.replace(/\s+/g, " ")'));
      expect(script, contains(r'out += "\n";'));
      expect(script, contains(r'/^\/r\/([^/]+)/'));
    });
  });

  group('desktopUserAgent', () {
    test('turns Android WebView into desktop Chrome of the same version', () {
      expect(
          desktopUserAgent('Mozilla/5.0 (Linux; Android 16; sdk_gphone64_arm64 Build/BE2A; wv) '
              'AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/153.0.8010.36 '
              'Mobile Safari/537.36'),
          'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) '
          'Chrome/153.0.0.0 Safari/537.36');
    });

    test('turns an iPhone WebView into Safari on a Mac of the same version', () {
      expect(
          desktopUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) '
              'AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148'),
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 '
          '(KHTML, like Gecko) Version/18.6 Safari/605.1.15');
    });

    test('falls back to Safari when the user agent is unknown', () {
      expect(desktopUserAgent(''), contains('Version/18.6 Safari/605.1.15'));
    });
  });
}
