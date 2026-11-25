// One row of a hierarchical tree list with depth indent, expand/collapse
// chevron, leading icon/widget, selection seam, hover-revealed actions,
// modifier-aware press, secondary tap and inline rename.

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'hover.dart';
import 'icons.dart';
import 'layout.dart';
import 'selection.dart';
import 'tokens.dart';

/// The modifier keys held when a [TreeRow] was pressed, so the app can do
/// range and multi selection.
class TreeRowPress {
  const TreeRowPress({this.shift = false, this.toggle = false});

  /// Shift was held (extend a range).
  final bool shift;

  /// Ctrl (or Cmd) was held (toggle one item).
  final bool toggle;
}

/// A single row in a hierarchical tree list.
///
/// Indents by [depth], optionally shows an expand/collapse chevron when
/// [expanded] is non-null, and reveals [trailing] actions on hover, keyboard
/// focus, touch density, or when [trailingAlwaysVisible] is true.
///
/// When [onRename] is set, a double-click on the label or F2 while the row is
/// focused swaps the label for a text field. [TreeRowState.startRename] starts
/// the same edit from code (a context menu item, say) through a
/// `GlobalKey<TreeRowState>`.
class TreeRow extends StatefulWidget {
  const TreeRow({
    super.key,
    required this.label,
    this.depth = 0,
    this.expanded,
    this.onToggleExpanded,
    this.icon,
    this.leading,
    this.selected = false,
    this.onPressed,
    this.onSecondaryTap,
    this.onRename,
    this.trailing = const [],
    this.trailingAlwaysVisible = false,
    this.chevronKey,
    this.semanticLabel,
  });

  /// Primary text label for the row.
  final String label;

  /// Nesting depth (`0` for top-level rows).
  final int depth;

  /// Whether this node's children are expanded; `null` hides the chevron
  /// while keeping its alignment column.
  final bool? expanded;

  /// Called when the expand/collapse chevron is tapped or toggled via Left/Right
  /// arrow keys; does not trigger [onPressed].
  final VoidCallback? onToggleExpanded;

  /// Optional leading [Ico] glyph (ignored when [leading] is supplied).
  final Ico? icon;

  /// Optional custom leading widget placed before [label].
  final Widget? leading;

  /// Whether the row is currently selected.
  final bool selected;

  /// Called when the row body is tapped or activated, with the Shift and
  /// Ctrl/Cmd state at that moment.
  final ValueChanged<TreeRowPress>? onPressed;

  /// Called with the global pointer position on a right-click, or a
  /// long-press on touch, so the app can open a context menu there. The row
  /// opens no menu itself and does not fire [onPressed].
  final ValueChanged<Offset>? onSecondaryTap;

  /// Called with the new label when an inline rename commits (Enter or focus
  /// loss). The text is trimmed; empty or unchanged text does not call it.
  /// Renaming is available only when this is non-null.
  final ValueChanged<String>? onRename;

  /// Action widgets shown at the end of the row on hover, focus, or when
  /// [trailingAlwaysVisible] is true.
  final List<Widget> trailing;

  /// Forces [trailing] actions to stay visible even when not hovered.
  final bool trailingAlwaysVisible;

  /// Optional key attached to the expand/collapse chevron button.
  final Key? chevronKey;

  /// Accessible label override; defaults to [label].
  final String? semanticLabel;

  @override
  State<TreeRow> createState() => TreeRowState();
}

/// State of a [TreeRow]; its [startRename] lets the app begin a rename.
class TreeRowState extends State<TreeRow> {
  bool _hovered = false;
  bool _focused = false;
  bool _renaming = false;
  bool _swallowTap = false;
  Duration? _lastDownAt;
  Offset? _lastDownPos;
  final TextEditingController _editor = TextEditingController();
  late final FocusNode _editFocus = FocusNode(onKeyEvent: _handleEditKey);

  @override
  void initState() {
    super.initState();
    _editFocus.addListener(_onEditFocus);
  }

  @override
  void dispose() {
    _editFocus.removeListener(_onEditFocus);
    _editFocus.dispose();
    _editor.dispose();
    super.dispose();
  }

  /// Turns the label into a text field with its text selected. Does nothing
  /// without [TreeRow.onRename].
  void startRename() {
    if (widget.onRename == null || _renaming) return;
    _editor.value = TextEditingValue(
      text: widget.label,
      selection: TextSelection(
        baseOffset: 0,
        extentOffset: widget.label.length,
      ),
    );
    setState(() => _renaming = true);
  }

  void _endRename({required bool commit}) {
    if (!_renaming) return;
    final text = _editor.text.trim();
    setState(() => _renaming = false);
    if (commit && text.isNotEmpty && text != widget.label) {
      widget.onRename?.call(text);
    }
  }

  void _onEditFocus() {
    if (_renaming && !_editFocus.hasFocus) _endRename(commit: true);
  }

