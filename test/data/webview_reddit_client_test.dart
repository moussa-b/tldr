import 'package:flutter_test/flutter_test.dart';
import 'package:tldr/core/errors.dart';
import 'package:tldr/data/engine/webview_reddit_client.dart';

Matcher apiError(String code, {String? reason}) => isA<ApiError>()
    .having((e) => e.code, 'code', code)
    .having((e) => e.reason, 'reason', reason);

void main() {
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

    test('rejects JSON that is not a listing', () {
      expect(() => decodeListingBody(200, '{"kind":"Listing"}'),
          throwsA(apiError('THREAD_NOT_FOUND')));
    });
  });
}
