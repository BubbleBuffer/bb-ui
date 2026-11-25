// Colour swatches, swatch grids, an HSVA + hex colour picker panel, and a
// popover helper anchored to a trigger widget.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'fields.dart';
import 'hover.dart';
import 'lines.dart';
import 'menu.dart';
import 'tokens.dart';
import 'tooltip.dart';

const _channelMax = 255.0;
const _channelByteMax = 255;
const _hexRadix = 16;
const _hexShort = 3;
const _hexRgb = 6;
const _hexRgba = 8;
const _byteStartG = 2;
const _byteStartB = 4;
const _byteStartA = 6;
const _nibbleScale = 17;
const _hexWidth = 2;
const _hueMax = 360.0;
const _hueStep = 60.0;
const _hueStopCount = 6;
const _hueKeyStep = 10.0;
const _svKeyStep = 0.05;
const _alphaKeyStep = 0.05;
const _percentScale = 100;
const _opaqueAlpha = 1.0;

final _hexChars = RegExp(r'^[0-9a-fA-F]+$');

/// Parses `#RGB`, `#RRGGBB`, or `#RRGGBBAA` (with or without leading `#`).
/// Returns `null` for invalid input.
Color? parseHexColor(String input) {
  var hex = input.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (!_hexChars.hasMatch(hex)) return null;

  int r, g, b, a;
  if (hex.length == _hexShort) {
    r = int.parse(hex[0], radix: _hexRadix) * _nibbleScale;
    g = int.parse(hex[1], radix: _hexRadix) * _nibbleScale;
    b = int.parse(hex[2], radix: _hexRadix) * _nibbleScale;
    a = _channelByteMax;
  } else if (hex.length == _hexRgb) {
    r = int.parse(hex.substring(0, _byteStartG), radix: _hexRadix);
    g = int.parse(hex.substring(_byteStartG, _byteStartB), radix: _hexRadix);
    b = int.parse(hex.substring(_byteStartB, _hexRgb), radix: _hexRadix);
    a = _channelByteMax;
  } else if (hex.length == _hexRgba) {
    r = int.parse(hex.substring(0, _byteStartG), radix: _hexRadix);
    g = int.parse(hex.substring(_byteStartG, _byteStartB), radix: _hexRadix);
    b = int.parse(hex.substring(_byteStartB, _byteStartA), radix: _hexRadix);
    a = int.parse(hex.substring(_byteStartA, _hexRgba), radix: _hexRadix);
  } else {
    return null;
  }
  // User-supplied hex colour parsed from text input.
  // ignore: bb_lints/no_raw_colors
  return Color.fromARGB(a, r, g, b);
}

/// Formats [color] as uppercase `#RRGGBB`, or `#RRGGBBAA` when translucent or
/// when [includeAlpha] is true.
String formatHexColor(Color color, {bool includeAlpha = false}) {
  String hexByte(double channel) => (channel * _channelMax)
      .round()
      .clamp(0, _channelByteMax)
      .toRadixString(_hexRadix)
      .padLeft(_hexWidth, '0')
      .toUpperCase();

  final r = hexByte(color.r);
  final g = hexByte(color.g);
  final b = hexByte(color.b);
  final aByte = (color.a * _channelMax).round().clamp(0, _channelByteMax);
  if (includeAlpha || aByte < _channelByteMax) {
    final a = aByte
        .toRadixString(_hexRadix)
        .padLeft(_hexWidth, '0')
        .toUpperCase();
    return '#$r$g$b$a';
  }
  return '#$r$g$b';
}

/// A square colour swatch button.
///
/// Renders a checkerboard underneath translucent colours and a diagonal line
/// when [color] is `null` ("none").
class SwatchButton extends StatelessWidget {
  const SwatchButton({
    super.key,
    required this.color,
    this.onPressed,
    this.selected = false,
    this.size,
    this.semanticLabel,
    this.tooltip,
  });

  /// The colour displayed by this swatch, or `null` for the "none" state.
  final Color? color;

  /// Called when tapped or activated; null disables interaction.
  final VoidCallback? onPressed;

  /// Draws an accent selection ring around the swatch.
  final bool selected;

  /// Optional square size; defaults to `ControlSize.xs` (pointer) or
  /// `ControlSize.md` (touch).
  final ControlSize? size;

  /// Accessible label; defaults to [tooltip], `"None"`, or the formatted hex.
  final String? semanticLabel;

