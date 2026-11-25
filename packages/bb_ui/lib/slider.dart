// Horizontal slider with optional discrete divisions, keyboard stepping,
// slider semantics, and preview/commit/cancel gesture callbacks.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'tokens.dart';

const _keyboardStepFraction = 0.05;
const _fineStepFraction = 0.01;
const _coarseStepFraction = 0.1;
const _maxVisibleTicks = 20;
const _percentScale = 100;

/// A horizontal slider built on `bb_tokens`.
///
/// Dragging emits [onChanged] during the gesture and [onChangeEnd] once on
/// release. Pressing Escape during a drag restores the starting value and
/// fires [onChangeCancel]. Tap and keyboard steps fire [onChanged] followed by
/// [onChangeEnd].
class BbSlider extends StatefulWidget {
  const BbSlider({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.semanticLabel,
    this.semanticFormatter,
    this.onChanged,
    this.onChangeEnd,
    this.onChangeCancel,
  }) : assert(min < max),
       assert(divisions == null || divisions > 0);

  /// Current value, clamped between [min] and [max].
  final double value;

  /// Minimum bound of the slider range.
  final double min;

  /// Maximum bound of the slider range.
  final double max;

  /// Optional number of discrete intervals across `[min, max]`.
  final int? divisions;

  /// Accessible label announced by screen readers.
  final String? semanticLabel;

  /// Formats a numeric value for semantic announcements; defaults to a
  /// percentage of `[min, max]` when `min == 0 && max == 1`, or rounded text.
  final String Function(double value)? semanticFormatter;

  /// Called continuously while dragging, or before [onChangeEnd] on tap/key.
  final ValueChanged<double>? onChanged;

  /// Called once when a drag finishes or a discrete change commits.
  final ValueChanged<double>? onChangeEnd;

  /// Called with the starting value if a drag is cancelled (for example by
  /// pressing Escape).
  final ValueChanged<double>? onChangeCancel;

  @override
  State<BbSlider> createState() => _BbSliderState();
}

class _BbSliderState extends State<BbSlider> {
  bool _hover = false;
  bool _focused = false;
  bool _dragging = false;
  bool _hasKeyHandler = false;

  double _dragStartValue = 0;
  double _lastEmitted = 0;

  bool get _enabled => widget.onChanged != null || widget.onChangeEnd != null;

  @override
  void dispose() {
    _detachKeyHandler();
    super.dispose();
  }

  void _attachKeyHandler() {
    if (_hasKeyHandler) return;
    HardwareKeyboard.instance.addHandler(_handleDragKey);
    _hasKeyHandler = true;
  }

  void _detachKeyHandler() {
    if (!_hasKeyHandler) return;
    HardwareKeyboard.instance.removeHandler(_handleDragKey);
    _hasKeyHandler = false;
  }

