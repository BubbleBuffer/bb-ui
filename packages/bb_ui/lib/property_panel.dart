// Compact inspector layout primitives: a fixed-label property row and a
// collapsible property section.

import 'package:flutter/widgets.dart';

import 'hover.dart';
import 'icons.dart';
import 'layout.dart';
import 'lines.dart';
import 'tokens.dart';

const _stackTextScale = 1.5;

/// A compact inspector row with a fixed-width [label] on the left and one
/// ([child]) or two ([child] and [secondary]) controls beside it.
///
/// Stacks vertically when the available width is too narrow or text scaling is
/// very large so controls never clip or overflow.
class PropertyRow extends StatelessWidget {
  const PropertyRow({
    super.key,
    required this.label,
    required this.child,
    this.secondary,
    this.labelWidth = Sizes.labelColumn,
  });

  /// Row label aligned in a fixed-width column on wide panes.
  final String label;

  /// Primary control placed beside [label].
  final Widget child;

  /// Optional second control placed beside [child] with equal width.
  final Widget? secondary;

  /// Width of the label column when laid out inline.
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: ts(context.type.uiSmall, c.textSecondary, weight: Weight.regular),
    );
    final controls = secondary == null
        ? child
        : Row(
            spacing: Space.xs,
            children: [
              Expanded(child: child),
              Expanded(child: secondary!),
            ],
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack =
            constraints.maxWidth < labelWidth + Space.sm + Sizes.labelColumn ||
            MediaQuery.textScalerOf(context).scale(1) > _stackTextScale;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: Space.xxs,
            children: [labelText, controls],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: labelWidth, child: labelText),
            const Gap(Space.sm),
            Expanded(child: controls),
          ],
        );
      },
    );
  }
}

/// A titled, collapsible section for grouping [PropertyRow]s and inspector
/// controls.
class PropertySection extends StatefulWidget {
  const PropertySection({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = true,
    this.expanded,
    this.onExpandedChanged,
    this.trailing,
    this.spacing = Space.xs,
  });

  /// Section title shown in the collapsible header.
  final String title;

  /// Rows or controls displayed inside the section when expanded.
  final List<Widget> children;

  /// Initial open state when [expanded] is null.
  final bool initiallyExpanded;

  /// Controlled open state; when non-null, tapping the header only invokes
  /// [onExpandedChanged].
  final bool? expanded;

  /// Called with the next open state when the header is toggled.
  final ValueChanged<bool>? onExpandedChanged;

  /// Optional trailing action placed at the end of the header row.
  final Widget? trailing;

  /// Vertical spacing between [children].
  final double spacing;

  @override
  State<PropertySection> createState() => _PropertySectionState();
}

class _PropertySectionState extends State<PropertySection> {
  late bool _expandedState = widget.initiallyExpanded;

  bool get _isExpanded => widget.expanded ?? _expandedState;

  void _toggle() {
    final next = !_isExpanded;
    if (widget.expanded == null) {
      setState(() => _expandedState = next);
    }
    widget.onExpandedChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final open = _isExpanded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                expanded: open,
                label: widget.title,
                excludeSemantics: true,
                onTap: _toggle,
                child: Hover(
                  onTap: _toggle,
                  lift: 0,
                  borderRadius: Radii.ctl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.xs,
                    vertical: Space.xs,
                  ),
                  child: Row(
                    children: [
                      Icon20(
                        open ? Ico.chevronDown : Ico.chevronRight,
                        size: IconSize.xs,
                        color: c.iconSecondary,
                      ),
                      const Gap(Space.xs),
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ts(
                            context.type.uiSmall,
                            c.textPrimary,
                            weight: Weight.strong,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.trailing != null) ...[
              const Gap(Space.xxs),
              widget.trailing!,
            ],
          ],
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.xs,
              Space.xs,
              Space.xs,
              Space.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: widget.spacing,
              children: widget.children,
            ),
          ),
        HLine(color: c.borderSubtle),
      ],
    );
  }
}
