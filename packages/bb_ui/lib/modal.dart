// Modal frames: a centred panel over the dimmed page (desktop dialogs such
// as page history and import), a small confirm dialog, a full-screen
// scaffold with a back button (mobile screens such as trash and history),
// and a spinner for work in progress.

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'buttons.dart';
import 'hover.dart';
import 'fields.dart';
import 'icons.dart';
import 'menu.dart';
import 'routes.dart';
import 'tokens.dart';
import 'layout.dart';

/// Shows [builder] in a centred panel, [width] x [height] at most (and a
/// margin smaller than the window). A [shrink] panel is as tall as its content.
/// Escape and a tap on the barrier close it.
Future<T?> showModalPanel<T>(
  BuildContext context,
  WidgetBuilder builder, {
  double width = Widths.content,
  double height = Heights.dialog,
  bool shrink = false,
}) => Navigator.of(context).push(
  ModalPanelRoute<T>(
    builder: builder,
    width: width,
    height: height,
    shrink: shrink,
    barrier: context.colors.overlay,
    duration: Motion.of(context).fast,
  ),
);

class ModalPanelRoute<T> extends PopupRoute<T> {
  ModalPanelRoute({
    required this.builder,
    required this.width,
    required this.height,
    required this.shrink,
    required this.barrier,
    this.duration = Motion.fast,
  });
  final WidgetBuilder builder;
  final double width, height;
  final bool shrink;
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
  ) {
    // A dialog route sizes against the screen it covers.
    // ignore: bb_lints/no_window_size
    final size = MediaQuery.sizeOf(context);
    final w = (size.width - 2 * Space.xxxl).clamp(Widths.panel, width);
    final h = (size.height - 2 * Space.xxxl).clamp(Heights.dialogMin, height);
    return Center(
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).maybePop(),
        },
        child: Focus(
          autofocus: true,
          child: ConstrainedBox(
            constraints: shrink
                ? BoxConstraints(maxWidth: w, minWidth: w, maxHeight: h)
                : BoxConstraints.tight(Size(w, h)),
            child: MenuSurface(child: builder(context)),
          ),
        ),
      ),
    );
  }

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

/// Asks to confirm an action. Completes with true when confirmed.
Future<bool> showConfirm(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool danger = false,
}) async {
  final r = await showModalPanel<bool>(
    context,
    (ctx) => ConfirmBox(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      danger: danger,
      onDone: (v) => Navigator.of(ctx).pop(v),
    ),
    width: Widths.dialog,
    shrink: true,
  );
  return r ?? false;
}

class ConfirmBox extends StatelessWidget {
  const ConfirmBox({
    super.key,
    required this.title,
    this.message,
    required this.confirmLabel,
    required this.onDone,
    this.cancelLabel = 'Cancel',
    this.danger = false,
  });
  final String title, confirmLabel, cancelLabel;
  final String? message;
  final bool danger;
  final ValueChanged<bool> onDone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.xl,
        Space.xl,
        Space.xl,
        Space.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: tsDisplay(
              context.type.h3,
              c.textPrimary,
              weight: Weight.display,
            ),
          ),
          if (message != null) ...[
            const Gap(Space.xs),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: ts(ty.uiSmall, c.textSecondary, weight: Weight.regular),
            ),
          ],
          const Gap(Space.lg),
          DialogButton(
            key: const ValueKey('confirm-ok'),
            label: confirmLabel,
            color: danger ? c.inlineCodeText : c.accent,
            filled: true,
            onTap: () => onDone(true),
          ),
          const Gap(Space.sm),
          DialogButton(
            key: const ValueKey('confirm-cancel'),
            label: cancelLabel,
            onTap: () => onDone(false),
          ),
        ],
      ),
    );
  }
}