  /// Optional tooltip shown on hover, focus, or long-press.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    final dim =
        (size ?? (context.touch ? ControlSize.md : ControlSize.xs)).height;
    final label =
        semanticLabel ??
        tooltip ??
        (color == null ? 'None' : formatHexColor(color!));

    final box = Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      heightFactor: 1,
      child: Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        label: label,
        excludeSemantics: true,
        onTap: onPressed,
        child: Hover(
          onTap: onPressed,
          lift: 0,
          radius: Radii.sm,
          child: Container(
            width: dim,
            height: dim,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.sm),
              border: Border.all(
                color: selected
                    ? c.accent
                    : enabled
                    ? c.borderStrong
                    : c.borderSubtle,
                width: selected ? Stroke.bold : Stroke.hair,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.sm),
              child: CustomPaint(
                painter: _SwatchPainter(
                  color: color,
                  surface: c.bgPrimary,
                  checkerLight: c.bgPrimary,
                  checkerDark: c.border,
                  noneStroke: c.palette.dangerInk,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? box : AppTooltip(label: tooltip!, child: box);
  }
}

class _SwatchPainter extends CustomPainter {
  const _SwatchPainter({
    required this.color,
    required this.surface,
    required this.checkerLight,
    required this.checkerDark,
    required this.noneStroke,
  });

  final Color? color;
  final Color surface;
  final Color checkerLight;
  final Color checkerDark;
  final Color noneStroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (color == null) {
      canvas.drawRect(rect, Paint()..color = surface);
      canvas.drawLine(
        Offset(0, size.height),
        Offset(size.width, 0),
        Paint()
          ..color = noneStroke
          ..strokeWidth = Stroke.bold
          ..strokeCap = StrokeCap.round,
      );
      return;
    }
    if (color!.a < _opaqueAlpha) {
      _paintCheckerboard(canvas, size, checkerLight, checkerDark);
    }
    canvas.drawRect(rect, Paint()..color = color!);
  }

  @override
  bool shouldRepaint(_SwatchPainter old) =>
      old.color != color ||
      old.surface != surface ||
      old.checkerLight != checkerLight ||
      old.checkerDark != checkerDark ||
      old.noneStroke != noneStroke;
}

void _paintCheckerboard(Canvas canvas, Size size, Color light, Color dark) {
  canvas.drawRect(Offset.zero & size, Paint()..color = light);
  const cell = Space.xxs;
  final paint = Paint()..color = dark;
  final cols = (size.width / cell).ceil();
  final rows = (size.height / cell).ceil();
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if ((r + c).isOdd) {
        canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell, cell), paint);
      }
    }
  }
}

/// A wrapped grid of [SwatchButton] choices with an optional leading "none"
/// swatch.
class SwatchGrid extends StatelessWidget {
  const SwatchGrid({
    super.key,
    required this.colors,
    this.selected,
    required this.onSelected,
    this.allowNone = false,
    this.swatchSize,
    this.spacing = Space.xs,
  });

  /// Preset colours shown in the grid.
  final List<Color> colors;

  /// Currently selected colour (or `null` when "none" is selected).
  final Color? selected;

  /// Called when a swatch is tapped; passes `null` for the "none" swatch.
  final ValueChanged<Color?>? onSelected;

  /// Whether to prepend a "none" swatch.
  final bool allowNone;

  /// Optional square size for each swatch.
  final ControlSize? swatchSize;

  /// Spacing between swatches horizontally and vertically.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final enabled = onSelected != null;
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        if (allowNone)
          SwatchButton(
            color: null,
            selected: selected == null,
            size: swatchSize,
            tooltip: 'None',
            onPressed: enabled ? () => onSelected!(null) : null,
          ),
        for (final c in colors)
          SwatchButton(
            color: c,
            selected: selected != null && selected!.toARGB32() == c.toARGB32(),
            size: swatchSize,
            tooltip: formatHexColor(c),
            onPressed: enabled ? () => onSelected!(c) : null,
          ),
      ],
    );
  }
}

