// The command palette panel: a query field over a grouped list of commands,
// fuzzy-filtered as you type. Up and Down move the selection and stop at the
// ends, Enter runs the selected command, Escape closes, Tab stays in the
// field. A disabled command is listed and can be selected, but Enter and a
// tap do not run it. The host owns the commands and what running one does;
// [showCommandPalette] puts the panel over the page and restores focus.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons.dart';
import '../fields.dart';
import '../icons.dart';
import '../lines.dart';
import '../search/search_result.dart';
import '../search/search_result_widgets.dart';
import '../tokens.dart';
import 'fuzzy.dart';
import 'palette_command.dart';

/// The row height of a command, the group header's and the query field's.
class PaletteMetrics {
  const PaletteMetrics._();
  static double row(bool mobile) => mobile ? 44 : 36;
  static const header = 30.0;
  static double field(bool mobile) => mobile ? 52 : 48;
  static const listPadding = EdgeInsets.fromLTRB(6, 4, 6, 8);
}

class _Item {
  const _Item.header(this.header) : command = null, marks = const [], row = -1;
  const _Item.command(this.command, this.marks, this.row) : header = null;
  final String? header;
  final PaletteCommand? command;
  final List<TextRange> marks;

  /// The command's place among the commands drawn (not counting headers).
  final int row;
}

typedef _Hit = (int score, int order, PaletteCommand command, List<TextRange>);

/// The commands that match [query], grouped. Ungrouped commands come first,
/// then groups in the order they first appear; within a group the better
/// match comes first, and equal matches keep the host's order.
List<_Item> _filter(List<PaletteCommand> commands, String query) {
  final hits = <_Hit>[];
  for (var i = 0; i < commands.length; i++) {
    final command = commands[i];
    var match = fuzzyMatch(query, command.title);
    if (match == null && command.subtitle.isNotEmpty) {
      final sub = fuzzyMatch(query, command.subtitle);
      // A hit in the subtitle ranks below any in the title, and marks nothing.
      if (sub != null) match = FuzzyMatch(sub.score - 5000, const []);
    }
    if (match != null) hits.add((match.score, i, command, match.ranges));
  }
  final groups = <String?>[null];
  for (final command in commands) {
    if (!groups.contains(command.group)) groups.add(command.group);
  }
  final out = <_Item>[];
  var row = 0;
  for (final group in groups) {
    final inGroup = [
      for (final hit in hits)
        if (hit.$3.group == group) hit,
    ]..sort((a, b) => a.$1 != b.$1 ? b.$1.compareTo(a.$1) : a.$2 - b.$2);
    if (inGroup.isEmpty) continue;
    if (group != null) out.add(_Item.header(group));
    for (final hit in inGroup) {
      out.add(_Item.command(hit.$3, hit.$4, row++));
    }
  }
  return out;
}

class CommandPalette extends StatefulWidget {
  const CommandPalette({
    super.key,
    required this.commands,
    required this.onRun,
    required this.onClose,
    this.initialQuery = '',
    this.placeholder = 'Search commands…',
    this.emptyNote = 'No matching commands',
    this.fieldKey,
    this.autofocus = true,
  });

  /// The commands to list, in the host's order.
  final List<PaletteCommand> commands;

  /// Called with the command the user ran, by Enter or a tap. Never called
  /// for a disabled command.
  final ValueChanged<PaletteCommand> onRun;

  /// Called when the user asks to close: Escape, or Cancel on a phone.
  final VoidCallback onClose;

  final String initialQuery;
  final String placeholder;

  /// Shown instead of the list when nothing matches.
  final String emptyNote;

  /// The query field's key.
  final Key? fieldKey;

