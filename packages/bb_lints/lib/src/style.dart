// What counts as a style position and as a token, shared by the rules and
// the migrate tool.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// Types whose constructor arguments are all visual: every number passed to
/// them is a spacing, size, radius, stroke, opacity or type value.
const styleTypes = {
  'EdgeInsets',
  'EdgeInsetsDirectional',
  'SizedBox',
  'Gap',
  'Radius',
  'BorderRadius',
  'BorderRadiusDirectional',
  'BorderSide',
  'Border',
  'BoxConstraints',
  'Size',
  'TextStyle',
  'StrutStyle',
  'BoxShadow',
  'Shadow',
  'BoxDecoration',
  'ShapeDecoration',
  'RoundedRectangleBorder',
  'ContinuousRectangleBorder',
  'StadiumBorder',
  'CircleBorder',
  'OutlineInputBorder',
  'UnderlineInputBorder',
  'IconThemeData',
  'FontVariation',
};

/// Named arguments that carry a visual value on any widget or style object.
const styleArgNames = {
  'width',
  'height',
  'size',
  'dimension',
  'spacing',
  'runSpacing',
  'padding',
  'margin',
  'radius',
  'borderRadius',
  'elevation',
  'gap',
  'indent',
  'endIndent',
  'thickness',
  'strokeWidth',
  'stroke',
  'fontSize',
  'letterSpacing',
  'wordSpacing',
  'iconSize',
  'glyph',
  'itemExtent',
  'minWidth',
  'maxWidth',
  'minHeight',
  'maxHeight',
  'left',
  'top',
  'right',
  'bottom',
  'start',
  'end',
  'duration',
  'reverseDuration',
  'transitionDuration',
  'reverseTransitionDuration',
  'opacity',
  'alpha',
  'blurRadius',
  'spreadRadius',
  'labelWidth',
  'extent',
};

/// Whether [uri] is a library allowed to hold raw design values: the
/// bb_tokens package, or an app's own `tokens.dart`, `*_tokens.dart` or
/// `tokens/` folder.
bool isTokenSource(Uri uri) {
  final path = uri.path;
  if (uri.scheme == 'package' && path.startsWith('bb_tokens/')) return true;
  final name = path.split('/').last;
  return name == 'tokens.dart' ||
      name.endsWith('_tokens.dart') ||
      path.contains('/tokens/');
}

/// Whether [path] is generated code, which no rule checks.
bool isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('.gr.dart');

/// The library [node] is in, or null before resolution.
Uri? unitUri(AstNode node) {
  final unit = node.thisOrAncestorOfType<CompilationUnit>();
  return unit?.declaredFragment?.source.uri;
}

/// Whether rules should skip [node]'s file entirely.
bool skipFile(AstNode node) {
  final uri = unitUri(node);
  if (uri == null) return true;
  return isTokenSource(uri) || isGenerated(uri.path);
}

String? typeName(InstanceCreationExpression node) =>
    node.constructorName.type.element?.name;

bool _isNamed(DartType? type, Set<String> names) {
  if (type is! InterfaceType) return false;
  if (names.contains(type.element.name)) return true;
  return type.element.allSupertypes.any((t) => names.contains(t.element.name));
}

/// Whether [type] is a Flutter widget.
bool isWidget(DartType? type) => _isNamed(type, const {'Widget'});

/// Whether [type] is one of [styleTypes] or extends one.
bool isStyleType(DartType? type) => _isNamed(type, styleTypes);

/// The parameter or argument name that [node] is passed as, if any.
String? argName(Expression node) {
  final p = node.parent;
  return p is NamedArgument ? p.name.lexeme : null;
}

/// Climbs from a value to the argument it is part of and decides whether that
/// argument is visual. Arithmetic, conditionals, parentheses and negation
/// pass through: `(gap + 4) / 2` is as much a style value as `4`.
bool inStylePosition(Expression value) {
  AstNode node = value;
  String? name;
  while (true) {
    final parent = node.parent;
    switch (parent) {
      case ParenthesizedExpression() ||
          PrefixExpression() ||
          BinaryExpression() ||
          ConditionalExpression() ||
          AsExpression():
        if (parent is ConditionalExpression && node == parent.condition) {
          return false;
        }
        node = parent!;
      case NamedArgument():
        name = parent.name.lexeme;
        node = parent;
      case ArgumentList():
        final owner = parent.parent;
        if (owner is InstanceCreationExpression) {
          if (styleTypes.contains(typeName(owner))) return true;
          return name != null &&
              styleArgNames.contains(name) &&
              (isWidget(owner.staticType) || isStyleType(owner.staticType));
        }
        if (owner is MethodInvocation) {
          if (owner.methodName.name == 'copyWith' &&
              isStyleType(owner.realTarget?.staticType)) {
            return true;
          }
          return name != null &&
              styleArgNames.contains(name) &&
              (isWidget(owner.staticType) ||
                  isStyleType(owner.staticType) ||
                  _fromUiLibrary(owner.methodName.element));
        }
        return false;
      case AssignmentExpression(:final leftHandSide, :final rightHandSide)
          when rightHandSide == node:
        // `..strokeWidth = 2` on a Paint, or `box.width = 8`.
        final target = switch (leftHandSide) {
          PropertyAccess(:final propertyName) => propertyName.name,
          PrefixedIdentifier(:final identifier) => identifier.name,
          SimpleIdentifier(:final name) => name,
          _ => null,
        };
        return target != null && styleArgNames.contains(target);
      case FormalParameterDefaultClause(parent: FormalParameter param):
        // A widget constructor's default: `this.height = 42`.
        final paramName = param.name?.lexeme;
        final cls = parent.thisOrAncestorOfType<ClassDeclaration>();
        final type = cls?.declaredFragment?.element.thisType;
        return paramName != null &&
            styleArgNames.contains(paramName) &&
            (isWidget(type) || isStyleType(type));
      default:
        return false;
    }
  }
}