  KeyEventResult _handleEditKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _endRename(commit: false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _press() {
    if (_renaming) return;
    if (_swallowTap) {
      _swallowTap = false;
      return;
    }
    final kb = HardwareKeyboard.instance;
    widget.onPressed?.call(
      TreeRowPress(
        shift: kb.isShiftPressed,
        toggle: kb.isControlPressed || kb.isMetaPressed,
      ),
    );
  }

  // A second press on the label inside the double-tap window starts the
  // rename; its tap-up does not press the row a second time.
  void _labelDown(PointerDownEvent e) {
    if (widget.onRename == null || _renaming) return;
    final last = _lastDownAt;
    final lastPos = _lastDownPos;
    _lastDownAt = e.timeStamp;
    _lastDownPos = e.position;
    if (last != null &&
        lastPos != null &&
        e.timeStamp - last <= kDoubleTapTimeout &&
        (e.position - lastPos).distance <= kDoubleTapSlop) {
      _lastDownAt = null;
      _swallowTap = widget.onPressed != null;
      startRename();
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _renaming) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.f2 && widget.onRename != null) {
      startRename();
      return KeyEventResult.handled;
    }
    final exp = widget.expanded;
    if (exp == null || widget.onToggleExpanded == null) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight && !exp) {
      widget.onToggleExpanded!();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft && exp) {
      widget.onToggleExpanded!();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    final m = context.metrics;
    final showTrailing =
        widget.trailing.isNotEmpty &&
        (widget.trailingAlwaysVisible || _hovered || _focused || context.touch);
    final chevronDim = ControlSize.xs.height;
    final labelStyle = ts(
      ty.uiSmall,
      c.textPrimary,
      weight: widget.selected ? Weight.strong : Weight.regular,
    );

    final Widget? lead =
        widget.leading ??
        (widget.icon == null
            ? null
            : Icon20(
                widget.icon!,
                size: m.iconSmall,
                color: widget.selected ? c.accentText : c.iconSecondary,
              ));

    final Widget chevronSlot;
    if (widget.expanded == null) {
      chevronSlot = SizedBox(width: chevronDim, height: chevronDim);
    } else {
      final isExpanded = widget.expanded!;
      chevronSlot = Semantics(
        button: true,
        label: '${isExpanded ? 'Collapse' : 'Expand'} ${widget.label}',
        excludeSemantics: true,
        onTap: widget.onToggleExpanded,
        child: Hover(
          key: widget.chevronKey,
          onTap: widget.onToggleExpanded,
          lift: 0,
          borderRadius: Radii.ctl,
          child: SizedBox(
            width: chevronDim,
            height: chevronDim,
            child: Center(
              child: Icon20(
                isExpanded ? Ico.chevronDown : Ico.chevronRight,
                size: IconSize.xs,
                color: c.iconSecondary,
              ),
            ),
          ),
        ),
      );
    }

    final Widget labelWidget = _renaming
        ? EditableText(
            controller: _editor,
            focusNode: _editFocus,
            autofocus: true,
            style: labelStyle,
            cursorColor: c.textPrimary,
            backgroundCursorColor: c.textTertiary,
            selectionColor: c.textSelection,
            cursorWidth: Stroke.regular,
            selectionControls: noteSelectionControls,
            autocorrect: false,
            enableSuggestions: false,
            maxLines: 1,
            onSubmitted: (_) => _endRename(commit: true),
          )
        : Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _labelDown,
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          );

    final secondary = widget.onSecondaryTap;
    return Semantics(
      selected: widget.selected,
      expanded: widget.expanded,
      enabled: widget.onPressed != null,
      label: widget.semanticLabel ?? widget.label,
      child: Focus(
        skipTraversal: true,
        onFocusChange: (value) => setState(() => _focused = value),
        onKeyEvent: _handleKey,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onSecondaryTapUp: secondary == null
                ? null
                : (d) => secondary(d.globalPosition),
            onLongPressStart: secondary == null
                ? null
                : (d) => secondary(d.globalPosition),
            child: Stack(
              children: [
                Hover(
                  onTap: widget.onPressed == null ? null : _press,
                  selected: widget.selected,
                  selectedColor: c.bgSelectedBlock,
                  lift: 0,
                  borderRadius: Radii.ctl,
                  padding: EdgeInsets.only(
                    left: Space.xs + widget.depth * Space.lg,
                    right: Space.xs,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: m.row.height),
                    child: Row(
                      children: [
                        chevronSlot,
                        if (lead != null) ...[const Gap(Space.hair), lead],
                        const Gap(Space.xs),
                        Expanded(child: labelWidget),
                        if (showTrailing) ...[
                          const Gap(Space.xs),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: Space.hair,
                            children: widget.trailing,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (widget.selected)
                  Positioned(
                    left: 0,
                    top: Space.xxs,
                    bottom: Space.xxs,
                    child: IgnorePointer(
                      child: Container(
                        width: Stroke.seam,
                        decoration: BoxDecoration(
                          color: c.accent,
                          borderRadius: Radii.pill,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