/// An HSVA colour picker with saturation/value area, hue slider, optional
/// alpha slider, hex input (`#RGB`, `#RRGGBB`, `#RRGGBBAA`), optional "none"
/// toggle, and optional [swatches].
///
/// Continuous drags fire [onChanged] during the gesture and [onChangeEnd] once
/// on release; Escape restores the starting colour and fires [onChangeCancel].
class ColorPickerPanel extends StatefulWidget {
  const ColorPickerPanel({
    super.key,
    required this.color,
    this.onChanged,
    this.onChangeEnd,
    this.onChangeCancel,
    this.allowNone = true,
    this.showAlpha = true,
    this.swatches,
    this.width = Widths.panel,
  });

  /// Current colour (`null` represents "none").
  final Color? color;

  /// Called continuously while dragging, or before [onChangeEnd] on discrete
  /// changes (swatches, hex commit, "none", keyboard steps).
  final ValueChanged<Color?>? onChanged;

  /// Called once when a drag finishes or a discrete change commits.
  final ValueChanged<Color?>? onChangeEnd;

  /// Called with the starting colour when Escape cancels a drag or hex edit.
  final ValueChanged<Color?>? onChangeCancel;

  /// Whether a "none" (`null`) button is offered.
  final bool allowNone;

  /// Whether the alpha slider is shown.
  final bool showAlpha;

  /// Optional palette swatches displayed below the hex field.
  final List<Color>? swatches;

  /// Maximum width of the panel.
  final double width;

  @override
  State<ColorPickerPanel> createState() => _ColorPickerPanelState();
}

class _ColorPickerPanelState extends State<ColorPickerPanel> {
  final TextEditingController _hexController = TextEditingController();
  late final FocusNode _hexFocus = FocusNode(onKeyEvent: _handleHexKey);

  late double _hue;
  late double _sat;
  late double _val;
  late double _alpha;
  late bool _isNone;

  bool _dragging = false;
  bool _hexFocused = false;
  bool _hexCancelling = false;
  bool _hexCommitted = false;
  bool _hasDragKeyHandler = false;

  Color? _dragStartColor;
  Color? _hexStartColor;

  bool get _enabled => widget.onChanged != null || widget.onChangeEnd != null;

  @override
  void initState() {
    super.initState();
    _syncFromColor(widget.color, updateHex: true);
    _hexFocus.addListener(_onHexFocusChange);
  }

  @override
  void didUpdateWidget(ColorPickerPanel old) {
    super.didUpdateWidget(old);
    if (!_dragging && widget.color != old.color) {
      if (widget.color != _currentColor) {
        _syncFromColor(widget.color, updateHex: !_hexFocused);
      }
    }
  }

  @override
  void dispose() {
    _detachDragKeyHandler();
    _hexFocus.removeListener(_onHexFocusChange);
    _hexFocus.dispose();
    _hexController.dispose();
    super.dispose();
  }

  Color? get _currentColor {
    if (_isNone) return null;
    final a = widget.showAlpha ? _alpha : _opaqueAlpha;
    return HSVColor.fromAHSV(a, _hue, _sat, _val).toColor();
  }

  void _syncFromColor(Color? color, {required bool updateHex}) {
    if (color == null) {
      _isNone = true;
      _hue = 0;
      _sat = _opaqueAlpha;
      _val = _opaqueAlpha;
      _alpha = _opaqueAlpha;
      if (updateHex) _hexController.text = '';
      return;
    }
    _isNone = false;
    final hsv = HSVColor.fromColor(color);
    _hue = hsv.hue;
    _sat = hsv.saturation;
    _val = hsv.value;
    _alpha = widget.showAlpha ? hsv.alpha : _opaqueAlpha;
    if (updateHex) {
      _hexController.text = formatHexColor(color);
    }
  }

  void _syncHexText() {
    final current = _currentColor;
    _hexController.text = current == null ? '' : formatHexColor(current);
  }

  void _attachDragKeyHandler() {
    if (_hasDragKeyHandler) return;
    HardwareKeyboard.instance.addHandler(_handleDragKey);
    _hasDragKeyHandler = true;
  }

