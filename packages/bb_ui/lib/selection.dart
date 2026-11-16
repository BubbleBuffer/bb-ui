// Text selection handles drawn in the accent colour, with no toolbar (the
// app draws its own selection toolbar or keyboard toolbar instead).

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'tokens.dart';

class NoteSelectionControls extends TextSelectionControls {
  static const _r = Sizes.selectionHandle;

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) {
    final color = context.colors.accent;
    return SizedBox(
      width: _r * 2 + Space.sm,
      height: textLineHeight + _r * 2,
      child: CustomPaint(painter: _HandlePainter(color, type, textLineHeight)),
    );
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) =>
      Offset(
        _r + Space.xxs,
        type == TextSelectionHandleType.collapsed ? 0 : textLineHeight,
      );

  @override
  Size getHandleSize(double textLineHeight) =>
      Size(_r * 2 + Space.sm, textLineHeight + _r * 2);

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) => const SizedBox.shrink();
}

final noteSelectionControls = NoteSelectionControls();

class _HandlePainter extends CustomPainter {
  _HandlePainter(this.color, this.type, this.lineHeight);
  final Color color;
  final TextSelectionHandleType type;
  final double lineHeight;

  /// The collapsed caret's dot, and the dot under a range's end.
  static const _caretDot = Space.xs, _endDot = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final cx = size.width / 2;
    // A thin stem through the line and a dot below it, as on mobile
    // handles.
    if (type == TextSelectionHandleType.collapsed) {
      canvas.drawCircle(Offset(cx, Space.sm), _caretDot, p);
      return;
    }
    canvas.drawRect(
      Rect.fromLTWH(cx - Stroke.bold / 2, 0, Stroke.bold, lineHeight),
      p,
    );
    canvas.drawCircle(Offset(cx, lineHeight + Space.xs), _endDot, p);
  }

  @override
  bool shouldRepaint(_HandlePainter old) =>
      old.color != color || old.lineHeight != lineHeight;
}
