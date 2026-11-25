// Compact numeric input field with label scrubbing, keyboard stepping,
// locale-flexible decimal parsing, and preview/commit/cancel callbacks.

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'selection.dart';
import 'tokens.dart';

const _defaultPrecision = 2;
const _shiftMultiplier = 10.0;
const _altMultiplier = 0.1;
const _scrubBucketPx = 4.0;
const _decimalBase = 10;
const _extraRoundDigits = 2;
const _minRoundDigits = 6;
final _decimalPattern = RegExp(r'^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$');

/// Parses a numeric string, accepting both `.` and `,` as the decimal
/// separator, and clamps the result to [min] and [max] when provided.
///
/// Returns `null` if [text] is empty, malformed, or not finite.
double? parseNumberInput(String text, {double? min, double? max}) {
  final normalized = text.trim().replaceAll(',', '.');
  if (!_decimalPattern.hasMatch(normalized)) return null;
  final parsed = double.tryParse(normalized);
  if (parsed == null || !parsed.isFinite) return null;
  var result = parsed == 0 ? 0.0 : parsed;
  if (min != null && result < min) result = min;
  if (max != null && result > max) result = max;
  return result == 0 ? 0.0 : result;
}

/// Formats [value] with up to [precision] decimal places, trimming trailing
/// fractional zeros and normalizing `-0` to `"0"`.
String formatNumberValue(double value, {int precision = _defaultPrecision}) {
  if (!value.isFinite) return '';
  final p = precision < 0 ? 0 : precision;
  var text = value.toStringAsFixed(p);
  if (p > 0 && text.contains('.')) {
    text = text.replaceFirst(RegExp(r'\.?0+$'), '');
  }
  return text == '-0' ? '0' : text;
}

/// A compact numeric field supporting direct text entry, horizontal label
/// scrubbing, and arrow-key stepping.
///
/// Continuous gestures (label scrubbing) fire [onChanged] during the drag and
/// [onChangeEnd] once on release. Text entry and arrow stepping fire
/// [onChanged] followed by [onChangeEnd] on commit. Pressing Escape during a
/// scrub or text edit restores the starting value and fires [onChangeCancel].
class NumberField extends StatefulWidget {
  const NumberField({
    super.key,
    required this.value,
    this.min,
    this.max,
    this.step = 1,
    this.precision = _defaultPrecision,
    this.label,
    this.unit,
    this.semanticLabel,
    this.enabled = true,
    this.onChanged,
    this.onChangeEnd,
    this.onChangeCancel,
    this.fieldKey,
    this.labelKey,
  });

  /// Current numeric value displayed by the field.
  final double value;

  /// Optional inclusive minimum bound.
  final double? min;

  /// Optional inclusive maximum bound.
  final double? max;

  /// Increment per scrub bucket or arrow key step.
  final double step;

  /// Maximum decimal digits displayed when formatting [value].
  final int precision;

  /// Optional short leading label (e.g. `"X"` or `"W"`). Dragging horizontally
  /// over this label scrubs the value.
  final String? label;

  /// Optional trailing unit text (e.g. `"px"` or `"°"`).
  final String? unit;

  /// Accessible name for screen readers; defaults to [label] or `"Number"`.
  final String? semanticLabel;

  /// Whether the field accepts input and scrubbing.
  final bool enabled;

  /// Called continuously during scrubbing, or immediately before [onChangeEnd]
  /// when a typed or arrow-stepped value commits.
  final ValueChanged<double>? onChanged;

  /// Called once when a scrub finishes or an edit commits.
  final ValueChanged<double>? onChangeEnd;

  /// Called with the starting value when Escape cancels a scrub or text edit.
  final ValueChanged<double>? onChangeCancel;

  /// Optional key attached to the inner [EditableText].
  final Key? fieldKey;

  /// Optional key attached to the scrubbable leading label.
  final Key? labelKey;

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late final TextEditingController _controller = TextEditingController(
    text: formatNumberValue(widget.value, precision: widget.precision),
  );
  late final FocusNode _focus = FocusNode(onKeyEvent: _handleFocusKey);

  bool _hover = false;
  bool _focused = false;
  bool _scrubbing = false;
  bool _cancelling = false;
  bool _committed = false;
  bool _hasScrubKeyHandler = false;

