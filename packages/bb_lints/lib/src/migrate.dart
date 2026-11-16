// The bulk rewrite behind `dart run bb_lints:migrate`. It resolves every
// library under a directory and applies the mechanical parts of the 0.8
// migration; what needs judgement is left for the analyzer rules to flag.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import 'fixes.dart' show gapSource;
import 'mapping.dart';
import 'rules.dart' show isSpacerBox;
import 'style.dart';

/// One text replacement in a file.
class Edit {
  Edit(this.offset, this.length, this.text);
  final int offset, length;
  final String text;
  int get end => offset + length;
}

/// Options for a run.
class MigrateOptions {
  const MigrateOptions({
    this.typeScale = 'TypeScale.pointer',
    this.import = 'package:bb_ui/bb_ui.dart',
    this.dryRun = false,
  });

  /// The expression type roles are read from, for example `context.type`.
  final String typeScale;

  /// The import added to a library that needs a token it cannot see.
  final String? import;
  final bool dryRun;
}

/// Rewrites every library under [root]; returns the changed paths.
Future<List<String>> migrate(String root, MigrateOptions options) async {
  final collection = AnalysisContextCollection(
    includedPaths: [
      Directory(root).absolute.uri
          .normalizePath()
          .toFilePath()
          .replaceFirst(RegExp(r'/$'), ''),
    ],
  );
  final changed = <String>[];
  for (final context in collection.contexts) {
    for (final path in context.contextRoot.analyzedFiles()) {
      if (!path.endsWith('.dart') || !path.contains('/lib/')) continue;
      if (isGenerated(path)) continue;
      final result = await context.currentSession.getResolvedUnit(path);
      if (result is! ResolvedUnitResult) continue;
      final uri = result.unit.declaredFragment?.source.uri;
      if (uri != null && isTokenSource(uri)) continue;
      final edits = collectEdits(result.unit, options);
      if (edits.isEmpty) continue;
      var source = applyEdits(result.content, edits);
      source = _ensureImport(source, result.unit, options);
      if (!options.dryRun) File(path).writeAsStringSync(source);
      changed.add(path);
    }
  }
  return changed;
}

/// The edits for one unit, outermost first, without overlaps.
List<Edit> collectEdits(CompilationUnit unit, MigrateOptions options) {
  final v = _Collector(options);
  unit.accept(v);
  final edits = v.edits..sort((a, b) => a.offset.compareTo(b.offset));
  final kept = <Edit>[];
  for (final e in edits) {
    if (kept.isNotEmpty && e.offset < kept.last.end) {
      // Nested in an earlier, larger edit (a literal inside a replaced
      // SizedBox): the outer one already rewrote it.
      if (e.end <= kept.last.end && e.length < kept.last.length) continue;
      if (e.length > kept.last.length) {
        kept.removeLast();
      } else {
        continue;
      }
    }
    kept.add(e);
  }
  return kept;
}

String applyEdits(String source, List<Edit> edits) {
  final b = StringBuffer();
  var at = 0;
  for (final e in edits) {
    b
      ..write(source.substring(at, e.offset))
      ..write(e.text);
    at = e.end;
  }
  b.write(source.substring(at));
  return b.toString();
}

const _newNames = [
  'Space.',
  'Radii.',
  'Stroke.',
  'Alpha.',
  'Weight.',
  'Gap(',
  'IconSize.',
  'ControlSize.',
];

String _ensureImport(String source, CompilationUnit unit, MigrateOptions o) {
  final import = o.import;
  if (import == null) return source;
  final uri = unit.declaredFragment?.source.uri;
  if (uri == null || !uri.isScheme('package')) return source;
  // Libraries of bb_ui itself import the tokens relatively.
  if (uri.path.startsWith('bb_ui/') || uri.path.startsWith('bb_tokens/')) {
    return source;
  }
  if (!_newNames.any(source.contains)) return source;
  final imports = unit.directives.whereType<ImportDirective>().map(
    (d) => d.uri.stringValue ?? '',
  );
  // agent_kit does not re-export the tokens, so only these count.
  if (imports.any(
    (u) => u.startsWith('package:bb_ui/') || u.startsWith('package:bb_tokens/'),
  )) {
    return source;
  }
  final last = unit.directives.whereType<ImportDirective>().lastOrNull;
  final line = "import '$import';\n";
  if (last == null) return line + source;
  return source.replaceRange(last.end + 1, last.end + 1, line);
}

