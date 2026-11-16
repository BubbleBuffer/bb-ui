// Layout primitives that keep spacing on the scale and let a component adapt
// to its own width: Gap and AdaptiveLayout.

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
