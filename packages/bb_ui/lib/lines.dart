// Hairlines.

import 'package:flutter/widgets.dart';

import 'tokens.dart';

class HLine extends StatelessWidget {
  const HLine({super.key, this.color, this.indent = 0});
  final Color? color;
  final double indent;
  @override
  Widget build(BuildContext context) => Container(
    height: Stroke.hair,
    margin: EdgeInsets.symmetric(horizontal: indent),
    color: color ?? context.colors.borderSubtle,
  );
}

class VLine extends StatelessWidget {
  const VLine({super.key, this.height = Sizes.rule});
  final double height;
  @override
  Widget build(BuildContext context) => Container(
    width: Stroke.hair,
    height: height,
    margin: const EdgeInsets.symmetric(horizontal: Space.hair),
    color: context.colors.border,
  );
}