/// Roles of the pointer ramp: name, size, line height, weight axis.
const _roles = [
  ('pageTitle', 40.0, 48.0, 700),
  ('display', 32.0, 34.0, 700),
  ('h1', 30.0, 39.0, 600),
  ('h2', 24.0, 31.2, 600),
  ('h3', 20.0, 26.0, 600),
  ('title', 16.0, 20.0, 640),
  ('body', 16.0, 24.0, 400),
  ('ui', 14.0, 20.0, 500),
  ('uiSmall', 12.0, 16.0, 500),
  ('caption', 11.0, 15.0, 400),
  ('micro', 10.0, 12.0, 600),
  ('code', 13.6, 20.4, 400),
  ('codeSmall', 12.0, 16.0, 400),
];

/// How far a written size may sit from a step and still snap to it.
const _snapTolerance = 4.0;

bool _nearStep(double v) => [
  ..._iconSizes,
  ..._controlSizes,
].any((s) => (s.$1 - v).abs() <= _snapTolerance);

const _iconWidgets = {'Icon20', 'Spinner'};
const _iconButtons = {'IconBtn', 'CopyButton'};
const _buttons = {'PrimaryButton', 'SecondaryButton', 'TextBtn'};
const _iconSizes = [
  (14.0, 'IconSize.xs'),
  (16.0, 'IconSize.sm'),
  (18.0, 'IconSize.md'),
  (20.0, 'IconSize.lg'),
  (24.0, 'IconSize.xl'),
  (28.0, 'IconSize.xxl'),
];
const _controlSizes = [
  (24.0, 'ControlSize.xs'),
  (28.0, 'ControlSize.sm'),
  (32.0, 'ControlSize.md'),
  (36.0, 'ControlSize.lg'),
  (44.0, 'ControlSize.xl'),
  (48.0, 'ControlSize.xxl'),
];

const _weights = [
  (400, 'Weight.regular'),
  (500, 'Weight.medium'),
  (600, 'Weight.semibold'),
  (640, 'Weight.display'),
  (700, 'Weight.bold'),
];

/// The role nearest a hand-written size and line height; a monospace style
/// may also take the code roles.
(String, int) roleFor(
  double size,
  double line, {
  required bool mono,
  num weight = 400,
}) {
  var best = _roles.first;
  var bestScore = double.infinity;
  for (final r in _roles) {
    if (!mono && (r.$1 == 'code' || r.$1 == 'codeSmall')) continue;
    final code = r.$1 == 'code' || r.$1 == 'codeSmall';
    final score =
        (r.$2 - size).abs() * 4 +
        (r.$3 - line).abs() +
        (r.$4 - weight).abs() / 100 -
        (mono && code ? 1 : 0);
    if (score < bestScore || (score == bestScore && r.$2 > best.$2)) {
      best = r;
      bestScore = score;
    }
  }
  return (best.$1, best.$4);
}

String weightFor(num w) {
  var best = _weights.first;
  for (final x in _weights) {
    if ((x.$1 - w).abs() < (best.$1 - w).abs()) best = x;
  }
  return best.$2;
}

class _Collector extends RecursiveAstVisitor<void> {
  _Collector(this.o);
  final MigrateOptions o;
  final edits = <Edit>[];

  void _replace(AstNode node, String text) =>
      edits.add(Edit(node.offset, node.length, text));

  void _literal(Literal node) {
    if (isNeutral(node)) return;
    final token = tokenFor(node);
    if (token == null) return;
    final colorAlpha = kindOf(node) == StyleKind.alpha && _onColor(node);
    if (inStylePosition(node) || colorAlpha) _replace(node, token);
  }

  bool _onColor(Expression node) {
    final call = node.thisOrAncestorOfType<MethodInvocation>();
    final t = call?.realTarget?.staticType;
    return t is InterfaceType && t.element.name == 'Color';
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _literal(node);
    super.visitIntegerLiteral(node);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _literal(node);
    super.visitDoubleLiteral(node);
  }

