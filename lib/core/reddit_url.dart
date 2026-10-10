/// Reddit link helpers: find a link in shared text, recognise a post id for
/// deduplication (spec D-10). Short `/s/` links are resolved by the Reddit
/// client (spec « Normalisation des URL »).
library;

const _redditHosts = {
  'reddit.com',
  'www.reddit.com',
  'old.reddit.com',
  'new.reddit.com',
  'np.reddit.com',
  'm.reddit.com',
  'amp.reddit.com',
  'redd.it',
};

final _urlPattern = RegExp(r'https?://[^\s<>"]+', caseSensitive: false);
final _commentsPath = RegExp(r'/comments/([a-z0-9]{5,10})(?:/|$)', caseSensitive: false);
final _postId = RegExp(r'^[a-z0-9]{5,10}$');

/// Returns the first Reddit URL found in [text] (the Reddit app sometimes
/// shares « title + URL »), or null.
String? extractRedditUrl(String text) {
  for (final match in _urlPattern.allMatches(text)) {
    final raw = match.group(0)!.replaceAll(RegExp(r'[).,;!?]+$'), '');
    final uri = Uri.tryParse(raw);
    if (uri != null && _redditHosts.contains(uri.host.toLowerCase())) {
      return raw;
    }
  }
  return null;
}

bool isRedditUrl(String text) => extractRedditUrl(text) != null;

/// Post id for `/comments/<id>` and `redd.it/<id>` links, null otherwise
/// (short `/s/` links are resolved when the thread is fetched).
String? extractPostId(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !_redditHosts.contains(uri.host.toLowerCase())) return null;
  if (uri.host.toLowerCase() == 'redd.it') {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length == 1 && _postId.hasMatch(segments.first.toLowerCase())) {
      return segments.first.toLowerCase();
    }
    return null;
  }
  final match = _commentsPath.firstMatch(uri.path);
  return match?.group(1)?.toLowerCase();
}

/// Subreddit name from the URL path, used by the loading screen (spec D-6).
String? extractSubreddit(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;
  final segments = uri.pathSegments;
  final index = segments.indexOf('r');
  if (index >= 0 && index + 1 < segments.length && segments[index + 1].isNotEmpty) {
    return segments[index + 1];
  }
  return null;
}