  void _detachDragKeyHandler() {
    if (!_hasDragKeyHandler) return;
    HardwareKeyboard.instance.removeHandler(_handleDragKey);
    _hasDragKeyHandler = false;
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

  void _beginDrag() {
    if (!_enabled) return;
    _dragging = true;
    _dragStartColor = _currentColor;
    _attachDragKeyHandler();
  }

  void _emitDragUpdate() {
    _isNone = false;
    _syncHexText();
    setState(() {});
    widget.onChanged?.call(_currentColor);
  }

  void _endDrag() {
    if (!_dragging) return;
    _detachDragKeyHandler();
    _dragging = false;
    widget.onChangeEnd?.call(_currentColor);
    if (mounted) setState(() {});
  }

  void _cancelDrag() {
    if (!_dragging) return;
    _detachDragKeyHandler();
    _dragging = false;
    _syncFromColor(_dragStartColor, updateHex: true);
    widget.onChangeCancel?.call(_dragStartColor);
    if (mounted) setState(() {});
  }

  void _commitColor(Color? next) {
    _syncFromColor(next, updateHex: true);
    setState(() {});
    widget.onChanged?.call(next);
    widget.onChangeEnd?.call(next);
  }

  void _onHexFocusChange() {
    if (_hexFocus.hasFocus) {
      _hexFocused = true;
      _hexCancelling = false;
      _hexCommitted = false;
      _hexStartColor = _currentColor;
      _hexController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _hexController.text.length,
      );
      setState(() {});
      return;
    }
    _hexFocused = false;
    if (!_hexCancelling && !_hexCommitted) {
      _commitHexText();
    }
    _hexCancelling = false;
    _hexCommitted = false;
    setState(() {});
  }

  void _commitHexText() {
    final fallback = _hexStartColor;
    final parsed = parseHexColor(_hexController.text);
    if (parsed == null) {
      _syncFromColor(fallback, updateHex: true);
      return;
    }
    final next = widget.showAlpha
        ? parsed
        : parsed.withValues(alpha: _opaqueAlpha);
    _syncFromColor(next, updateHex: true);
    if (next != fallback) {
      _hexStartColor = next;
      widget.onChanged?.call(next);
      widget.onChangeEnd?.call(next);
    }
  }