  /// bb_ui 0.8 sizes components by step, not by number.
  void _componentSizes(InstanceCreationExpression node) {
    final type = typeName(node);
    for (final a in node.argumentList.arguments) {
      if (a is! NamedArgument) continue;
      final value = numericValue(a.argumentExpression);
      if (value == null) continue;
      final name = a.name.lexeme;
      final v = value.toDouble();
      // A size far from every step is a one-off (an illustration, a hero
      // glyph): leave it for a person, and the rules, to decide.
      if (!_nearStep(v)) continue;
      String? replacement;
      if (_iconWidgets.contains(type) && name == 'size') {
        replacement = 'size: ${nearest(_iconSizes, v)}';
      } else if (_iconButtons.contains(type) && name == 'size') {
        replacement = 'size: ${nearest(_controlSizes, v)}';
      } else if (_iconButtons.contains(type) && name == 'glyph') {
        replacement = 'glyph: ${nearest(_iconSizes, v)}';
      } else if (_buttons.contains(type) && name == 'height') {
        replacement = 'size: ${nearest(_controlSizes, v)}';
      }
      if (replacement != null) _replace(a, replacement);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _componentSizes(node);
    if (isSpacerBox(node)) {
      _replace(node, gapSource(node));
    } else if (typeName(node) == 'TypeSpec') {
      _typeSpec(node);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    final args = node.argumentList.arguments;
    if (node.target == null && name == 'tsRaw' && args.length == 4) {
      _tsRaw(node);
    } else if (node.target == null && name == 'fw' && args.length == 1) {
      final w = numericValue(args.single as Expression);
      if (w != null) _replace(node, '${weightFor(w)}.fontWeight');
    } else if (node.target == null && (name == 'ts' || name == 'tsDisplay')) {
      for (final a in args) {
        if (a is NamedArgument && a.name.lexeme == 'weight') {
          final w = numericValue(a.argumentExpression);
          if (w != null) _replace(a.argumentExpression, weightFor(w));
        }
      }
    }
    super.visitMethodInvocation(node);
  }

  void _tsRaw(MethodInvocation node) {
    final args = node.argumentList.arguments;
    final size = numericValue(args[0] as Expression);
    final line = numericValue(args[1] as Expression);
    final weight = numericValue(args[2] as Expression);
    if (size == null || line == null || weight == null) return;
    final (role, roleWeight) = roleFor(
      size.toDouble(),
      line.toDouble(),
      mono: false,
      weight: weight,
    );
    final color = (args[3] as Expression).toSource();
    final w = weight == roleWeight ? '' : ', weight: ${weightFor(weight)}';
    _replace(node, 'ts(${o.typeScale}.$role, $color$w)');
  }

  void _typeSpec(InstanceCreationExpression node) {
    final args = node.argumentList.arguments;
    if (args.length != 3) return;
    final size = numericValue(args[0] as Expression);
    final line = numericValue(args[1] as Expression);
    final weight = numericValue(args[2] as Expression);
    if (size == null || line == null || weight == null) return;
    final call = node.parent?.parent;
    // Monospace if the style it feeds says so, or the constant it is named
    // by does (`const mono = TypeSpec(...)`, `codeSpec`).
    final declared = node.thisOrAncestorOfType<VariableDeclaration>();
    final namedMono =
        declared != null &&
        RegExp(
          'mono|code',
          caseSensitive: false,
        ).hasMatch(declared.name.lexeme);
    final mono =
        namedMono ||
        call is MethodInvocation &&
            call.argumentList.arguments.any(
              (a) =>
                  a is NamedArgument &&
                  a.name.lexeme == 'mono' &&
                  a.argumentExpression.toSource() == 'true',
            );
    final (role, roleWeight) = roleFor(
      size.toDouble(),
      line.toDouble(),
      mono: mono,
      weight: weight,
    );
    _replace(node, '${o.typeScale}.$role');
    // Keep the written weight when the role's differs and the call has none.
    if (weight != roleWeight &&
        call is MethodInvocation &&
        (call.methodName.name == 'ts' || call.methodName.name == 'tsDisplay') &&
        call.argumentList.arguments.first == node &&
        !call.argumentList.arguments.any(
          (a) => a is NamedArgument && a.name.lexeme == 'weight',
        )) {
      final close = call.argumentList.rightParenthesis.offset;
      final args = call.argumentList.arguments;
      final trailingComma = args.last.endToken.next?.lexeme == ',';
      final sep = trailingComma ? ' ' : ', ';
      edits.add(Edit(close, 0, '${sep}weight: ${weightFor(weight)}'));
    }
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _rename(node, node.prefix, node.identifier.name);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _rename(node, node.realTarget, node.propertyName.name);
    super.visitPropertyAccess(node);
  }

  void _rename(AstNode node, Expression target, String property) {
    final type = target.staticType;
    final targetName = type is InterfaceType ? type.element.name : null;
    if (property == 'mobile' && targetName == 'BuildContext') {
      _replace(node, '${target.toSource()}.touch');
    } else if (target is SimpleIdentifier && target.name == 'TypeScale') {
      if (property == 'desktop') _replace(node, 'TypeScale.pointer');
      if (property == 'mobile') _replace(node, 'TypeScale.touch');
    }
  }
}