  double? _sessionStart;
  double _scrubOrigin = 0;
  double _scrubLastEmitted = 0;
  double _scrubAccumPx = 0;

  bool get _enabled =>
      widget.enabled &&
      (widget.onChanged != null || widget.onChangeEnd != null);

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(NumberField old) {
    super.didUpdateWidget(old);
    if (!_focused && !_scrubbing) {
      final formatted = formatNumberValue(
        widget.value,
        precision: widget.precision,
      );
      if (_controller.text != formatted) {
        _controller.text = formatted;
      }
    }
  }

  @override
  void dispose() {
    _detachScrubKeyHandler();
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _attachScrubKeyHandler() {
    if (_hasScrubKeyHandler) return;
    HardwareKeyboard.instance.addHandler(_handleScrubKey);
    _hasScrubKeyHandler = true;
  }

  void _detachScrubKeyHandler() {
    if (!_hasScrubKeyHandler) return;
    HardwareKeyboard.instance.removeHandler(_handleScrubKey);
    _hasScrubKeyHandler = false;
  }

  bool _handleScrubKey(KeyEvent event) {
    if (!_scrubbing) return false;
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _cancelScrub();
      return true;
    }
    return false;
  }

  void _onFocusChange() {
    if (_focus.hasFocus) {
      _focused = true;
      _cancelling = false;
      _committed = false;
      _sessionStart = widget.value;
      _controller.text = formatNumberValue(
        widget.value,
        precision: widget.precision,
      );
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
      setState(() {});
      return;
    }
    _focused = false;
    if (!_cancelling && !_committed) {
      _commitText();
    }
    _cancelling = false;
    _committed = false;
    setState(() {});
  }

  double _applyStep(double base, int stepCount) {
    final modifier = HardwareKeyboard.instance.isShiftPressed
        ? _shiftMultiplier
        : HardwareKeyboard.instance.isAltPressed
        ? _altMultiplier
        : 1.0;
    final raw = base + stepCount * widget.step * modifier;
    final digits = math.max(
      widget.precision + _extraRoundDigits,
      _minRoundDigits,
    );
    final factor = math.pow(_decimalBase, digits);
    var rounded = (raw * factor).roundToDouble() / factor;
    if (rounded == 0) rounded = 0.0;
    if (widget.min != null && rounded < widget.min!) rounded = widget.min!;
    if (widget.max != null && rounded > widget.max!) rounded = widget.max!;
    return rounded == 0 ? 0.0 : rounded;
  }

  void _commitText() {
    final fallback = _sessionStart ?? widget.value;
    final parsed = parseNumberInput(
      _controller.text,
      min: widget.min,
      max: widget.max,
    );
    if (parsed == null) {
      _controller.text = formatNumberValue(
        fallback,
        precision: widget.precision,
      );
      return;
    }
    _controller.text = formatNumberValue(parsed, precision: widget.precision);
    if (parsed != fallback) {
      _sessionStart = parsed;
      widget.onChanged?.call(parsed);
      widget.onChangeEnd?.call(parsed);
    }
  }

  void _cancelEdit() {
    final start = _sessionStart ?? widget.value;
    _cancelling = true;
    _controller.text = formatNumberValue(start, precision: widget.precision);
    widget.onChangeCancel?.call(start);
    _focus.unfocus();
  }

