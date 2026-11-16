// The bb_lints rules. Each keeps UI code on the bb_tokens scales; see the
// package README for the reasoning and the fixes.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import 'style.dart';

LintCode _code(String name, String problem, String correction) => LintCode(
  name,
  problem,
  correctionMessage: correction,
  severity: DiagnosticSeverity.WARNING,
);

/// Every rule, in the order the README lists them.
List<AnalysisRule> get warningRules => [
  TokensOnly(),
  NoRawColors(),
  NoRawTextStyle(),
  UseGap(),
  NoMaterial(),
];

/// Rules a package turns on in `analysis_options.yaml`.
List<AnalysisRule> get lintRules => [NoMagicNumbers(), NoWindowSize()];

abstract class _Rule extends AnalysisRule {
  _Rule(this.code, String description)
    : super(name: code.lowerCaseName, description: description);
  final LintCode code;

  @override
  LintCode get diagnosticCode => code;
}

/// A raw number, or a constant written outside the token library, where a
/// spacing, size, radius, stroke, opacity, type or motion value goes.
class TokensOnly extends _Rule {
  static final LintCode literal = _code(
    'tokens_only',
    "'{0}' is a raw design value.",
    'Use a bb_tokens step: Space, ControlSize, IconSize, Radii, Stroke, '
        'Alpha, Widths, Motion or a context.metrics/context.type value.',
  );

  TokensOnly()
    : super(literal, 'Style values come from bb_tokens, never from literals.');

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isInLibDir) return;
    final v = _TokensVisitor(this);
    registry
      ..addIntegerLiteral(this, v)
      ..addDoubleLiteral(this, v)
      ..addSimpleIdentifier(this, v)
      ..addPrefixedIdentifier(this, v);
  }
}

class _TokensVisitor extends SimpleAstVisitor<void> {
  _TokensVisitor(this.rule);
  final TokensOnly rule;

  void _literal(Literal node) {
    if (skipFile(node) || isNeutral(node)) return;
    if (inStylePosition(node)) {
      rule.reportAtNode(node, arguments: [node.toSource()]);
    }
  }

  void _identifier(Identifier node) {
    if (skipFile(node)) return;
    if (node is SimpleIdentifier && node.inDeclarationContext()) return;
    if (isUntokenedConstant(node) && inStylePosition(node)) {
      rule.reportAtNode(node, arguments: [node.name]);
    }
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) => _literal(node);
  @override
  void visitDoubleLiteral(DoubleLiteral node) => _literal(node);
  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final parent = node.parent;
    if (parent is PrefixedIdentifier) return;
    if (parent is PropertyAccess && parent.propertyName == node) return;
    if (parent is MethodInvocation) return;
    _identifier(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) => _identifier(node);
}

/// Any number outside a named constant or the token library. Turn it on for
/// libraries that should hold no unexplained numbers at all.
class NoMagicNumbers extends _Rule {
  static final LintCode code_ = _code(
    'no_magic_numbers',
    "'{0}' is an unnamed number.",
    'Name it with a const (or use a bb_tokens value if it is visual).',
  );

  NoMagicNumbers() : super(code_, 'Numbers have names.');

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isInLibDir) return;
    final v = _MagicVisitor(this);
    registry
      ..addIntegerLiteral(this, v)
      ..addDoubleLiteral(this, v);
  }
}

class _MagicVisitor extends SimpleAstVisitor<void> {
  _MagicVisitor(this.rule);
  final NoMagicNumbers rule;

  void _check(Literal node) {
    if (skipFile(node) || isNeutral(node)) return;
    // One is a count, a step or a whole, never a design decision.
    if (numericValue(node as Expression) == 1) return;
    if (isNamedConstant(node)) return;
    // tokens_only reports these with a better message.
    if (inStylePosition(node)) return;
    rule.reportAtNode(node, arguments: [node.toSource()]);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) => _check(node);
  @override
  void visitDoubleLiteral(DoubleLiteral node) => _check(node);
}

