// Menus: the elevated surface, header, item and separator rows, and a
// popover route that places a menu next to an anchor rectangle (desktop).
// On mobile the same content goes into a bottom sheet (sheet.dart).

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'hover.dart';
import 'icons.dart';
import 'lines.dart';
import 'tokens.dart';
import 'layout.dart';

/// Elevated menu surface: `bgElevated`, `shadowMenu`, radius.
class MenuSurface extends StatelessWidget {
  const MenuSurface({
    super.key,
    required this.child,
    this.radius,
    this.padding,
    this.width,
  });
  final Widget child;
  final double? radius;
  final EdgeInsetsGeometry? padding;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: c.bgElevated,
        borderRadius: radius == null
            ? context.shape.panel
            : BorderRadius.circular(radius!),
        boxShadow: c.seamHover,
      ),
      child: ClipRRect(
        borderRadius: radius == null
            ? context.shape.panel
            : BorderRadius.circular(radius!),
        child: child,
      ),
    );
  }
}

/// The small grey label at the top of a menu section.
class MenuHeader extends StatelessWidget {
  const MenuHeader(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.sm, Space.xs, Space.sm, Space.xs),
    child: Text(
      text,
      style: ts(context.type.uiSmall, context.colors.textTertiary),
    ),
  );
}

/// One menu row: icon (an [Ico] or any [leading] widget), label, optional
/// trailing widget. [danger] draws it in the destructive colour.
class MenuItem extends StatelessWidget {
  const MenuItem({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.leading,
    this.trailing,
    this.selected = false,
    this.danger = false,
    this.onHover,
    this.firstLine = false,
  });
  final String label;

  /// [label] stands in for a missing page title (the page's first line):
  /// tertiary italics.
  final bool firstLine;
  final VoidCallback? onTap;
  final Ico? icon;
  final Widget? leading;
  final Widget? trailing;
  final bool selected;
  final bool danger;
  final VoidCallback? onHover;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    final m = context.metrics;
    final color = danger ? c.inlineCodeText : null;
    final lead =
        leading ??
        (icon == null
            ? null
            : Icon20(icon!, size: m.icon, color: color ?? c.iconPrimary));
    Widget row = Hover(
      onTap: onTap,
      selected: selected,
      radius: Radii.md,
      padding: const EdgeInsets.symmetric(horizontal: Space.sm),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: m.row.height),
        child: Row(
          children: [
            if (lead != null) ...[lead, Gap(m.iconGap)],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: firstLine
                    ? ts(
                        ty.item,
                        c.textTertiary,
                        weight: Weight.regular,
                      ).copyWith(fontStyle: FontStyle.italic)
                    : ts(
                        ty.item,
                        color ?? c.textPrimary,
                        weight: Weight.regular,
                      ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
    if (onHover != null) {
      row = MouseRegion(onEnter: (_) => onHover!(), child: row);
    }
    return row;
  }
}

class MenuSeparator extends StatelessWidget {
  const MenuSeparator({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Space.xs),
    child: HLine(color: context.colors.border),
  );
}

/// A menu of [MenuItem]s and separators on a [MenuSurface].
class MenuList extends StatelessWidget {
  const MenuList({
    super.key,
    required this.children,
    this.width = Widths.menu,
    this.header,
  });
  final List<Widget> children;
  final double width;
  final String? header;

  @override
  Widget build(BuildContext context) => MenuSurface(
    width: width,
    padding: const EdgeInsets.all(Space.xs),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [if (header != null) MenuHeader(header!), ...children],
    ),
  );
}

/// A popup with a transparent barrier that shows [builder]'s menu below
/// (or above, when there is no room) the global rectangle [anchor].
class PopoverRoute<T> extends PopupRoute<T> {
  PopoverRoute({
    required this.anchor,
    required this.builder,
    this.duration = Motion.fast,
  });
  final Rect anchor;
  final WidgetBuilder builder;
  final Duration duration;

  @override
  Color? get barrierColor => null;
  @override
  bool get barrierDismissible => true;
  @override
  String? get barrierLabel => 'Close';
  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => CustomSingleChildLayout(
    delegate: _PopoverLayout(anchor),
    child: builder(context),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MediaQuery.disableAnimationsOf(context)
      ? child
      : FadeTransition(opacity: animation, child: child);
}

class _PopoverLayout extends SingleChildLayoutDelegate {
  _PopoverLayout(this.anchor);
  final Rect anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size child) {
    const m = Space.sm;
    final x = math.max(m, math.min(anchor.left, size.width - child.width - m));
    final below = anchor.bottom + Space.xxs;
    final y = below + child.height <= size.height - m
        ? below
        : math.max(m, anchor.top - Space.xxs - child.height);
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_PopoverLayout old) => old.anchor != anchor;
}

/// Shows [builder] as a popover under [anchor]; completes with what it pops.
Future<T?> showPopover<T>(
  BuildContext context,
  Rect anchor,
  WidgetBuilder builder,
) => Navigator.of(context).push(
  PopoverRoute<T>(
    anchor: anchor,
    builder: builder,
    duration: Motion.of(context).fast,
  ),
);

/// The global rectangle of [context]'s render box (to anchor a popover).
Rect globalRectOf(BuildContext context) {
  final box = context.findRenderObject() as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}
