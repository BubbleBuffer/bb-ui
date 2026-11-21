// Layout primitives that keep spacing on the scale and let a component adapt
// to its own width: Gap, AdaptiveLayout and InlineOrStacked.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// Empty space of [extent] along its parent's axis: `Gap(Space.sm)` is 8 wide
/// in a [Row] and 8 tall in a [Column] or [Wrap] run. Outside a flex it is a
/// square, which a list's tight cross axis turns into a strip.
///
/// For equal gaps between every child, prefer the parent's `spacing:`.
class Gap extends LeafRenderObjectWidget {
  const Gap(this.extent, {super.key});

  /// One of the [Space] steps.
  final double extent;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderGap(extent);

  @override
  void updateRenderObject(BuildContext context, RenderGap renderObject) {
    renderObject.extent = extent;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('extent', extent));
  }
}

/// The render object of a [Gap].
class RenderGap extends RenderBox {
  RenderGap(this._extent);

  double _extent;
  set extent(double value) {
    if (value == _extent) return;
    _extent = value;
    markNeedsLayout();
  }

  /// The parent's main axis, or null outside a flex or wrap.
  Axis? get _axis => switch (parent) {
    RenderFlex(:final direction) => direction,
    RenderWrap(:final direction) => direction,
    _ => null,
  };

  Size get _size => switch (_axis) {
    Axis.horizontal => Size(_extent, 0),
    Axis.vertical => Size(0, _extent),
    null => Size.square(_extent),
  };

  @override
  double computeMinIntrinsicWidth(double height) => _size.width;
  @override
  double computeMaxIntrinsicWidth(double height) => _size.width;
  @override
  double computeMinIntrinsicHeight(double width) => _size.height;
  @override
  double computeMaxIntrinsicHeight(double width) => _size.height;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(_size);

  @override
  void performLayout() => size = constraints.constrain(_size);
}

/// Builds by the [SizeClass] of its own width, not the window's, and puts
/// that class in a [SizeClassScope] so everything below reads it with
/// `context.sizeClass`.
///
/// ```dart
/// AdaptiveLayout(
///   builder: (context, size) => size.isCompact ? column : row,
/// )
/// ```
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({super.key, required this.builder});

  final Widget Function(BuildContext context, SizeClass sizeClass) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final sizeClass = SizeClass.forWidth(constraints.maxWidth);
      return SizeClassScope(
        sizeClass: sizeClass,
        child: Builder(builder: (context) => builder(context, sizeClass)),
      );
    },
  );
}

/// [main] with [trailing] after it on one line while [main] still gets its
/// minimum width there (its longest word); otherwise [trailing] goes under
/// [main], at its own width. The choice follows the text size as well as
/// the width: a row's action drops below its text only when they no longer
/// fit side by side.
class InlineOrStacked extends MultiChildRenderObjectWidget {
  InlineOrStacked({
    super.key,
    required Widget main,
    required Widget trailing,
    this.gap = Space.md,
    this.runGap = Space.sm,
  }) : super(children: [main, trailing]);

  /// Between [main] and [trailing] on one line.
  final double gap;

  /// Between [main] and [trailing] when stacked.
  final double runGap;

  @override
  RenderInlineOrStacked createRenderObject(BuildContext context) =>
      RenderInlineOrStacked(gap, runGap);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderInlineOrStacked renderObject,
  ) {
    renderObject
      ..gap = gap
      ..runGap = runGap;
  }
}

class _SlotData extends ContainerBoxParentData<RenderBox> {}

/// The render object of an [InlineOrStacked].
class RenderInlineOrStacked extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SlotData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SlotData> {
  RenderInlineOrStacked(this._gap, this._runGap);

  double _gap, _runGap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  set runGap(double v) {
    if (v == _runGap) return;
    _runGap = v;
    markNeedsLayout();
  }

  /// Whether the last layout put the trailing child under the main one.
  bool stacked = false;

  RenderBox get _main => firstChild!;
  RenderBox get _trailing => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SlotData) child.parentData = _SlotData();
  }

  bool _fits(double width) =>
      width - _gap - _trailing.getMaxIntrinsicWidth(double.infinity) >=
      _main.getMinIntrinsicWidth(double.infinity);

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _main.getMinIntrinsicWidth(height),
    _trailing.getMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _main.getMaxIntrinsicWidth(height) +
      _gap +
      _trailing.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) => _height(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _height(width);

  double _height(double width) {
    final tw = _trailing.getMaxIntrinsicWidth(double.infinity);
    if (_fits(width)) {
      return math.max(
        _main.getMinIntrinsicHeight(width - _gap - tw),
        _trailing.getMinIntrinsicHeight(tw),
      );
    }
    return _main.getMinIntrinsicHeight(width) +
        _runGap +
        _trailing.getMinIntrinsicHeight(math.min(tw, width));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final tw = math.min(_trailing.getMaxIntrinsicWidth(double.infinity), width);
    final t = _trailing.getDryLayout(BoxConstraints(maxWidth: tw));
    if (_fits(width)) {
      final m = _main.getDryLayout(BoxConstraints(maxWidth: width - _gap - tw));
      return constraints.constrain(Size(width, math.max(m.height, t.height)));
    }
    final m = _main.getDryLayout(BoxConstraints(maxWidth: width));
    return constraints.constrain(Size(width, m.height + _runGap + t.height));
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final tw = math.min(_trailing.getMaxIntrinsicWidth(double.infinity), width);
    _trailing.layout(BoxConstraints(maxWidth: tw), parentUsesSize: true);
    final mainData = _main.parentData! as _SlotData;
    final trailingData = _trailing.parentData! as _SlotData;
    stacked = !_fits(width);
    if (!stacked) {
      _main.layout(
        BoxConstraints(maxWidth: width - _gap - tw),
        parentUsesSize: true,
      );
      final h = math.max(_main.size.height, _trailing.size.height);
      mainData.offset = Offset(0, (h - _main.size.height) / 2);
      trailingData.offset = Offset(
        width - _trailing.size.width,
        (h - _trailing.size.height) / 2,
      );
      size = constraints.constrain(Size(width, h));
    } else {
      _main.layout(BoxConstraints(maxWidth: width), parentUsesSize: true);
      mainData.offset = Offset.zero;
      trailingData.offset = Offset(0, _main.size.height + _runGap);
      size = constraints.constrain(
        Size(width, _main.size.height + _runGap + _trailing.size.height),
      );
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