/// A colour written in code instead of read from the palette.
class NoRawColors extends _Rule {
  static final LintCode code_ = _code(
    'no_raw_colors',
    "'{0}' is a raw colour.",
    'Use a role from context.colors (or add one to the generated palette); '
        'for a translucent colour use an Alpha step.',
  );

  NoRawColors() : super(code_, 'Colours come from the palette.');

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isInLibDir) return;
    final v = _ColorVisitor(this);
    registry
      ..addInstanceCreationExpression(this, v)
      ..addPrefixedIdentifier(this, v)
      ..addMethodInvocation(this, v);
  }
}

class _ColorVisitor extends SimpleAstVisitor<void> {
  _ColorVisitor(this.rule);
  final NoRawColors rule;

  static const _colorTypes = {'Color', 'ColorSwatch', 'MaterialColor'};
  static const _palettes = {'Colors', 'CupertinoColors'};
  static const _alphaMethods = {'withValues', 'withOpacity', 'withAlpha'};

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (skipFile(node)) return;
    if (_colorTypes.contains(typeName(node))) {
      rule.reportAtNode(node, arguments: [node.toSource()]);
    }
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (skipFile(node)) return;
    final prefix = node.prefix.element;
    if (prefix is ClassElement && _palettes.contains(prefix.name)) {
      rule.reportAtNode(node, arguments: [node.name]);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (skipFile(node)) return;
    if (!_alphaMethods.contains(node.methodName.name)) return;
    final target = node.realTarget?.staticType;
    if (target is! InterfaceType || target.element.name != 'Color') return;
    for (final arg in node.argumentList.arguments) {
      final value = arg is NamedArgument
          ? arg.argumentExpression
          : arg as Expression;
      if (numericValue(value.unParenthesized) case final v? when v != 0) {
        rule.reportAtNode(arg, arguments: [node.toSource()]);
      }
    }
  }
}

/// A text style built by hand instead of from a TypeScale role.
class NoRawTextStyle extends _Rule {
  static final LintCode code_ = _code(
    'no_raw_text_style',
    "'{0}' sets type outside the type scale.",
    'Use ts(context.type.<role>, colour) or tsDisplay(...), and Weight for '
        'a different weight.',
  );

  NoRawTextStyle() : super(code_, 'Type comes from the type scale.');

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isInLibDir) return;
    final v = _TextVisitor(this);
    registry
      ..addInstanceCreationExpression(this, v)
      ..addPrefixedIdentifier(this, v)
      ..addMethodInvocation(this, v);
  }
}

class _TextVisitor extends SimpleAstVisitor<void> {
  _TextVisitor(this.rule);
  final NoRawTextStyle rule;

  static const _types = {'TextStyle', 'StrutStyle'};
  static const _typeArgs = {
    'fontSize',
    'fontWeight',
    'height',
    'letterSpacing',
    'wordSpacing',
    'fontFamily',
  };

  /// A style that only colours, highlights or italicises a span is fine;
  /// one that sets size, weight, leading, family or tracking is type.
  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (skipFile(node)) return;
    if (!_types.contains(typeName(node))) return;
    final setsType = node.argumentList.arguments.any(
      (a) => a is NamedArgument && _typeArgs.contains(a.name.lexeme),
    );
    if (setsType) {
      rule.reportAtNode(node.constructorName, arguments: [typeName(node)!]);
    }
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (skipFile(node)) return;
    final prefix = node.prefix.element;
    if (prefix is ClassElement && prefix.name == 'FontWeight') {
      rule.reportAtNode(node, arguments: [node.name]);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (skipFile(node)) return;
    if (node.methodName.name != 'copyWith') return;
    final target = node.realTarget?.staticType;
    if (target is! InterfaceType || target.element.name != 'TextStyle') return;
    for (final arg in node.argumentList.arguments) {
      if (arg is NamedArgument && _typeArgs.contains(arg.name.lexeme)) {
        rule.reportAtNode(arg, arguments: [arg.name.lexeme]);
      }
    }
  }
}

