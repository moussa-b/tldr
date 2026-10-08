/// Comment as flattened from Reddit (pre-order, depth ≤ 4).
class RawComment {
  const RawComment({
    required this.id,
    required this.parentId,
    required this.depth,
    required this.author,
    required this.score,
    required this.body,
    this.stickied = false,
    this.distinguished,
  });

  final String id;
  final String? parentId;
  final int depth;
  final String author;
  final int score;
  final String body;
  final bool stickied;
  final String? distinguished;

  bool get isUsable =>
      body != '[deleted]' &&
      body != '[removed]' &&
      body.trim().isNotEmpty &&
      author != 'AutoModerator' &&
      !(stickied && distinguished == 'moderator');
}

/// A comment kept for the prompt. [placeholder] marks an excluded ancestor kept
/// only to preserve reply context (it costs nothing in the budgets).
class SelectedComment {
  const SelectedComment(this.comment, this.body, {this.placeholder = false});

  final RawComment comment;
  final String body;
  final bool placeholder;
}

class Selection {
  const Selection(this.comments, {required this.usableCount});

  final List<SelectedComment> comments;
  final int usableCount;

  int get analyzed => comments.where((c) => !c.placeholder).length;
  bool get truncated => analyzed < usableCount;
}

/// Budgeted selection (spec « Sélection des commentaires », eng review R9):
/// greedy by score, each candidate brings its missing ancestors, all counted
/// in the budgets; a candidate whose chain does not fit is skipped.
Selection selectComments(
  List<RawComment> all, {
  int maxComments = 200,
  int maxChars = 60000,
  int maxBodyChars = 2000,
}) {
  final byId = {for (final c in all) c.id: c};
  final order = {for (var i = 0; i < all.length; i++) all[i].id: i};
  final usable = all.where((c) => c.isUsable).toList();
  String truncate(String body) =>
      body.length > maxBodyChars ? '${body.substring(0, maxBodyChars)}…' : body;

  final kept = <String>{};
  final placeholders = <String>{};
  var count = 0;
  var chars = 0;

  final candidates = [...usable]..sort((a, b) => b.score.compareTo(a.score));
  for (final candidate in candidates) {
    if (kept.contains(candidate.id)) continue;
    final chain = <RawComment>[candidate];
    var parentId = candidate.parentId;
    while (parentId != null && !kept.contains(parentId) && !placeholders.contains(parentId)) {
      final parent = byId[parentId];
      if (parent == null) break;
      chain.add(parent);
      parentId = parent.parentId;
    }
    final costing = chain.where((c) => c.isUsable).toList();
    final addChars = costing.fold<int>(0, (sum, c) => sum + truncate(c.body).length);
    if (count + costing.length > maxComments || chars + addChars > maxChars) continue;
    for (final c in chain) {
      if (c.isUsable) {
        kept.add(c.id);
      } else {
        placeholders.add(c.id);
      }
    }
    count += costing.length;
    chars += addChars;
    if (count >= maxComments) break;
  }

  final selected = [
    for (final c in all)
      if (kept.contains(c.id))
        SelectedComment(c, truncate(c.body))
      else if (placeholders.contains(c.id))
        SelectedComment(c, '', placeholder: true),
  ]..sort((a, b) => order[a.comment.id]!.compareTo(order[b.comment.id]!));

  return Selection(selected, usableCount: usable.length);
}