  KeyEventResult _handleHexKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _hexCancelling = true;
      final start = _hexStartColor;
      _syncFromColor(start, updateHex: true);
      widget.onChangeCancel?.call(start);
      _hexFocus.unfocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    final current = _currentColor;
    final pureHue = HSVColor.fromAHSV(
      _opaqueAlpha,
      _hue,
      _opaqueAlpha,
      _opaqueAlpha,
    ).toColor();
    final opaqueColor = HSVColor.fromAHSV(
      _opaqueAlpha,
      _hue,
      _sat,
      _val,
    ).toColor();

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.width),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Space.sm,
        children: [
          _SvArea(
            key: const ValueKey('color-picker-sv-area'),
            hueColor: pureHue,
            saturation: _sat,
            value: _val,
            thumbColor: opaqueColor,
            enabled: _enabled,
            onDragStart: (s, v) {
              _beginDrag();
              _sat = s;
              _val = v;
              _emitDragUpdate();
            },
            onDragUpdate: (s, v) {
              _sat = s;
              _val = v;
              _emitDragUpdate();
            },
            onDragEnd: _endDrag,
            onDragCancel: _cancelDrag,
            onDiscrete: (s, v) {
              _isNone = false;
              _sat = s;
              _val = v;
              _commitColor(_currentColor);
            },
          ),
          _HueBar(
            key: const ValueKey('color-picker-hue-slider'),
            hue: _hue,
            enabled: _enabled,
            onDragStart: (h) {
              _beginDrag();
              _hue = h;
              _emitDragUpdate();
            },
            onDragUpdate: (h) {
              _hue = h;
              _emitDragUpdate();
            },
            onDragEnd: _endDrag,
            onDragCancel: _cancelDrag,
            onDiscrete: (h) {
              _isNone = false;
              _hue = h;
              _commitColor(_currentColor);
            },
          ),
          if (widget.showAlpha)
            _AlphaBar(
              key: const ValueKey('color-picker-alpha-slider'),
              alpha: _alpha,
              opaqueColor: opaqueColor,
              enabled: _enabled,
              onDragStart: (a) {
                _beginDrag();
                _alpha = a;
                _emitDragUpdate();
              },
              onDragUpdate: (a) {
                _alpha = a;
                _emitDragUpdate();
              },
              onDragEnd: _endDrag,
              onDragCancel: _cancelDrag,
              onDiscrete: (a) {
                _isNone = false;
                _alpha = a;
                _commitColor(_currentColor);
              },
            ),
          Row(
            spacing: Space.xs,
            children: [
              SwatchButton(
                color: current,
                size: ControlSize.sm,
                semanticLabel: current == null
                    ? 'Current colour: none'
                    : 'Current colour ${formatHexColor(current)}',
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _enabled ? _hexFocus.requestFocus : null,
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: context.metrics.field.height,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: _enabled ? c.bgSecondary : c.bgTertiary,
                      borderRadius: Radii.field,
                      border: Border.all(
                        color: _hexFocused ? c.focus : c.border,
                        width: _hexFocused ? Stroke.bold : Stroke.hair,
                      ),
                    ),
                    child: PlainField(
                      key: const ValueKey('color-picker-hex-field'),
                      controller: _hexController,
                      focusNode: _hexFocus,
                      style: ts(
                        ty.codeSmall,
                        _enabled ? c.textPrimary : c.textDisabled,
                        mono: true,
                      ),
                      placeholder: _isNone ? 'None' : '#RRGGBB',
                      semanticLabel: 'Hex colour',
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        _hexCommitted = true;
                        _commitHexText();
                        _hexFocus.unfocus();
                      },
                    ),
                  ),
                ),
              ),
              if (widget.allowNone)
                SwatchButton(
                  color: null,
                  selected: _isNone,
                  size: ControlSize.sm,
                  tooltip: 'None',
                  onPressed: _enabled ? () => _commitColor(null) : null,
                ),
            ],
          ),
          if (widget.swatches != null && widget.swatches!.isNotEmpty) ...[
            const HLine(),
            SwatchGrid(
              colors: widget.swatches!,
              selected: current,
              onSelected: _enabled ? _commitColor : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _SvArea extends StatefulWidget {
  const _SvArea({
    super.key,
    required this.hueColor,
    required this.saturation,
    required this.value,
    required this.thumbColor,
    required this.enabled,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
    required this.onDiscrete,
  });

  final Color hueColor;
  final double saturation;
  final double value;
  final Color thumbColor;
  final bool enabled;
  final void Function(double s, double v) onDragStart;
  final void Function(double s, double v) onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onDragCancel;
  final void Function(double s, double v) onDiscrete;

  @override
  State<_SvArea> createState() => _SvAreaState();
}

class _SvAreaState extends State<_SvArea> {
  bool _focused = false;

  (double, double) _svFromLocal(Offset pos, Size size) {
    final s = size.width <= 0 ? 0.0 : (pos.dx / size.width).clamp(0.0, 1.0);
    final v = size.height <= 0
        ? 0.0
        : (1.0 - pos.dy / size.height).clamp(0.0, 1.0);
    return (s.toDouble(), v.toDouble());
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    var s = widget.saturation;
    var v = widget.value;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        s = (s - _svKeyStep).clamp(0.0, 1.0).toDouble();
      case LogicalKeyboardKey.arrowRight:
        s = (s + _svKeyStep).clamp(0.0, 1.0).toDouble();
      case LogicalKeyboardKey.arrowDown:
        v = (v - _svKeyStep).clamp(0.0, 1.0).toDouble();
      case LogicalKeyboardKey.arrowUp:
        v = (v + _svKeyStep).clamp(0.0, 1.0).toDouble();
      default:
        return KeyEventResult.ignored;
    }
    widget.onDiscrete(s, v);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sPct = (widget.saturation * _percentScale).round();
    final vPct = (widget.value * _percentScale).round();
    return Semantics(
      label: 'Saturation and brightness',
      value: 'Saturation $sPct%, brightness $vPct%',
      enabled: widget.enabled,
      child: Focus(
        canRequestFocus: widget.enabled,
        onFocusChange: (v) => setState(() => _focused = v),
        onKeyEvent: _handleKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : Widths.panel;
            const height = Sizes.displayMap;
            final boxSize = Size(width, height);
            return MouseRegion(
              cursor: widget.enabled
                  ? SystemMouseCursors.precise
                  : MouseCursor.defer,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: widget.enabled
                    ? (d) {
                        final (s, v) = _svFromLocal(d.localPosition, boxSize);
                        widget.onDiscrete(s, v);
                      }
                    : null,
                onPanStart: widget.enabled
                    ? (d) {
                        final (s, v) = _svFromLocal(d.localPosition, boxSize);
                        widget.onDragStart(s, v);
                      }
                    : null,
                onPanUpdate: widget.enabled
                    ? (d) {
                        final (s, v) = _svFromLocal(d.localPosition, boxSize);
                        widget.onDragUpdate(s, v);
                      }
                    : null,
                onPanEnd: widget.enabled ? (_) => widget.onDragEnd() : null,
                onPanCancel: widget.enabled ? widget.onDragCancel : null,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: Radii.field,
                    border: Border.all(
                      color: _focused ? c.focus : c.borderStrong,
                      width: _focused ? Stroke.bold : Stroke.hair,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: Radii.field,
                    child: CustomPaint(
                      size: Size(width, height),
                      painter: _SvPainter(
                        hueColor: widget.hueColor,
                        saturation: widget.saturation,
                        value: widget.value,
                        thumbColor: widget.thumbColor,
                        ringColor: c.palette.knob,
                        outerRingColor: c.palette.black.withValues(
                          alpha: Alpha.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SvPainter extends CustomPainter {
  const _SvPainter({
    required this.hueColor,
    required this.saturation,
    required this.value,
    required this.thumbColor,
    required this.ringColor,
    required this.outerRingColor,
  });

  final Color hueColor;
  final double saturation;
  final double value;
  final Color thumbColor;
  final Color ringColor;
  final Color outerRingColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = hueColor);

    final white = HSVColor.fromAHSV(_opaqueAlpha, 0, 0, _opaqueAlpha).toColor();
    final black = HSVColor.fromAHSV(_opaqueAlpha, 0, 0, 0).toColor();
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [white, kTransparent],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [black, kTransparent],
        ).createShader(rect),
    );

    final thumb = Offset(saturation * size.width, (1.0 - value) * size.height);
    final radius = Sizes.dot;
    canvas.drawCircle(thumb, radius, Paint()..color = thumbColor);
    canvas.drawCircle(
      thumb,
      radius,
      Paint()
        ..color = outerRingColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = Stroke.seam,
    );
    canvas.drawCircle(
      thumb,
      radius,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = Stroke.bold,
    );
  }

  @override
  bool shouldRepaint(_SvPainter old) =>
      old.hueColor != hueColor ||
      old.saturation != saturation ||
      old.value != value ||
      old.thumbColor != thumbColor ||
      old.ringColor != ringColor ||
      old.outerRingColor != outerRingColor;
}

class _HueBar extends StatefulWidget {
  const _HueBar({
    super.key,
    required this.hue,
    required this.enabled,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
    required this.onDiscrete,
  });

  final double hue;
  final bool enabled;
  final ValueChanged<double> onDragStart;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onDragCancel;
  final ValueChanged<double> onDiscrete;

  @override
  State<_HueBar> createState() => _HueBarState();
}

class _HueBarState extends State<_HueBar> {
  bool _focused = false;

  double _hueFromDx(double dx, double width) {
    if (width <= 0) return 0;
    return ((dx / width).clamp(0.0, 1.0) * _hueMax).toDouble();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      widget.onDiscrete((widget.hue + _hueKeyStep).clamp(0.0, _hueMax));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      widget.onDiscrete((widget.hue - _hueKeyStep).clamp(0.0, _hueMax));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final height = context.touch ? ControlSize.xs.height : IconSize.sm.px;
    final inc = (widget.hue + _hueKeyStep).clamp(0.0, _hueMax).toDouble();
    final dec = (widget.hue - _hueKeyStep).clamp(0.0, _hueMax).toDouble();

    return Semantics(
      slider: true,
      enabled: widget.enabled,
      label: 'Hue',
      value: '${widget.hue.round()}°',
      increasedValue: '${inc.round()}°',
      decreasedValue: '${dec.round()}°',
      onIncrease: widget.enabled ? () => widget.onDiscrete(inc) : null,
      onDecrease: widget.enabled ? () => widget.onDiscrete(dec) : null,
      child: Focus(
        canRequestFocus: widget.enabled,
        onFocusChange: (v) => setState(() => _focused = v),
        onKeyEvent: _handleKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : Widths.panel;
            return MouseRegion(
              cursor: widget.enabled
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: widget.enabled
                    ? (d) => widget.onDiscrete(
                        _hueFromDx(d.localPosition.dx, width),
                      )
                    : null,
                onHorizontalDragStart: widget.enabled
                    ? (d) => widget.onDragStart(
                        _hueFromDx(d.localPosition.dx, width),
                      )
                    : null,
                onHorizontalDragUpdate: widget.enabled
                    ? (d) => widget.onDragUpdate(
                        _hueFromDx(d.localPosition.dx, width),
                      )
                    : null,
                onHorizontalDragEnd: widget.enabled
                    ? (_) => widget.onDragEnd()
                    : null,
                onHorizontalDragCancel: widget.enabled
                    ? widget.onDragCancel
                    : null,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: Radii.pill,
                    border: Border.all(
                      color: _focused ? c.focus : c.borderStrong,
                      width: _focused ? Stroke.bold : Stroke.hair,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: Radii.pill,
                    child: CustomPaint(
                      size: Size(width, height),
                      painter: _HueBarPainter(
                        fraction: (widget.hue / _hueMax).clamp(0.0, 1.0),
                        thumbColor: c.palette.knob,
                        thumbBorder: c.palette.black.withValues(
                          alpha: Alpha.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HueBarPainter extends CustomPainter {
  const _HueBarPainter({
    required this.fraction,
    required this.thumbColor,
    required this.thumbBorder,
  });

  final double fraction;
  final Color thumbColor;
  final Color thumbBorder;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stops = [
      for (var i = 0; i <= _hueStopCount; i++)
        HSVColor.fromAHSV(
          _opaqueAlpha,
          (i * _hueStep).clamp(0.0, _hueMax),
          _opaqueAlpha,
          _opaqueAlpha,
        ).toColor(),
    ];
    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(colors: stops).createShader(rect),
    );
    _paintBarThumb(canvas, size, fraction, thumbColor, thumbBorder);
  }

  @override
  bool shouldRepaint(_HueBarPainter old) =>
      old.fraction != fraction ||
      old.thumbColor != thumbColor ||
      old.thumbBorder != thumbBorder;
}

class _AlphaBar extends StatefulWidget {
  const _AlphaBar({
    super.key,
    required this.alpha,
    required this.opaqueColor,
    required this.enabled,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
    required this.onDiscrete,
  });

  final double alpha;
  final Color opaqueColor;
  final bool enabled;
  final ValueChanged<double> onDragStart;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onDragCancel;
  final ValueChanged<double> onDiscrete;

  @override
  State<_AlphaBar> createState() => _AlphaBarState();
}

class _AlphaBarState extends State<_AlphaBar> {
  bool _focused = false;

  double _alphaFromDx(double dx, double width) {
    if (width <= 0) return _opaqueAlpha;
    return (dx / width).clamp(0.0, 1.0).toDouble();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      widget.onDiscrete((widget.alpha + _alphaKeyStep).clamp(0.0, 1.0));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      widget.onDiscrete((widget.alpha - _alphaKeyStep).clamp(0.0, 1.0));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final height = context.touch ? ControlSize.xs.height : IconSize.sm.px;
    final inc = (widget.alpha + _alphaKeyStep).clamp(0.0, 1.0).toDouble();
    final dec = (widget.alpha - _alphaKeyStep).clamp(0.0, 1.0).toDouble();

    return Semantics(
      slider: true,
      enabled: widget.enabled,
      label: 'Alpha',
      value: '${(widget.alpha * _percentScale).round()}%',
      increasedValue: '${(inc * _percentScale).round()}%',
      decreasedValue: '${(dec * _percentScale).round()}%',
      onIncrease: widget.enabled ? () => widget.onDiscrete(inc) : null,
      onDecrease: widget.enabled ? () => widget.onDiscrete(dec) : null,
      child: Focus(
        canRequestFocus: widget.enabled,
        onFocusChange: (v) => setState(() => _focused = v),
        onKeyEvent: _handleKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : Widths.panel;
            return MouseRegion(
              cursor: widget.enabled
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: widget.enabled
                    ? (d) => widget.onDiscrete(
                        _alphaFromDx(d.localPosition.dx, width),
                      )
                    : null,
                onHorizontalDragStart: widget.enabled
                    ? (d) => widget.onDragStart(
                        _alphaFromDx(d.localPosition.dx, width),
                      )
                    : null,
                onHorizontalDragUpdate: widget.enabled
                    ? (d) => widget.onDragUpdate(
                        _alphaFromDx(d.localPosition.dx, width),
                      )
                    : null,
                onHorizontalDragEnd: widget.enabled
                    ? (_) => widget.onDragEnd()
                    : null,
                onHorizontalDragCancel: widget.enabled
                    ? widget.onDragCancel
                    : null,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: Radii.pill,
                    border: Border.all(
                      color: _focused ? c.focus : c.borderStrong,
                      width: _focused ? Stroke.bold : Stroke.hair,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: Radii.pill,
                    child: CustomPaint(
                      size: Size(width, height),
                      painter: _AlphaBarPainter(
                        alpha: widget.alpha,
                        opaqueColor: widget.opaqueColor,
                        checkerLight: c.bgPrimary,
                        checkerDark: c.border,
                        thumbColor: c.palette.knob,
                        thumbBorder: c.palette.black.withValues(
                          alpha: Alpha.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AlphaBarPainter extends CustomPainter {
  const _AlphaBarPainter({
    required this.alpha,
    required this.opaqueColor,
    required this.checkerLight,
    required this.checkerDark,
    required this.thumbColor,
    required this.thumbBorder,
  });

  final double alpha;
  final Color opaqueColor;
  final Color checkerLight;
  final Color checkerDark;
  final Color thumbColor;
  final Color thumbBorder;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    _paintCheckerboard(canvas, size, checkerLight, checkerDark);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [opaqueColor.withValues(alpha: 0), opaqueColor],
        ).createShader(rect),
    );
    _paintBarThumb(
      canvas,
      size,
      alpha.clamp(0.0, 1.0),
      thumbColor,
      thumbBorder,
    );
  }

  @override
  bool shouldRepaint(_AlphaBarPainter old) =>
      old.alpha != alpha ||
      old.opaqueColor != opaqueColor ||
      old.checkerLight != checkerLight ||
      old.checkerDark != checkerDark ||
      old.thumbColor != thumbColor ||
      old.thumbBorder != thumbBorder;
}

void _paintBarThumb(
  Canvas canvas,
  Size size,
  double fraction,
  Color fill,
  Color stroke,
) {
  final radius = (size.height / 2 - Stroke.hair).clamp(
    Stroke.bold,
    size.height,
  );
  final minX = radius + Stroke.hair;
  final maxX = (size.width - radius - Stroke.hair).clamp(minX, size.width);
  final cx = minX + (maxX - minX) * fraction;
  final center = Offset(cx, size.height / 2);
  canvas.drawCircle(center, radius, Paint()..color = fill);
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = Stroke.regular,
  );
}

/// Opens a [ColorPickerPanel] in a popover anchored to [anchor] (or to
/// [context]'s render box when omitted).
Future<Color?> showColorPicker(
  BuildContext context, {
  Rect? anchor,
  required Color? color,
  ValueChanged<Color?>? onChanged,
  ValueChanged<Color?>? onChangeEnd,
  ValueChanged<Color?>? onChangeCancel,
  bool allowNone = true,
  bool showAlpha = true,
  List<Color>? swatches,
}) {
  final rect = anchor ?? globalRectOf(context);
  return showPopover<Color?>(
    context,
    rect,
    (ctx) => _ColorPickerPopover(
      initialColor: color,
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      onChangeCancel: onChangeCancel,
      allowNone: allowNone,
      showAlpha: showAlpha,
      swatches: swatches,
    ),
  );
}

class _ColorPickerPopover extends StatefulWidget {
  const _ColorPickerPopover({
    required this.initialColor,
    required this.onChanged,
    required this.onChangeEnd,
    required this.onChangeCancel,
    required this.allowNone,
    required this.showAlpha,
    required this.swatches,
  });

  final Color? initialColor;
  final ValueChanged<Color?>? onChanged;
  final ValueChanged<Color?>? onChangeEnd;
  final ValueChanged<Color?>? onChangeCancel;
  final bool allowNone;
  final bool showAlpha;
  final List<Color>? swatches;

  @override
  State<_ColorPickerPopover> createState() => _ColorPickerPopoverState();
}

class _ColorPickerPopoverState extends State<_ColorPickerPopover> {
  late Color? _current = widget.initialColor;

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () =>
          Navigator.of(context).pop(_current),
    },
    child: MenuSurface(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: ColorPickerPanel(
          color: _current,
          allowNone: widget.allowNone,
          showAlpha: widget.showAlpha,
          swatches: widget.swatches,
          onChanged: (c) {
            setState(() => _current = c);
            widget.onChanged?.call(c);
          },
          onChangeEnd: (c) {
            setState(() => _current = c);
            widget.onChangeEnd?.call(c);
          },
          onChangeCancel: (c) {
            setState(() => _current = c);
            widget.onChangeCancel?.call(c);
          },
        ),
      ),
    ),
  );
}