/// A `SizedBox` used only as a gap between the children of a row, column or
/// list.
class UseGap extends _Rule {
  static final LintCode code_ = _code(
    'use_gap',
    'A SizedBox used as a gap.',
    "Use Gap(Space.<step>), or the parent's spacing: when every gap is equal.",
  );

  UseGap() : super(code_, 'Gaps are Gap widgets or Flex spacing.');

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isInLibDir) return;
    registry.addInstanceCreationExpression(this, _GapVisitor(this));
  }
}

/// Whether [node] is `SizedBox(width: x)` or `SizedBox(height: x)` with no
/// child, as an element of a `children:` list.
bool isSpacerBox(InstanceCreationExpression node) {
  if (typeName(node) != 'SizedBox' || node.constructorName.name != null) {
    return false;
  }
  final args = node.argumentList.arguments;
  if (args.length != 1) return false;
  final arg = args.single;
  if (arg is! NamedArgument) return false;
  final name = arg.name.lexeme;
  if (name != 'width' && name != 'height') return false;
  AstNode? n = node.parent;
  while (n is IfElement || n is SpreadElement || n is ListLiteral) {
    if (n is ListLiteral && n.parent is NamedArgument) {
      final label = (n.parent! as NamedArgument).name.lexeme;
      return label == 'children';
    }
    n = n?.parent;
  }
  return false;
}

class _GapVisitor extends SimpleAstVisitor<void> {
  _GapVisitor(this.rule);
  final UseGap rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (skipFile(node)) return;
    if (isSpacerBox(node)) rule.reportAtNode(node);
  }
}

/// Reading the window's size inside a component. Components lay out by their
/// own constraints: `context.sizeClass`, `AdaptiveLayout` or `LayoutBuilder`.
class NoWindowSize extends _Rule {
  static final LintCode code_ = _code(
    'no_window_size',
    'A component reads the window size.',
    'Use context.sizeClass, AdaptiveLayout or LayoutBuilder; a route that '
        'really positions against the screen can ignore this with a reason.',
  );

  NoWindowSize() : super(code_, 'Components lay out by their constraints.');

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isInLibDir) return;
    final v = _WindowVisitor(this);
    registry
      ..addMethodInvocation(this, v)
      ..addPropertyAccess(this, v)
      ..addPrefixedIdentifier(this, v);
  }
}

class _WindowVisitor extends SimpleAstVisitor<void> {
  _WindowVisitor(this.rule);
  final NoWindowSize rule;

  static const _methods = {'sizeOf', 'maybeSizeOf'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (skipFile(node)) return;
    final target = node.target;
    if (target is SimpleIdentifier &&
        target.name == 'MediaQuery' &&
        _methods.contains(node.methodName.name)) {
      rule.reportAtNode(node);
    }
  }

  void _size(AstNode node, Expression? target, String property) {
    if (property != 'size') return;
    final type = target?.staticType;
    if (type is InterfaceType && type.element.name == 'MediaQueryData') {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (skipFile(node)) return;
    _size(node, node.realTarget, node.propertyName.name);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (skipFile(node)) return;
    _size(node, node.prefix, node.identifier.name);
  }
}

/// Importing Material or Cupertino, which the kit does not use.
class NoMaterial extends _Rule {
  static final LintCode code_ = _code(
    'no_material',
    "'{0}' brings in another design system.",
    "Import 'package:flutter/widgets.dart' and use bb_ui components.",
  );

  NoMaterial() : super(code_, 'Only bb_ui, no Material or Cupertino.');

  static const _banned = {
    'package:flutter/material.dart',
    'package:flutter/cupertino.dart',
  };

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isInLibDir) return;
    registry.addImportDirective(this, _ImportVisitor(this));
  }
}

class _ImportVisitor extends SimpleAstVisitor<void> {
  _ImportVisitor(this.rule);
  final NoMaterial rule;

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    if (uri != null && NoMaterial._banned.contains(uri)) {
      rule.reportAtNode(node.uri, arguments: [uri]);
    }
  }
}
