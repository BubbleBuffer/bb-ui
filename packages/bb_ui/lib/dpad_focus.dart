// D-pad (TV remote) focus: a heavy ring for the focused control and a scope
// that maps arrows, OK and Back to focus movement, activation and a callback.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// Stroke width of the [DpadFocus] ring, in logical pixels.
const double kDpadRingWidth = 4;

/// Gap between a [DpadFocus] child and its ring, in logical pixels.
const double kDpadRingGap = 3;

/// Wraps [child] as a focus target and draws a thick, high-contrast ring with
/// a gap around it while it has primary focus through keyboard or D-pad
/// traversal. Pointer focus draws no ring.
///
/// The ring is drawn in the ink colour over a [AppColors.focus] halo, so it
/// reads on light and dark surfaces. A heavier label weight, if wanted, is the
/// child's business.
class DpadFocus extends StatefulWidget {
  const DpadFocus({
    super.key,
    required this.child,
    this.onActivate,
    this.autofocus = false,
    this.focusNode,
    this.borderRadius = Radii.ctl,
  });

  /// The focusable content.
  final Widget child;

  /// Runs on Enter, numpad Enter or the remote's Select button (any
  /// [ActivateIntent]). Null still allows focus, but OK does nothing.
  final VoidCallback? onActivate;

  /// Takes primary focus when first built, if nothing else has it.
  final bool autofocus;

  /// An optional external node, for moving focus from code.
  final FocusNode? focusNode;

  /// Corner shape of the ring, matching the child's own shape.
  final BorderRadius borderRadius;

  @override
  State<DpadFocus> createState() => _DpadFocusState();
}

class _DpadFocusState extends State<DpadFocus> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FocusableActionDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onShowFocusHighlight: (value) => setState(() => _show = value),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onActivate?.call();
            return null;
          },
        ),
      },
      child: CustomPaint(
        foregroundPainter: _show
            ? _DpadRing(c.textPrimary, c.focus, widget.borderRadius)
            : null,
        child: widget.child,
      ),
    );
  }
}

class _DpadRing extends CustomPainter {
  const _DpadRing(this.ink, this.halo, this.radius);
  final Color ink, halo;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = radius.toRRect(
      (Offset.zero & size).inflate(kDpadRingGap + kDpadRingWidth / 2),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = halo
        ..style = PaintingStyle.stroke
        ..strokeWidth = kDpadRingWidth + 4,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = kDpadRingWidth,
    );
  }

  @override
  bool shouldRepaint(_DpadRing old) =>
      old.ink != ink || old.halo != halo || old.radius != radius;
}

class _BackIntent extends Intent {
  const _BackIntent();
}

/// Makes the subtree operable with a D-pad remote: arrow keys move focus
/// directionally, Enter, numpad Enter and Select activate the focused control
/// ([ActivateIntent]), and Escape or the remote's Back button calls [onBack].
///
/// Pair it with [DpadFocus] (or any widget that handles [ActivateIntent]).
class DpadScope extends StatelessWidget {
  const DpadScope({super.key, required this.child, this.onBack});

  final Widget child;

  /// Runs on Escape or GoBack. Without it those keys are ignored.
  final VoidCallback? onBack;

  static const _shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(
      TraversalDirection.up,
    ),
    SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(
      TraversalDirection.down,
    ),
    SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(
      TraversalDirection.left,
    ),
    SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(
      TraversalDirection.right,
    ),
    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.escape): _BackIntent(),
    SingleActivator(LogicalKeyboardKey.goBack): _BackIntent(),
  };

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: {
          DirectionalFocusIntent: DirectionalFocusAction(),
          _BackIntent: CallbackAction<_BackIntent>(
            onInvoke: (_) {
              onBack?.call();
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}
