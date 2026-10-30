// Chrome that hangs from the top edge of a full-screen surface: a small tab at
// rest and a strip of grouped controls when open.

import 'package:flutter/widgets.dart';

import '../hover.dart';
import '../icons.dart';
import '../lines.dart';
import '../tokens.dart';

/// The corners of the tab and the strip: square where they meet the edge,
/// rounded where they hang free.
const _hanging = BorderRadius.only(
  bottomLeft: Radius.circular(12),
  bottomRight: Radius.circular(12),
);

BoxDecoration _surface(AppColors c) => BoxDecoration(
  color: c.bgElevated,
  borderRadius: _hanging,
  border: Border.all(color: c.border),
  boxShadow: c.seam,
);

/// The resting tab: a status [mark], the [label] (a name), a monospace
/// [value] (a latency) and a chevron. It is a button that opens the strip.
class EdgeTab extends StatelessWidget {
  const EdgeTab({
    super.key,
    required this.label,
    this.value,
    this.mark,
    this.opened = false,
    this.onTap,
  });
  final String label;
  final String? value;

  /// The colour of the dot before the label; no dot when null.
  final Color? mark;

  /// Whether the strip is open; turns the chevron.
  final bool opened;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: value == null ? label : '$label, $value',
      expanded: opened,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: _surface(c),
        child: Hover(
          onTap: onTap,
          borderRadius: _hanging,
          lift: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            height: 28,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (mark != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: mark,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: ts(context.type.uiSmall, c.textSecondary, weight: 600),
                ),
                if (value != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    value!,
                    style: ts(
                      const TypeSpec(11, 14, 400),
                      c.textPrimary,
                      mono: true,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Icon20(
                  opened ? Ico.chevronUp : Ico.chevronDown,
                  size: 16,
                  color: c.iconSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The open strip: [groups] side by side with a seam between each. Put a
/// connection group first and the leave action alone in the last group.
class EdgeStrip extends StatelessWidget {
  const EdgeStrip({super.key, required this.groups});
  final List<Widget> groups;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: _surface(c),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < groups.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: VLine(height: 22),
                ),
              groups[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// A strip control: an [icon] with an optional [label], and a chevron when it
/// opens a popover ([menu]). [selected] marks the one whose popover is open
/// or whose state is on; [signal] draws the label in the accent colour for the
/// live state ("Captured").
class EdgeStripButton extends StatelessWidget {
  const EdgeStripButton({
    super.key,
    required this.icon,
    this.label,
    this.semanticLabel,
    this.selected = false,
    this.signal = false,
    this.menu = false,
    this.onTap,
  });
  final Ico icon;
  final String? label;

  /// The accessible name when there is no [label].
  final String? semanticLabel;
  final bool selected;
  final bool signal;
  final bool menu;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = signal ? c.accentText : c.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label: label ?? semanticLabel,
      excludeSemantics: true,
      child: Hover(
        onTap: onTap,
        selected: selected,
        selectedColor: c.bgPressed,
        radius: Radii.md,
        padding: EdgeInsets.symmetric(horizontal: label == null ? 6 : 10),
        child: SizedBox(
          height: 32,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon20(
                icon,
                size: 18,
                color: signal ? c.accentText : c.iconSecondary,
              ),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: ts(context.type.uiSmall, ink, weight: 600),
                ),
              ],
              if (menu) ...[
                const SizedBox(width: 4),
                Icon20(
                  selected ? Ico.chevronUp : Ico.chevronDown,
                  size: 14,
                  color: c.iconTertiary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
