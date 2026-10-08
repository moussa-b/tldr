import 'package:flutter_test/flutter_test.dart';
import 'package:tldr/core/reddit_url.dart';

void main() {
  group('extractRedditUrl', () {
    final cases = <String, String?>{
      'https://www.reddit.com/r/france/comments/1abc23d/votre_avis/':
          'https://www.reddit.com/r/france/comments/1abc23d/votre_avis/',
      'Regarde ça : https://www.reddit.com/r/france/s/AbCdEf123 trop bien':
          'https://www.reddit.com/r/france/s/AbCdEf123',
      'https://old.reddit.com/r/x/comments/1abc23d/t/': 'https://old.reddit.com/r/x/comments/1abc23d/t/',
      'https://np.reddit.com/r/x/comments/1abc23d/': 'https://np.reddit.com/r/x/comments/1abc23d/',
      'https://redd.it/1abc23d': 'https://redd.it/1abc23d',
      'https://m.reddit.com/r/x/comments/1abc23d/t/c0mment1/':
          'https://m.reddit.com/r/x/comments/1abc23d/t/c0mment1/',
      '(https://www.reddit.com/r/x/comments/1abc23d/t/).': 'https://www.reddit.com/r/x/comments/1abc23d/t/',
      'https://example.com/r/x/comments/1abc23d': null,
      'pas de lien ici': null,
      '': null,
    };
    cases.forEach((input, expected) {
      test('"$input"', () => expect(extractRedditUrl(input), expected));
    });
  });

  group('extractPostId', () {
    test('desktop, old, np, mobile and comment links share one id', () {
      for (final url in [
        'https://www.reddit.com/r/france/comments/1abc23d/votre_avis/',
        'https://old.reddit.com/r/france/comments/1abc23d/',
        'https://np.reddit.com/r/france/comments/1ABC23D/x/?utm=1#top',
        'https://m.reddit.com/r/france/comments/1abc23d/x/c0mment1/',
        'https://redd.it/1abc23d',
      ]) {
        expect(extractPostId(url), '1abc23d', reason: url);
      }
    });

    test('short share links and non-post URLs have no id', () {
      expect(extractPostId('https://www.reddit.com/r/france/s/AbCdEf123'), isNull);
      expect(extractPostId('https://www.reddit.com/r/france/'), isNull);
      expect(extractPostId('https://www.reddit.com/user/someone'), isNull);
      expect(extractPostId('https://example.com/comments/1abc23d'), isNull);
    });
  });

  test('extractSubreddit', () {
    expect(extractSubreddit('https://www.reddit.com/r/france/s/AbC'), 'france');
    expect(extractSubreddit('https://redd.it/1abc23d'), isNull);
  });
}
