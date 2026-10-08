import 'package:flutter_test/flutter_test.dart';
import 'package:tldr/data/engine/comment_selector.dart';

RawComment c(String id, {String? parent, int depth = 0, int score = 1, String body = 'hello', String author = 'u'}) =>
    RawComment(id: id, parentId: parent, depth: depth, author: author, score: score, body: body);

void main() {
  test('excludes deleted, removed and AutoModerator comments', () {
    final s = selectComments([
      c('a', body: '[deleted]'),
      c('b', body: '[removed]'),
      c('d', author: 'AutoModerator'),
      c('e'),
    ]);
    expect(s.comments.map((x) => x.comment.id), ['e']);
    expect(s.usableCount, 1);
  });

  test('a highly voted reply brings its low-voted parent (R9)', () {
    final s = selectComments([
      c('p', score: 1, body: 'parent'),
      c('r', parent: 'p', depth: 1, score: 500, body: 'reply'),
      c('x', score: 50),
    ], maxComments: 2);
    expect(s.comments.map((x) => x.comment.id), ['p', 'r']);
    expect(s.truncated, isTrue);
  });

  test('a candidate whose ancestor chain does not fit is skipped', () {
    final s = selectComments([
      c('p', body: 'x' * 30),
      c('r', parent: 'p', depth: 1, score: 100, body: 'y' * 30),
      c('small', score: 10, body: 'z' * 10),
    ], maxChars: 35);
    expect(s.comments.map((x) => x.comment.id), ['small']);
  });

  test('an excluded ancestor becomes a free placeholder', () {
    final s = selectComments([
      c('p', body: '[deleted]'),
      c('r', parent: 'p', depth: 1, score: 10),
    ], maxComments: 1);
    expect(s.comments.map((x) => (x.comment.id, x.placeholder)), [('p', true), ('r', false)]);
    expect(s.analyzed, 1);
  });

  test('keeps tree order and truncates long bodies', () {
    final s = selectComments([
      c('a', score: 1),
      c('b', score: 9, body: 'w' * 2500),
    ]);
    expect(s.comments.map((x) => x.comment.id), ['a', 'b']);
    expect(s.comments.last.body.length, 2001);
  });
}
