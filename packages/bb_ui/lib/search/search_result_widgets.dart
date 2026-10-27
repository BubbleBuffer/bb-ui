// The search result widgets: marked text, one result row, a group header and
// the grouped list with its keyboard selection mark. They draw neutral
// [SearchResult]s and report taps by result id.

import 'package:flutter/widgets.dart';

import '../hover.dart';
import '../icons.dart';
import '../tokens.dart';
import 'search_result.dart';

/// [text] with the [highlights] ranges marked. Without ranges it is a plain
/// [Text], so the text stays as given.
class HighlightedText extends StatelessWidget {
  const HighlightedText(
    this.text, {
    super.key,
    required this.style,
    this.highlights = const [],
    this.maxLines = 1,
  });
  final String text;
  final TextStyle style;
  final List<TextRange> highlights;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final mark = context.colors.textSelection;
    if (highlights.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    final spans = <InlineSpan>[];
    var at = 0;
    for (final range in highlights) {
      if (range.start > at) {
        spans.add(TextSpan(text: text.substring(at, range.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(range.start, range.end),
          style: TextStyle(backgroundColor: mark),
        ),
      );
      at = range.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// One search result: its icon, title, optional secondary line and snippet.
/// The result's [SearchResult.rowKey] keys the row.
class SearchResultRow extends StatelessWidget {
  const SearchResultRow({
    super.key,
    required this.result,
    required this.onTap,
    this.showTypeLabel = false,
  });
  final SearchResult result;
  final VoidCallback onTap;

  /// Whether to draw [SearchResult.typeLabel] at the end of the row.
  final bool showTypeLabel;

  /// The row's height.
  static double extent(bool mobile) => mobile ? 72 : 64;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    final m = context.mobile;
    final base = ts(
      m ? ty.body : ty.ui,
      result.titleTone == SearchTitleTone.normal
          ? c.textPrimary
          : c.textSecondary,
      weight: 500,
    );
    final titleStyle = result.titleTone == SearchTitleTone.standIn
        ? base.copyWith(color: c.textTertiary, fontStyle: FontStyle.italic)
        : base;
    final typeLabel = result.typeLabel;
    return Hover(
      key: result.rowKey,
      onTap: onTap,
      radius: m ? 0 : Radii.md,
      padding: EdgeInsets.symmetric(horizontal: m ? Layout.gutter : 8),
      child: Row(
        children: [
          result.leading ??
              Icon20(
                result.icon ?? Ico.page,
                size: m ? 22 : 20,
                color: c.iconSecondary,
              ),
          SizedBox(width: m ? 12 : 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HighlightedText(
                  result.title,
                  maxLines: result.titleMaxLines,
                  style: titleStyle,
                  highlights: result.titleHighlights,
                ),
                if (result.secondary.isNotEmpty)
                  Text(
                    result.secondary,
                    key: result.secondaryKey,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts(ty.uiSmall, c.textTertiary, weight: 400),
                  ),
                if (result.snippet.isNotEmpty)
                  HighlightedText(
                    result.snippet,
                    key: result.snippetKey,
                    style: ts(ty.uiSmall, c.textSecondary, weight: 400),
                    highlights: result.snippetHighlights,
                  ),
              ],
            ),
          ),
          if (showTypeLabel && typeLabel != null) ...[
            SizedBox(width: m ? 12 : 10),
            Text(
              typeLabel.toUpperCase(),
              maxLines: 1,
              style: ts(ty.uiSmall, c.textTertiary, weight: 500, mono: true),
            ),
          ],
        ],
      ),
    );
  }
}

/// The small group label above a run of results, in the mono face group
/// labels use.
class SearchGroupHeader extends StatelessWidget {
  const SearchGroupHeader(this.section, {super.key});
  final SearchResultSection section;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    final m = context.mobile;
    return Padding(
      padding: EdgeInsets.fromLTRB(m ? Layout.gutter : 10, 10, 10, 4),
      child: Text(
        section.label.toUpperCase(),
        style: ts(ty.uiSmall, c.textTertiary, weight: 500, mono: true),
      ),
    );
  }
}

/// The grouped results: a header per section, then its rows. [active] is the
/// keyboard selection, an index into the flattened results (desktop only).
class SearchResultsList extends StatelessWidget {
  const SearchResultsList({
    super.key,
    required this.sections,
    required this.onPick,
    required this.mobile,
    this.active,
    this.padding = EdgeInsets.zero,
  });
  final List<SearchResultSection> sections;
  final ValueChanged<SearchResult> onPick;
  final bool mobile;
  final int? active;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Headers have no index; rows carry their position in the flat order.
    final items =
        <({SearchResultSection? header, SearchResult? result, int index})>[];
    var index = 0;
    for (final section in sections) {
      items.add((header: section, result: null, index: -1));
      for (final result in section.results) {
        items.add((header: null, result: result, index: index++));
      }
    }
    return ListView.builder(
      padding: padding,
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final result = item.result;
        if (result == null) {
          final header = item.header!;
          return SearchGroupHeader(
            header,
            key: ValueKey('search-group-${header.id}'),
          );
        }
        final row = SizedBox(
          height: SearchResultRow.extent(mobile),
          child: SearchResultRow(result: result, onTap: () => onPick(result)),
        );
        if (mobile) return row;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: item.index == active ? c.bgHover : null,
            borderRadius: Radii.ctl,
          ),
          child: row,
        );
      },
    );
  }
}
