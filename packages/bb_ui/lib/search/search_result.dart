// The neutral view models of the search widgets: one result, a titled group of
// results and one filter chip. A host maps its own hits onto them; nothing
// here knows what a hit is, where it opens or what the host's types are.

import 'package:flutter/widgets.dart';

import '../icons.dart';

/// How a result's title reads: as a name, as a name that is missing, or as a
/// stand-in for one (the first line of an untitled page, say).
enum SearchTitleTone {
  /// A real title, in primary text.
  normal,

  /// An empty title's placeholder, in secondary text.
  muted,

  /// A stand-in for a missing title, in tertiary italics.
  standIn,
}

/// The ranges of [text] that match any of [terms], ignoring case. Terms are
/// matched as literal text, never as patterns. The ranges are in order and do
/// not overlap; no terms, or no match, gives none.
List<TextRange> termHighlights(String text, List<String> terms) {
  if (terms.isEmpty) return const [];
  final pattern = RegExp(
    terms.map(RegExp.escape).join('|'),
    caseSensitive: false,
  );
  return [
    for (final m in pattern.allMatches(text))
      TextRange(start: m.start, end: m.end),
  ];
}

/// One search result, as the row draws it: an icon, a title, an optional
/// secondary line (a path, a source) and an optional snippet. Highlight ranges
/// index into [title] and [snippet] and are drawn as marked text.
@immutable
class SearchResult {
  const SearchResult({
    required this.id,
    required this.title,
    this.titleTone = SearchTitleTone.normal,
    this.titleMaxLines = 1,
    this.titleHighlights = const [],
    this.secondary = '',
    this.secondaryKey,
    this.snippet = '',
    this.snippetKey,
    this.snippetHighlights = const [],
    this.icon,
    this.leading,
    this.typeLabel,
    this.rowKey,
  });

  /// Unique among the results shown; the selection callbacks report it.
  final String id;
  final String title;
  final SearchTitleTone titleTone;
  final int titleMaxLines;
  final List<TextRange> titleHighlights;

  /// A line between the title and the snippet, in tertiary text (a page path,
  /// say). Empty draws none.
  final String secondary;
  final Key? secondaryKey;

  /// The matching text. Empty draws none.
  final String snippet;
  final Key? snippetKey;
  final List<TextRange> snippetHighlights;

  /// The row's icon. [leading] replaces it when the host draws its own.
  final Ico? icon;
  final Widget? leading;

  /// What kind of result this is (a source or type name). A row draws it at
  /// its end only when asked to ([SearchResultRow.showTypeLabel]): grouped
  /// lists already say it in the group label.
  final String? typeLabel;

  /// The key of the row, so a host's tests and tools can find it.
  final Key? rowKey;
}

/// A titled run of results: the group label above its rows.
@immutable
class SearchResultSection {
  const SearchResultSection({
    required this.id,
    required this.label,
    required this.results,
  });

  /// Names the group's header: it is keyed `search-group-<id>`.
  final String id;
  final String label;
  final List<SearchResult> results;
}

/// One filter chip. A selected chip is filled; a removable one ends with a
/// close mark, and its tap is the host's to read as "remove".
@immutable
class SearchTypeChip {
  const SearchTypeChip({
    required this.id,
    required this.label,
    required this.selected,
    required this.onTap,
    this.removable = false,
  });

  /// The chip is keyed `search-type-<id>`.
  final String id;
  final String label;
  final bool selected;
  final bool removable;
  final VoidCallback onTap;
}
