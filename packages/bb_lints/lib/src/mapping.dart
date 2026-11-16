// Which bb_tokens step replaces a raw value. Shared by the IDE quick fixes
// and `dart run bb_lints:migrate`.

import 'package:analyzer/dart/ast/ast.dart';

import 'rules.dart' show isSpacerBox;
import 'style.dart';

/// The kind of design value a literal is, judged by where it is passed.
enum StyleKind { spacing, radius, stroke, alpha }

const _space = [
  (2.0, 'Space.hair'),
  (4.0, 'Space.xxs'),
  (6.0, 'Space.xs'),
  (8.0, 'Space.sm'),
  (12.0, 'Space.md'),
  (16.0, 'Space.lg'),
  (24.0, 'Space.xl'),
  (32.0, 'Space.xxl'),
  (48.0, 'Space.xxxl'),
];
const _radius = [
  (4.0, 'Radii.sm'),
  (6.0, 'Radii.md'),
  (10.0, 'Radii.lg'),
  (12.0, 'Radii.sheet'),
];
const _stroke = [
  (1.0, 'Stroke.hair'),
  (1.5, 'Stroke.regular'),
  (2.0, 'Stroke.bold'),
  (3.0, 'Stroke.seam'),
];
const _alpha = [
  (0.12, 'Alpha.tint'),
  (0.35, 'Alpha.wash'),
  (0.5, 'Alpha.muted'),
  (0.9, 'Alpha.strong'),
];

/// Largest raw value treated as spacing; wider values are layout sizes that
/// need a named token by hand.
const maxSpacing = 64.0;

/// The step nearest to [value]; a tie goes to the larger step.
String nearest(List<(double, String)> steps, double value) {
  var best = steps.first;
  for (final step in steps) {
    final d = (step.$1 - value).abs(), b = (best.$1 - value).abs();
    if (d < b || (d == b && step.$1 > best.$1)) best = step;
  }
  return best.$2;
}

const _spacingArgs = {
  'spacing',
  'runSpacing',
  'gap',
  'indent',
  'endIndent',
  'padding',
  'margin',
};
const _spacingTypes = {'EdgeInsets', 'EdgeInsetsDirectional', 'Gap'};
const _radiusTypes = {'Radius', 'BorderRadius', 'BorderRadiusDirectional'};
const _strokeArgs = {'strokeWidth', 'thickness', 'stroke'};
const _strokeTypes = {'BorderSide', 'Border'};

/// What kind of value [literal] is, or null when it is not one the tool can
/// map (a width, a height, a duration...).
StyleKind? kindOf(Expression literal) {
  String? name;
  for (AstNode? n = literal.parent; n != null; n = n.parent) {
    if (n is NamedArgument) {
      name ??= n.name.lexeme;
      continue;
    }
    if (n is PrefixExpression || n is ParenthesizedExpression) continue;
    if (n is ConditionalExpression) continue;
    if (n is ArgumentList) {
      final owner = n.parent;
      final type = owner is InstanceCreationExpression ? typeName(owner) : null;
      if (owner is InstanceCreationExpression && isSpacerBox(owner)) {
        return StyleKind.spacing;
      }
      if (_spacingTypes.contains(type)) return StyleKind.spacing;
      if (_radiusTypes.contains(type)) return StyleKind.radius;
      if (_strokeTypes.contains(type) && name == 'width') {
        return StyleKind.stroke;
      }
      if (name == null) return null;
      if (_spacingArgs.contains(name)) return StyleKind.spacing;
      if (name == 'radius') return StyleKind.radius;
      if (_strokeArgs.contains(name)) return StyleKind.stroke;
      if (name == 'alpha' || name == 'opacity') return StyleKind.alpha;
      return null;
    }
    return null;
  }
  return null;
}

/// The token source that replaces [literal], or null when there is no
/// mechanical answer.
String? tokenFor(Expression literal) {
  final value = numericValue(literal)?.toDouble();
  if (value == null) return null;
  // A leading minus stays in the source; only the magnitude is replaced.
  return switch (kindOf(literal)) {
    StyleKind.spacing when value <= maxSpacing => nearest(_space, value),
    StyleKind.radius when value < 999 => nearest(_radius, value),
    StyleKind.stroke => nearest(_stroke, value),
    StyleKind.alpha => nearest(_alpha, value),
    _ => null,
  };
}