/// A full-width dialog button: [filled] in [color], or outlined.
class DialogButton extends StatelessWidget {
  const DialogButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.filled = false,
    this.height,
  });
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final bool filled;
  final double? height;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = color ?? c.accent;
    final enabled = onTap != null;
    return Hover(
      onTap: onTap,
      borderRadius: Radii.ctl,
      background: filled ? (enabled ? base : c.bgTertiary) : c.bgPrimary,
      hoverBackground: filled
          ? (base == c.accent
                ? c.accentHover
                : base.withValues(alpha: Alpha.strong))
          : c.bgHover,
      pressedBackground: filled ? base : c.bgPressed,
      border: filled ? null : Border.all(color: c.thread),
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: height ?? context.metrics.control.height,
        ),
        child: Center(
          child: Text(
            label,
            style: ts(
              context.type.ui,
              !enabled
                  ? c.textDisabled
                  : filled
                  ? (base == c.accent || c.dark ? c.onAccent : c.bgPrimary)
                  : c.textPrimary,
              weight: filled ? Weight.bold : Weight.semibold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Pushes a full-screen page (mobile).
Future<T?> pushScreen<T>(
  BuildContext context,
  WidgetBuilder builder, {
  String? name,
}) => Navigator.of(context).push<T>(
  pageRoute<T>(
    builder,
    motion: Motion.of(context),
    slide: true,
    settings: RouteSettings(name: name),
  ),
);

/// A full-screen page: a 44 px bar with back, [title] and [actions], then
/// [body].
class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
  });
  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mq = MediaQuery.of(context);
    return ColoredBox(
      color: c.bgPrimary,
      child: Padding(
        padding: EdgeInsets.only(
          top: mq.padding.top,
          bottom: mq.padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: Layout.topbarHeight,
              child: Row(
                children: [
                  const Gap(Space.xxs),
                  IconBtn(
                    Ico.chevronLeft,
                    key: const ValueKey('screen-back'),
                    onTap: () => Navigator.of(context).maybePop(),
                    size: ControlSize.xl,
                    glyph: IconSize.xl,
                    color: c.iconPrimary,
                    semanticLabel: 'Back',
                  ),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ts(
                        context.type.ui,
                        c.textPrimary,
                        weight: Weight.semibold,
                      ),
                    ),
                  ),
                  ...actions,
                  const Gap(Space.sm),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// A small rotating arc (work in progress).
class Spinner extends StatefulWidget {
  const Spinner({super.key, this.size = IconSize.sm, this.color});
  final IconSize size;
  final Color? color;

  @override
  State<Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<Spinner> with SingleTickerProviderStateMixin {
  late final _ctl = AnimationController(vsync: this, duration: Motion.spin)
    ..repeat();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.size.px,
    height: widget.size.px,
    child: AnimatedBuilder(
      animation: _ctl,
      builder: (context, _) => CustomPaint(
        painter: _ArcPainter(
          _ctl.value,
          widget.color ?? context.colors.iconSecondary,
        ),
      ),
    ),
  );
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.t, this.color);
  final double t;
  final Color color;

  /// The arc's sweep in half turns.
  static const _sweep = 1.4;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = Stroke.bold
      ..strokeCap = StrokeCap.round;
    final r = (Offset.zero & size).deflate(Stroke.bold);
    canvas.drawArc(r, t * 2 * math.pi, math.pi * _sweep, false, p);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.t != t || old.color != color;
}

/// A bordered single-line input box (path fields in dialogs).
class InputBox extends StatelessWidget {
  const InputBox({super.key, required this.child, this.height});
  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return FieldFrame(
      height: height ?? context.metrics.field.height,
      child: child,
    );
  }
}

/// A tappable surface row used by lists in panels (kept for symmetry with
/// MenuItem, but without fixed height).
class PanelRow extends StatelessWidget {
  const PanelRow({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.padding,
  });
  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Hover(
    onTap: onTap,
    selected: selected,
    selectedColor: context.colors.bgPressed,
    borderRadius: Radii.ctl,
    padding:
        padding ?? EdgeInsets.symmetric(horizontal: context.metrics.insetX),
    child: child,
  );
}
