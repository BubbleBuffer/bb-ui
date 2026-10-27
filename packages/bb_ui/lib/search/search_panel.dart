// A search panel: the field, a slot for filters, the grouped results and the
// explanation lines. Up and down move the selection through the flattened
// results, Enter picks it, and the field takes focus on open. The host owns
// the query, the results and what picking one does.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../fields.dart';
import '../lines.dart';
import '../tokens.dart';
import 'search_result.dart';
import 'search_result_widgets.dart';

class SearchPanel extends StatefulWidget {
  const SearchPanel({
    super.key,
    required this.controller,
    required this.onQueryChanged,
    required this.onPick,
    required this.sections,
    this.fieldKey,
    this.placeholder,
    this.filters,
    this.idleNote = '',
    this.emptyNote = 'No results',
    this.narrowedNote,
    this.correction,
    this.correctionPrefix = 'Showing results for ',
    this.selectionResetKey,
  });
  final TextEditingController controller;

  /// Called with the new query text after the user types.
  final ValueChanged<String> onQueryChanged;

  /// Called with the result the user picked, by tap or by Enter.
  final ValueChanged<SearchResult> onPick;

  /// The results for the current query, or null when the query is empty.
  final List<SearchResultSection>? sections;

  /// The query field's key, and its placeholder (the field's own by default).
  final Key? fieldKey;
  final String? placeholder;

  /// Shown between the field and the results, such as a [SearchTypeChips] row.
  final Widget? filters;

  /// Shown instead of the results while the query is empty, and when no
  /// result matches.
  final String idleNote;
  final String emptyNote;

  /// A line under the results saying they are narrowed, or null for none.
  /// Keyed `search-narrowed-hint`.
  final String? narrowedNote;

  /// The query the results are really for when it differs from the typed
  /// one, or null. It follows [correctionPrefix] in italics, under the
  /// results, keyed `search-correction-hint`.
  final String? correction;
  final String correctionPrefix;

  /// The selection returns to the first row whenever this value changes
  /// (compared with `==`). Without one, it never resets.
  final Object? selectionResetKey;

  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  late final _focus = FocusNode(onKeyEvent: _key);
  int _active = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(SearchPanel old) {
    super.didUpdateWidget(old);
    // A new result list starts at the first row.
    if (old.selectionResetKey != widget.selectionResetKey) _active = 0;
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  List<SearchResult> get _order => [
    for (final section in widget.sections ?? const <SearchResultSection>[])
      ...section.results,
  ];

  KeyEventResult _key(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final results = _order;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowDown && results.isNotEmpty) {
      setState(() => _active = (_active + 1) % results.length);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowUp && results.isNotEmpty) {
      setState(() => _active = (_active - 1 + results.length) % results.length);
      return KeyEventResult.handled;
    }
    if ((k == LogicalKeyboardKey.enter ||
            k == LogicalKeyboardKey.numpadEnter) &&
        results.isNotEmpty) {
      widget.onPick(results[_active.clamp(0, results.length - 1)]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    final sections = widget.sections;
    final total = _order.length;
    final correction = widget.correction;
    final narrowed = widget.narrowedNote;
    final filters = widget.filters;
    Widget note(String s) => Padding(
      padding: const EdgeInsets.all(16),
      child: Text(s, style: ts(ty.ui, c.textTertiary, weight: 400)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: SearchField(
            fieldKey: widget.fieldKey,
            controller: widget.controller,
            focusNode: _focus,
            onChanged: widget.onQueryChanged,
            placeholder: widget.placeholder,
          ),
        ),
        if (filters != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: filters,
          ),
        HLine(color: c.divider),
        Expanded(
          child: sections == null
              ? note(widget.idleNote)
              : total == 0
              ? note(widget.emptyNote)
              : SearchResultsList(
                  sections: sections,
                  mobile: false,
                  active: _active.clamp(0, total - 1),
                  padding: const EdgeInsets.all(6),
                  onPick: widget.onPick,
                ),
        ),
        if (narrowed != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              narrowed,
              key: const ValueKey('search-narrowed-hint'),
              style: ts(ty.uiSmall, c.textTertiary, weight: 400),
            ),
          ),
        if (correction != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: widget.correctionPrefix),
                  TextSpan(
                    text: correction,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              key: const ValueKey('search-correction-hint'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ts(ty.uiSmall, c.textTertiary, weight: 400),
            ),
          ),
      ],
    );
  }
}