  KeyEventResult _handleFocusKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _cancelEdit();
      return KeyEventResult.handled;
    }
    if (!_enabled) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final dir = event.logicalKey == LogicalKeyboardKey.arrowUp ? 1 : -1;
      final base =
          parseNumberInput(
            _controller.text,
            min: widget.min,
            max: widget.max,
          ) ??
          widget.value;
      final next = _applyStep(base, dir);
      _controller.text = formatNumberValue(next, precision: widget.precision);
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      _sessionStart = next;
      widget.onChanged?.call(next);
      widget.onChangeEnd?.call(next);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _startScrub(DragStartDetails details) {
    if (!_enabled) return;
    _scrubbing = true;
    _scrubOrigin = widget.value;
    _scrubLastEmitted = widget.value;
    _scrubAccumPx = 0;
    _attachScrubKeyHandler();
    setState(() {});
  }

  void _updateScrub(DragUpdateDetails details) {
    if (!_scrubbing) return;
    _scrubAccumPx += details.delta.dx;
    final steps = (_scrubAccumPx / _scrubBucketPx).truncate();
    if (steps == 0) return;
    _scrubAccumPx -= steps * _scrubBucketPx;
    final next = _applyStep(_scrubLastEmitted, steps);
    if (next != _scrubLastEmitted) {
      _scrubLastEmitted = next;
      _controller.text = formatNumberValue(next, precision: widget.precision);
      widget.onChanged?.call(next);
    }
  }

  void _endScrub(DragEndDetails details) {
    if (!_scrubbing) return;
    _detachScrubKeyHandler();
    _scrubbing = false;
    widget.onChangeEnd?.call(_scrubLastEmitted);
    if (mounted) setState(() {});
  }

  void _cancelScrub() {
    if (!_scrubbing) return;
    _detachScrubKeyHandler();
    _scrubbing = false;
    _controller.text = formatNumberValue(
      _scrubOrigin,
      precision: widget.precision,
    );
    widget.onChangeCancel?.call(_scrubOrigin);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    final enabled = _enabled;
    final ink = enabled ? c.textPrimary : c.textDisabled;
    final mutedInk = enabled ? c.textTertiary : c.textDisabled;

    return Semantics(
      label: widget.semanticLabel ?? widget.label ?? 'Number',
      enabled: enabled,
      onTap: enabled ? _focus.requestFocus : null,
      onFocus: enabled ? _focus.requestFocus : null,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: CustomPaint(
          foregroundPainter: _focused ? _NumberFocusRing(c.focus) : null,
          child: AnimatedContainer(
            duration: Motion.of(context).fast,
            curve: Motion.ease,
            constraints: BoxConstraints(
              minHeight: context.metrics.field.height,
            ),
            decoration: BoxDecoration(
              color: enabled ? c.bgSecondary : c.bgTertiary,
              borderRadius: Radii.field,
              border: Border.all(
                color: !enabled
                    ? c.borderSubtle
                    : (_hover || _scrubbing)
                    ? c.threadStrong
                    : c.border,
              ),
            ),
            child: Row(
              children: [
                if (widget.label != null)
                  ExcludeSemantics(
                    child: MouseRegion(
                      cursor: enabled
                          ? SystemMouseCursors.resizeColumn
                          : MouseCursor.defer,
                      child: GestureDetector(
                        key: widget.labelKey,
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragStart: enabled ? _startScrub : null,
                        onHorizontalDragUpdate: enabled ? _updateScrub : null,
                        onHorizontalDragEnd: enabled ? _endScrub : null,
                        onHorizontalDragCancel: enabled ? _cancelScrub : null,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: Space.sm,
                            right: Space.xs,
                          ),
                          child: Text(
                            widget.label!,
                            style: ts(
                              ty.uiSmall,
                              mutedInk,
                              weight: Weight.strong,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: enabled ? _focus.requestFocus : null,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: widget.label == null ? Space.sm : 0,
                        right: widget.unit == null ? Space.sm : Space.xxs,
                      ),
                      child: EditableText(
                        key: widget.fieldKey,
                        controller: _controller,
                        focusNode: _focus,
                        style: ts(ty.codeSmall, ink, mono: true),
                        cursorColor: c.textPrimary,
                        backgroundCursorColor: c.textTertiary,
                        selectionColor: c.textSelection,
                        cursorWidth: Stroke.regular,
                        selectionControls: noteSelectionControls,
                        readOnly: !enabled,
                        autocorrect: false,
                        enableSuggestions: false,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        textInputAction: TextInputAction.done,
                        maxLines: 1,
                        onSubmitted: (_) {
                          _committed = true;
                          _commitText();
                          _focus.unfocus();
                        },
                      ),
                    ),
                  ),
                ),
                if (widget.unit != null)
                  ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.only(right: Space.sm),
                      child: Text(
                        widget.unit!,
                        style: ts(ty.uiSmall, mutedInk, weight: Weight.regular),
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

class _NumberFocusRing extends CustomPainter {
  const _NumberFocusRing(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).inflate(Sizes.focusGap);
    canvas.drawRRect(
      Radii.field.toRRect(rect),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = Stroke.bold,
    );
  }

  @override
  bool shouldRepaint(_NumberFocusRing old) => old.color != color;
}
