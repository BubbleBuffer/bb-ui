// The palette's matching: case-insensitive, spaces in the query ignored. A
// contiguous match beats a spread-out one, a match at a word start beats one
// in the middle of a word, and an earlier match beats a later one.

import 'package:flutter/widgets.dart';

/// How well a query matches a text, and where (ranges index into the text).
@immutable
class FuzzyMatch {
  const FuzzyMatch(this.score, this.ranges);
  final int score;
  final List<TextRange> ranges;
}

bool _wordStart(String text, int i) =>
    i == 0 || !RegExp(r'[A-Za-z0-9]').hasMatch(text[i - 1]);

/// The match of [query] in [text], or null when the characters of the query
/// do not all appear in order. An empty query matches everything with no
/// ranges.
FuzzyMatch? fuzzyMatch(String query, String text) {
  final q = query.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  if (q.isEmpty) return const FuzzyMatch(0, []);
  final t = text.toLowerCase();
  // `toLowerCase` may change a length (a few letters expand); then offsets
  // would not index the original text, so give up on those texts.
  if (t.length != text.length) return null;

  // Contiguous: the best placement is the first at a word start, else the
  // first anywhere.
  var first = -1;
  var best = -1;
  for (var at = t.indexOf(q); at >= 0; at = t.indexOf(q, at + 1)) {
    if (first < 0) first = at;
    if (_wordStart(text, at)) {
      best = at;
      break;
    }
  }
  if (first >= 0) {
    final at = best >= 0 ? best : first;
    final score = 1000 + (best >= 0 ? 200 : 0) + (at == 0 ? 100 : 0) - at;
    return FuzzyMatch(score, [TextRange(start: at, end: at + q.length)]);
  }

  // Spread out: each query character takes the next place it appears.
  final hits = <int>[];
  var from = 0;
  for (var k = 0; k < q.length; k++) {
    final at = t.indexOf(q[k], from);
    if (at < 0) return null;
    hits.add(at);
    from = at + 1;
  }
  var score = 0;
  for (var k = 0; k < hits.length; k++) {
    score += 10;
    if (_wordStart(text, hits[k])) score += 8;
    if (k > 0 && hits[k] == hits[k - 1] + 1) score += 6;
  }
  score -= hits.first;
  final ranges = <TextRange>[];
  for (final at in hits) {
    if (ranges.isNotEmpty && ranges.last.end == at) {
      ranges.last = TextRange(start: ranges.last.start, end: at + 1);
    } else {
      ranges.add(TextRange(start: at, end: at + 1));
    }
  }
  return FuzzyMatch(score, ranges);
}