  /// Whether the field takes focus when the palette opens.
  final bool autofocus;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  late final _focus = FocusNode(onKeyEvent: _key);
  final _scroll = ScrollController();
  late List<_Item> _items = _filter(widget.commands, widget.initialQuery);
  int _active = 0;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(CommandPalette old) {
    super.didUpdateWidget(old);
    if (old.commands != widget.commands) {
      _items = _filter(widget.commands, _controller.text);
      _active = _clamp(_active);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_focusChanged);
    _focus.dispose();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _focusChanged() => setState(() {});

  List<PaletteCommand> get _rows => [
    for (final item in _items)
      if (item.command != null) item.command!,
  ];

  int _clamp(int i) {
    final n = _rows.length;
    return n == 0 ? 0 : i.clamp(0, n - 1);
  }

  void _query(String text) => setState(() {
    _items = _filter(widget.commands, text);
    _active = 0;
    if (_scroll.hasClients) _scroll.jumpTo(0);
  });

  void _run(PaletteCommand command) {
    if (command.enabled) widget.onRun(command);
  }

  KeyEventResult _key(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final k = e.logicalKey;
    final rows = _rows;
    if (k == LogicalKeyboardKey.escape) {
      widget.onClose();
      return KeyEventResult.handled;
    }
    // The field is the only stop.
    if (k == LogicalKeyboardKey.tab) return KeyEventResult.handled;
    if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.arrowUp) {
      if (rows.isNotEmpty) {
        final step = k == LogicalKeyboardKey.arrowDown ? 1 : -1;
        setState(() => _active = _clamp(_active + step));
        _reveal();
      }
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      if (rows.isNotEmpty) _run(rows[_clamp(_active)]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Scrolls the selected row into view.
  void _reveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final m = context.mobile;
      const pad = PaletteMetrics.listPadding;
      var top = pad.top;
      var at = -1;
      for (final item in _items) {
        if (item.command == null) {
          top += PaletteMetrics.header;
          continue;
        }
        if (++at == _active) break;
        top += PaletteMetrics.row(m);
      }
      final bottom = top + PaletteMetrics.row(m);
      final pos = _scroll.position;
      if (top < pos.pixels) {
        pos.jumpTo(top - pad.top);
      } else if (bottom > pos.pixels + pos.viewportDimension) {
        pos.jumpTo(bottom + pad.bottom - pos.viewportDimension);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    final m = context.mobile;
    final active = _clamp(_active);
    final Widget body;
    if (_items.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          widget.emptyNote,
          key: const ValueKey('palette-empty'),
          style: ts(ty.ui, c.textTertiary, weight: 400),
        ),
      );
    } else {
      body = ListView.builder(
        controller: _scroll,
        shrinkWrap: !m,
        padding: PaletteMetrics.listPadding,
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final item = _items[i];
          final command = item.command;
          if (command == null) {
            return SizedBox(
              height: PaletteMetrics.header,
              child: SearchGroupHeader(
                SearchResultSection(
                  id: item.header!,
                  label: item.header!,
                  results: const [],
                ),
                key: ValueKey('palette-group-${item.header}'),
              ),
            );
          }
          final at = item.row;
          return _PaletteRow(
            key: command.rowKey ?? ValueKey('palette-row-${command.id}'),
            command: command,
            marks: item.marks,
            active: at == active,
            onHover: () {
              if (_active != at) setState(() => _active = at);
            },
            onTap: () {
              setState(() => _active = at);
              _run(command);
            },
          );
        },
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bgElevated,
        border: m ? null : Border.all(color: c.borderStrong),
        borderRadius: m ? null : Radii.panel,
        boxShadow: m ? null : c.seamHover,
      ),
      child: ClipRRect(
        borderRadius: m ? BorderRadius.zero : Radii.panel,
        child: Column(
          mainAxisSize: m ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: PaletteMetrics.field(m),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      left: m ? 16 : 14,
                      right: m ? 4 : 14,
                    ),
                    child: Row(
                      children: [
                        Icon20(
                          Ico.search,
                          size: m ? 20 : 16,
                          color: c.iconTertiary,
                        ),
                        SizedBox(width: m ? 12 : 10),
                        Expanded(
                          child: PlainField(
                            key: widget.fieldKey,
                            controller: _controller,
                            focusNode: _focus,
                            style: ts(ty.body, c.textPrimary, weight: 400),
                            placeholder: widget.placeholder,
                            onChanged: _query,
                          ),
                        ),
                        if (m)
                          TextBtn(
                            'Cancel',
                            key: const ValueKey('palette-cancel'),
                            height: 44,
                            onTap: widget.onClose,
                          )
                        else
                          const Keycap('Esc'),
                      ],
                    ),
                  ),
                  if (_focus.hasFocus)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 2,
                      child: ColoredBox(
                        key: const ValueKey('palette-field-focus'),
                        color: c.focus,
                      ),
                    ),
                ],
              ),
            ),
            HLine(color: c.divider),
            if (m) Expanded(child: body) else Flexible(child: body),
          ],
        ),
      ),
    );
  }
}

/// A small key label in a box: a shortcut such as "Ctrl+N", or "Esc". A
/// [raised] one is a single key of a chord: a filled chip with a heavier
/// bottom edge, as in `KeyChord`.
class Keycap extends StatelessWidget {
  const Keycap(this.label, {super.key, this.color, this.raised = false});
  final String label;
  final Color? color;
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = color ?? (raised ? c.textPrimary : c.textTertiary);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: raised ? c.bgTertiary : null,
        border: Border.all(color: raised ? c.thread : c.border),
        borderRadius: BorderRadius.circular(Radii.sm),
        boxShadow: raised
            ? [BoxShadow(color: c.threadStrong, offset: const Offset(0, 1.5))]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          maxLines: 1,
          style: ts(context.type.uiSmall, fg, weight: 400, mono: true),
        ),
      ),
    );
  }
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({
    super.key,
    required this.command,
    required this.marks,
    required this.active,
    required this.onHover,
    required this.onTap,
  });
  final PaletteCommand command;
  final List<TextRange> marks;
  final bool active;
  final VoidCallback onHover, onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    final m = context.mobile;
    final enabled = command.enabled;
    final icon = command.icon;
    final reason = command.disabledReason;
    final shortcut = command.shortcutLabel;
    final Widget? trailing = !enabled
        ? (reason == null || reason.isEmpty
              ? null
              : Text(
                  reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(ty.uiSmall, c.textTertiary, weight: 400),
                ))
        : (shortcut == null || shortcut.isEmpty ? null : Keycap(shortcut));
    return Semantics(
      button: true,
      enabled: enabled,
      selected: active,
      label: command.title,
      excludeSemantics: true,
      onTap: enabled ? onTap : null,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onHover: (_) => onHover(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: PaletteMetrics.row(m),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: active ? c.bgHover : null,
                borderRadius: Radii.ctl,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (active)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 2,
                      child: ColoredBox(
                        key: const ValueKey('palette-active-bar'),
                        color: c.threadStrong,
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: m ? 12 : 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: icon == null
                              ? null
                              : Icon20(
                                  icon,
                                  size: m ? 20 : 16,
                                  color: enabled
                                      ? c.iconSecondary
                                      : c.iconTertiary,
                                ),
                        ),
                        SizedBox(width: m ? 12 : 10),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: HighlightedText(
                                  command.title,
                                  highlights: marks,
                                  style: ts(
                                    m ? ty.body : ty.ui,
                                    enabled ? c.textPrimary : c.textDisabled,
                                    weight: 400,
                                  ),
                                ),
                              ),
                              if (command.subtitle.isNotEmpty) ...[
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    command.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: ts(
                                      ty.uiSmall,
                                      c.textTertiary,
                                      weight: 400,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: 10),
                          Flexible(flex: 0, child: trailing),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
