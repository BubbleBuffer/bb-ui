// IDE quick fixes for the mechanical cases. Bulk changes go through
// `dart run bb_lints:migrate`, because plugin fixes apply one at a time.

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'mapping.dart';
import 'rules.dart';

void registerFixes(PluginRegistry registry) {
  registry
    ..registerFixForRule(TokensOnly.literal, UseToken.new)
    ..registerFixForRule(UseGap.code_, ToGap.new);
}

/// Replaces a raw spacing, radius, stroke or alpha with its nearest step.
class UseToken extends ResolvedCorrectionProducer {
  UseToken({required super.context});

  static const _kind = FixKind(
    'bb_lints.fix.useToken',
    DartFixKindPriority.standard,
    "Replace with '{0}'",
  );

  String _token = '';

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _kind;

  @override
  List<String> get fixArguments => [_token];

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final literal = node;
    if (literal is! Literal) return;
    final token = tokenFor(literal);
    if (token == null) return;
    _token = token;
    await builder.addDartFileEdit(file, (b) {
      b.addSimpleReplacement(range.node(literal), token);
    });
  }
}

/// `SizedBox(width: 8)` between children becomes `Gap(Space.sm)`.
class ToGap extends ResolvedCorrectionProducer {
  ToGap({required super.context});

  static const _kind = FixKind(
    'bb_lints.fix.toGap',
    DartFixKindPriority.standard,
    'Replace with Gap',
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  FixKind get fixKind => _kind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final box = node.thisOrAncestorOfType<InstanceCreationExpression>();
    if (box == null || !isSpacerBox(box)) return;
    final text = gapSource(box);
    await builder.addDartFileEdit(file, (b) {
      b.addSimpleReplacement(range.node(box), text);
    });
  }
}

/// The `Gap(...)` that replaces spacer [box], with a literal mapped to its
/// step.
String gapSource(InstanceCreationExpression box) {
  final arg = box.argumentList.arguments.single as NamedArgument;
  final value = arg.argumentExpression;
  final token = value is Literal ? tokenFor(value) : null;
  final keyword = box.keyword?.lexeme == 'const' ? 'const ' : '';
  return '${keyword}Gap(${token ?? value.toSource()})';
}