  bool _handleDragKey(KeyEvent event) {
    if (!_dragging) return false;
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _cancelDrag();
      return true;
    }
    return false;
  }

  double _snap(double raw) {
    final clamped = raw.clamp(widget.min, widget.max).toDouble();
    final divisions = widget.divisions;
    if (divisions == null) return clamped;
    final span = widget.max - widget.min;
    final stepIndex = ((clamped - widget.min) / span * divisions).round();
    return (widget.min + stepIndex * span / divisions)
        .clamp(widget.min, widget.max)
        .toDouble();
  }

  double _valueFromDx(double dx, double width, double thumbRadius) {
    final trackSpan = width - thumbRadius * 2;
    if (trackSpan <= 0) return widget.min;
    final t = ((dx - thumbRadius) / trackSpan).clamp(0.0, 1.0);
    return _snap(widget.min + t * (widget.max - widget.min));
  }

  double _stepAmount() {
    if (widget.divisions != null) {
      return (widget.max - widget.min) / widget.divisions!;
    }
    final fraction = HardwareKeyboard.instance.isShiftPressed
        ? _coarseStepFraction
        : HardwareKeyboard.instance.isAltPressed
        ? _fineStepFraction
        : _keyboardStepFraction;
    return (widget.max - widget.min) * fraction;
  }

  void _commitValue(double next) {
    final snapped = _snap(next);
    widget.onChanged?.call(snapped);
    widget.onChangeEnd?.call(snapped);
  }

  void _startDrag(double localDx, double width, double thumbRadius) {
    if (!_enabled) return;
    _dragging = true;
    _dragStartValue = _snap(widget.value);
    final next = _valueFromDx(localDx, width, thumbRadius);
    _lastEmitted = next;
    _attachKeyHandler();
    setState(() {});
    widget.onChanged?.call(next);
  }

  void _updateDrag(double localDx, double width, double thumbRadius) {
    if (!_dragging) return;
    final next = _valueFromDx(localDx, width, thumbRadius);
    if (next != _lastEmitted) {
      _lastEmitted = next;
      widget.onChanged?.call(next);
    }
  }

  void _endDrag() {
    if (!_dragging) return;
    _detachKeyHandler();
    _dragging = false;
    widget.onChangeEnd?.call(_lastEmitted);
    if (mounted) setState(() {});
  }

  void _cancelDrag() {
    if (!_dragging) return;
    _detachKeyHandler();
    _dragging = false;
    widget.onChangeCancel?.call(_dragStartValue);
    if (mounted) setState(() {});
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!_enabled) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final step = _stepAmount();
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp) {
      _commitValue(widget.value + step);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowDown) {
      _commitValue(widget.value - step);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _commitValue(widget.min);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _commitValue(widget.max);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String _formatSemantic(double v) {
    if (widget.semanticFormatter != null) return widget.semanticFormatter!(v);
    if (widget.min == 0 && widget.max == 1) {
      return '${(v * _percentScale).round()}%';
    }
    return v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = _enabled;
    final thumbDiameter = context.touch ? IconSize.md.px : Sizes.switchThumb;
    final thumbRadius = thumbDiameter / 2;
    final hitHeight = context.metrics.target.height;

    final current = _snap(widget.value);
    final t = ((current - widget.min) / (widget.max - widget.min))
        .clamp(0.0, 1.0)
        .toDouble();
    final step = widget.divisions != null
        ? (widget.max - widget.min) / widget.divisions!
        : (widget.max - widget.min) * _keyboardStepFraction;
    final increased = _snap(current + step);
    final decreased = _snap(current - step);

    return Semantics(
      slider: true,
      enabled: enabled,
      label: widget.semanticLabel,
      value: _formatSemantic(current),
      increasedValue: _formatSemantic(increased),
      decreasedValue: _formatSemantic(decreased),
      onIncrease: enabled ? () => _commitValue(increased) : null,
      onDecrease: enabled ? () => _commitValue(decreased) : null,
      child: Focus(
        canRequestFocus: enabled,
        onFocusChange: (value) => setState(() => _focused = value),
        onKeyEvent: _handleKey,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : Widths.panel;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: enabled
                    ? (d) => _commitValue(
                        _valueFromDx(d.localPosition.dx, width, thumbRadius),
                      )
                    : null,
                onHorizontalDragStart: enabled
                    ? (d) => _startDrag(d.localPosition.dx, width, thumbRadius)
                    : null,
                onHorizontalDragUpdate: enabled
                    ? (d) => _updateDrag(d.localPosition.dx, width, thumbRadius)
                    : null,
                onHorizontalDragEnd: enabled ? (_) => _endDrag() : null,
                onHorizontalDragCancel: enabled ? _cancelDrag : null,
                child: SizedBox(
                  height: hitHeight,
                  width: width,
                  child: CustomPaint(
                    painter: _SliderPainter(
                      fraction: t,
                      thumbRadius: thumbRadius,
                      divisions: widget.divisions,
                      trackColor: enabled ? c.border : c.borderSubtle,
                      activeColor: enabled ? c.accent : c.textDisabled,
                      thumbFill: c.palette.knob,
                      thumbStroke: !enabled
                          ? c.borderStrong
                          : (_hover || _dragging)
                          ? c.accentHover
                          : c.accent,
                      focusColor: _focused ? c.focus : null,
                      shadowColor: c.palette.lift,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SliderPainter extends CustomPainter {
  const _SliderPainter({
    required this.fraction,
    required this.thumbRadius,
    required this.divisions,
    required this.trackColor,
    required this.activeColor,
    required this.thumbFill,
    required this.thumbStroke,
    required this.focusColor,
    required this.shadowColor,
  });

  final double fraction;
  final double thumbRadius;
  final int? divisions;
  final Color trackColor;
  final Color activeColor;
  final Color thumbFill;
  final Color thumbStroke;
  final Color? focusColor;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final trackLeft = thumbRadius;
    final trackRight = (size.width - thumbRadius).clamp(trackLeft, size.width);
    final trackSpan = trackRight - trackLeft;
    final thumbX = trackLeft + trackSpan * fraction;
    const trackHeight = Space.xxs;
    final trackRadius = Radius.circular(trackHeight / 2);

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        trackLeft,
        cy - trackHeight / 2,
        trackRight,
        cy + trackHeight / 2,
      ),
      trackRadius,
    );
    canvas.drawRRect(bgRect, Paint()..color = trackColor);

    if (thumbX > trackLeft) {
      final activeRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          trackLeft,
          cy - trackHeight / 2,
          thumbX,
          cy + trackHeight / 2,
        ),
        trackRadius,
      );
      canvas.drawRRect(activeRect, Paint()..color = activeColor);
    }

    if (divisions != null && divisions! <= _maxVisibleTicks) {
      final tickPaint = Paint()..color = thumbFill;
      for (var i = 1; i < divisions!; i++) {
        final tx = trackLeft + trackSpan * (i / divisions!);
        canvas.drawCircle(Offset(tx, cy), Stroke.hair, tickPaint);
      }
    }

    final center = Offset(thumbX, cy);
    canvas.drawCircle(
      center + const Offset(0, Stroke.hair),
      thumbRadius,
      Paint()..color = shadowColor,
    );
    canvas.drawCircle(center, thumbRadius, Paint()..color = thumbFill);
    canvas.drawCircle(
      center,
      thumbRadius - Stroke.bold / 2,
      Paint()
        ..color = thumbStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = Stroke.bold,
    );

    if (focusColor != null) {
      canvas.drawCircle(
        center,
        thumbRadius + Sizes.focusGap,
        Paint()
          ..color = focusColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = Stroke.bold,
      );
    }
  }

  @override
  bool shouldRepaint(_SliderPainter old) =>
      old.fraction != fraction ||
      old.thumbRadius != thumbRadius ||
      old.divisions != divisions ||
      old.trackColor != trackColor ||
      old.activeColor != activeColor ||
      old.thumbFill != thumbFill ||
      old.thumbStroke != thumbStroke ||
      old.focusColor != focusColor ||
      old.shadowColor != shadowColor;
}
