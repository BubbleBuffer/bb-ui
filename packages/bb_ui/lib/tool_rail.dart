// Tool rail and tool toggle buttons for vertical or horizontal editor bars.

import 'package:flutter/widgets.dart';

import 'hover.dart';
import 'icons.dart';
import 'tokens.dart';
import 'tooltip.dart';

class _ToolRailScope extends InheritedWidget {
  const _ToolRailScope({required this.direction, required super.child});

  final Axis direction;

  static Axis? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ToolRailScope>()?.direction;

  @override
  bool updateShouldNotify(_ToolRailScope old) => old.direction != direction;
}

/// A vertical or horizontal strip of [ToolButton]s and optional
/// [ToolRailSeparator]s on an elevated surface.
class ToolRail extends StatelessWidget {
  const ToolRail({
    super.key,
    required this.children,
    this.direction = Axis.vertical,
    this.spacing = Space.xxs,
    this.padding = const EdgeInsets.all(Space.xs),
    this.semanticLabel,
  });

  /// The tool buttons and separators in this rail.
  final List<Widget> children;

  /// Whether buttons are stacked vertically or laid out horizontally.
  final Axis direction;

  /// Space between rail items.
  final double spacing;

  /// Padding inside the rail surface.
  final EdgeInsetsGeometry padding;

  /// Optional accessible name for the rail container.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: c.bgElevated,
          borderRadius: Radii.panel,
          border: Border.all(color: c.border),
        ),
        child: _ToolRailScope(
          direction: direction,
          child: Flex(
            direction: direction,
            mainAxisSize: MainAxisSize.min,
            spacing: spacing,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// A hairline divider between groups of [ToolButton]s inside a [ToolRail].
class ToolRailSeparator extends StatelessWidget {
  const ToolRailSeparator({super.key, this.direction});

  /// Overrides the enclosing [ToolRail]'s direction when placed standalone.
  final Axis? direction;

  @override
  Widget build(BuildContext context) {
    final axis = direction ?? _ToolRailScope.maybeOf(context) ?? Axis.vertical;
    final c = context.colors;
    return ExcludeSemantics(
      child: axis == Axis.vertical
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xxs),
              child: Container(
                width: Sizes.rule,
                height: Stroke.hair,
                color: c.border,
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xxs),
              child: Container(
                width: Stroke.hair,
                height: Sizes.rule,
                color: c.border,
              ),
            ),
    );
  }
}

/// An icon toggle button for a [ToolRail] with tooltip, optional [shortcut]
/// hint, [selected] state, and disabled state when [onPressed] is null.
class ToolButton extends StatelessWidget {
  const ToolButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.shortcut,
    this.selected = false,
    this.onPressed,
    this.size,
    this.glyph,
    this.semanticLabel,
  });

  /// The glyph shown inside the button.
  final Ico icon;

  /// Tooltip text shown on hover, focus, or long-press.
  final String tooltip;

  /// Optional keyboard shortcut hint shown next to [tooltip].
  final String? shortcut;

  /// Whether this tool is currently active.
  final bool selected;

  /// Called when tapped or activated; null disables the button.
  final VoidCallback? onPressed;

  /// Hit area size; defaults to `ControlSize.md` (pointer) or `ControlSize.xl`
  /// (touch).
  final ControlSize? size;

  /// Icon size; defaults to `IconSize.md` (pointer) or `IconSize.lg` (touch).
  final IconSize? glyph;

  /// Optional override for screen-reader label; defaults to [tooltip].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    final dim =
        (size ?? (context.touch ? ControlSize.xl : ControlSize.md)).height;
    final iconSize = glyph ?? (context.touch ? IconSize.lg : IconSize.md);
    final ink = !enabled
        ? c.textDisabled
        : selected
        ? c.accentText
        : c.iconSecondary;
    final button = Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: semanticLabel ?? tooltip,
      excludeSemantics: true,
      onTap: onPressed,
      child: Hover(
        onTap: onPressed,
        selected: selected,
        selectedColor: enabled ? c.bgSelectedBlock : c.bgHover,
        hoverColor: selected ? c.bgSelectedBlock : null,
        lift: 0,
        borderRadius: Radii.ctl,
        border: selected
            ? Border.all(color: enabled ? c.accent : c.border)
            : null,
        child: SizedBox(
          width: dim,
          height: dim,
          child: Center(
            child: Icon20(icon, size: iconSize, color: ink),
          ),
        ),
      ),
    );
    return AppTooltip(label: tooltip, shortcut: shortcut, child: button);
  }
}