/// The literal's value, or null for a non-numeric node.
num? numericValue(Expression node) => switch (node) {
  IntegerLiteral(:final value) => value,
  DoubleLiteral(:final value) => value,
  _ => null,
};

/// Literals that never carry a design decision: zero always, and one or two
/// as an operand of arithmetic with a non-literal (`width / 2`, `i + 1`).
bool isNeutral(Expression literal) {
  final v = numericValue(literal);
  if (v == null || v == 0) return true;
  final parent = literal.parent;
  if (parent is PrefixExpression &&
      parent.operator.type == TokenType.MINUS &&
      v == 1) {
    return true;
  }
  if ((v == 1 || v == 2) && parent is BinaryExpression) {
    final other = parent.leftOperand == literal
        ? parent.rightOperand
        : parent.leftOperand;
    return numericValue(other.unParenthesized) == null;
  }
  return false;
}

/// Whether [literal] sits in a named constant's initializer
/// (`const x = ...`, `static const x = ...`), in an annotation or as an
/// index.
bool isNamedConstant(Expression literal) {
  for (AstNode? n = literal.parent; n != null; n = n.parent) {
    if (n is VariableDeclarationList) return n.isConst;
    if (n is Annotation) return true;
    if (n is IndexExpression) return true;
    if (n is FunctionBody || n is ClassMember && n is! FieldDeclaration) {
      return false;
    }
  }
  return false;
}

/// For an identifier in a style position: whether it names a number that was
/// written outside the token library (`const _pad = 10`, a static constant
/// in a widget, or a local `final gap = 6`).
bool isUntokenedConstant(Identifier node) {
  final element = node.element;
  final PropertyInducingElement? variable = switch (element) {
    GetterElement(:final variable) => variable,
    PropertyInducingElement() => element,
    _ => null,
  };
  if (variable != null) {
    if (!variable.isConst) return false;
    if (!_isNumber(variable.type)) return false;
    final uri = variable.library.uri;
    if (isTokenSource(uri) || uri.isScheme('dart') || _isSdk(uri)) {
      return false;
    }
    return _hasRawNumber(_initializerOf(node, variable));
  }
  if (element is LocalVariableElement && _isNumber(element.type)) {
    return _hasRawNumber(_initializerOf(node, element), missing: false);
  }
  return false;
}

/// Whether [init] writes a number of its own rather than naming tokens
/// (`const _gap = Space.xxs` is an alias; `const _gap = 4.0` is not). A
/// declaration in another file is not visible here and counts as raw.
bool _hasRawNumber(Expression? init, {bool missing = true}) {
  if (init == null) return missing;
  final finder = _RawNumber();
  init.accept(finder);
  return finder.found;
}

class _RawNumber extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitIntegerLiteral(IntegerLiteral node) => found |= !isNeutral(node);

  @override
  void visitDoubleLiteral(DoubleLiteral node) => found |= !isNeutral(node);
}

final _initializers = Expando<Map<Element, Expression?>>();

/// The initializer of [variable] if it is declared in [node]'s file.
Expression? _initializerOf(AstNode node, Element variable) {
  final unit = node.thisOrAncestorOfType<CompilationUnit>();
  if (unit == null) return null;
  final map = _initializers[unit] ??= () {
    final collector = _LocalInit();
    unit.accept(collector);
    return collector.found;
  }();
  return map[variable.baseElement];
}

/// Whether [element] is declared by Flutter or the kit, whose functions take
/// visual arguments (`showModalPanel(width: ...)`, `showToast(duration:)`).
bool _fromUiLibrary(Element? element) {
  final uri = element?.library?.uri;
  if (uri == null || !uri.isScheme('package')) return false;
  final path = uri.path;
  return path.startsWith('flutter/') ||
      path.startsWith('bb_ui/') ||
      path.startsWith('bb_tokens/') ||
      path.startsWith('agent_kit/');
}

bool _isSdk(Uri uri) =>
    uri.isScheme('package') &&
    (uri.path.startsWith('flutter/') || uri.path.startsWith('vector_math/'));

bool _isNumber(DartType type) =>
    type.isDartCoreDouble || type.isDartCoreInt || type.isDartCoreNum;

class _LocalInit extends RecursiveAstVisitor<void> {
  final found = <Element, Expression?>{};

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element != null) found[element.baseElement] = node.initializer;
    super.visitVariableDeclaration(node);
  }
}
