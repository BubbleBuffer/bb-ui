// Bottom sheets (mobile): a route that slides up over a dimmed barrier and a
// surface with a grab handle that closes when dragged down.

import 'package:flutter/widgets.dart';

import 'hover.dart';
import 'icons.dart';
import 'tokens.dart';
import 'layout.dart';

// Dragging a sheet: how far it follows the finger, and the distance or
// downward speed (logical px per second) that dismisses it.
const _maxDrag = 600.0, _dismissDrag = 120.0, _dismissVelocity = 700.0;

class SheetRoute<T> extends PopupRoute<T> {
  SheetRoute({
    required this.builder,
    required this.barrier,
    this.duration = Motion.sheet,
  });
  final WidgetBuilder builder;
  final Color barrier;
  final Duration duration;

  @override
  Color? get barrierColor => barrier;
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
  ) => Align(alignment: Alignment.bottomCenter, child: builder(context));

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final t = CurvedAnimation(
      parent: animation,
      curve: Motion.easing,
      reverseCurve: Motion.easing.flipped,
    );
    return SlideTransition(
      position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(t),
      child: child,
    );
  }
}

/// Shows [builder] in a bottom sheet; completes with what it pops.
Future<T?> showSheet<T>(BuildContext context, WidgetBuilder builder) =>
    Navigator.of(context).push(
      SheetRoute<T>(
        builder: builder,
        barrier: context.colors.overlay,
        duration: Motion.of(context).sheet,
      ),
    );

/// The sheet's surface: rounded top, grab handle, drag down to close.
class SheetSurface extends StatefulWidget {
  const SheetSurface({super.key, required this.children});
  final List<Widget> children;

  @override
  State<SheetSurface> createState() => _SheetSurfaceState();
}

class _SheetSurfaceState extends State<SheetSurface> {
  double _drag = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // A bottom sheet sizes against the screen it rises from.
    // ignore: bb_lints/no_window_size
    final screen = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    return Transform.translate(
      offset: Offset(0, _drag),
      child: GestureDetector(
        onVerticalDragUpdate: (d) =>
            setState(() => _drag = (_drag + d.delta.dy).clamp(0, _maxDrag)),
        onVerticalDragEnd: (d) {
          if (_drag > _dismissDrag ||
              d.velocity.pixelsPerSecond.dy > _dismissVelocity) {
            Navigator.of(context).pop();
          } else {
            setState(() => _drag = 0);
          }
        },
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: screen.height * Layout.sheetHeight,
          ),
          decoration: BoxDecoration(
            color: c.bgElevated,
            borderRadius: context.shape.panel,
            boxShadow: c.seamHover,
          ),
          padding: EdgeInsets.only(bottom: safe.bottom + Space.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Gap(Space.sm),
              Center(
                child: Container(
                  width: Sizes.grabWidth,
                  height: Sizes.grabHeight,
                  decoration: BoxDecoration(
                    color: c.borderStrong,
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                ),
              ),
              const Gap(Space.md),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.children,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The grey label above a group of sheet rows.
class SheetHeader extends StatelessWidget {
  const SheetHeader(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Layout.gutter,
      Space.xxs,
      Layout.gutter,
      Space.sm,
    ),
    child: Text(
      text,
      style: ts(context.type.uiSmall, context.colors.textTertiary),
    ),
  );
}

/// One 48 px sheet row: icon, label, a check when [selected].
class SheetItem extends StatelessWidget {
  const SheetItem({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.leading,
    this.selected = false,
    this.danger = false,
  });
  final String label;
  final VoidCallback onTap;
  final Ico? icon;
  final Widget? leading;
  final bool selected;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = danger ? c.inlineCodeText : null;
    return Hover(
      onTap: onTap,
      borderRadius: context.shape.ctl,
      selected: selected,
      padding: const EdgeInsets.symmetric(horizontal: Layout.gutter),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: ControlSize.xxl.height),
        child: Row(
          children: [
            leading ??
                (icon == null
                    ? SizedBox(width: IconSize.xl.px)
                    : Icon20(
                        icon!,
                        size: IconSize.xl,
                        color: color ?? c.iconPrimary,
                      )),
            const Gap(Space.lg),
            Expanded(
              child: Text(
                label,
                style: ts(context.type.body, color ?? c.textPrimary),
              ),
            ),
            if (selected)
              Icon20(Ico.check, size: IconSize.md, color: c.accentText),
          ],
        ),
      ),
    );
  }
}
