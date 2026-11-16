// Test methods follow test_reflective_loader's test_ naming.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart' // ignore: implementation_imports
    show ExpectedDiagnostic;
import 'package:bb_lints/src/rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TokensOnlyTest);
    defineReflectiveTests(NoMagicNumbersTest);
    defineReflectiveTests(NoRawColorsTest);
    defineReflectiveTests(NoRawTextStyleTest);
    defineReflectiveTests(UseGapTest);
    defineReflectiveTests(NoWindowSizeTest);
    defineReflectiveTests(NoMaterialTest);
  });
}

/// Shared set-up: the mock Flutter package and a small bb_tokens.
abstract class _RuleTest extends AnalysisRuleTest {
  AnalysisRule get subject;

  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = subject;
    newPackage('bb_ui').addFile('lib/bb_ui.dart', r'''
Future<void> showModalPanel({double width = 0}) async {}
''');
    newPackage('bb_tokens').addFile('lib/bb_tokens.dart', r'''
abstract final class Space {
  static const double sm = 8;
  static const double md = 12;
}
''');
    super.setUp();
  }

  /// A lint on the first [needle] in [code] (after [after], if given).
  ExpectedDiagnostic at(String code, String needle, {String? after}) {
    final from = after == null ? 0 : code.indexOf(after);
    return lint(code.indexOf(needle, from), needle.length);
  }
}

@reflectiveTest
class TokensOnlyTest extends _RuleTest {
  @override
  AnalysisRule get subject => TokensOnly();

  Future<void> test_literalPadding() async {
    const code = r'''
import 'package:flutter/widgets.dart';
Widget f() => const Padding(padding: EdgeInsets.all(10), child: Text(''));
''';
    await assertDiagnostics(code, [at(code, '10')]);
  }

  Future<void> test_tokenPadding() async {
    await assertNoDiagnostics(r'''
import 'package:bb_tokens/bb_tokens.dart';
import 'package:flutter/widgets.dart';
Widget f() =>
    const Padding(padding: EdgeInsets.all(Space.md), child: Text(''));
''');
  }

  Future<void> test_widgetSizeArgument() async {
    const code = r'''
import 'package:flutter/widgets.dart';
Widget f() => const SizedBox(width: 120, child: Text(''));
''';
    await assertDiagnostics(code, [at(code, '120')]);
  }

  Future<void> test_constantOutsideTokens() async {
    const code = r'''
import 'package:flutter/widgets.dart';
const _pad = 10.0;
Widget f() => const Padding(padding: EdgeInsets.all(_pad), child: Text(''));
''';
    await assertDiagnostics(code, [at(code, '_pad', after: 'all(')]);
  }

  Future<void> test_aliasOfToken() async {
    await assertNoDiagnostics(r'''
import 'package:bb_tokens/bb_tokens.dart';
import 'package:flutter/widgets.dart';
const _pad = Space.sm;
Widget f() => const Padding(padding: EdgeInsets.all(_pad), child: Text(''));
''');
  }

  Future<void> test_widgetDefault() async {
    const code = r'''
import 'package:flutter/widgets.dart';
class Box extends StatelessWidget {
  const Box({super.key, this.height = 42});
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}
''';
    await assertDiagnostics(code, [at(code, '42')]);
  }

  Future<void> test_halfOfMeasuredSize() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f(double w) => SizedBox(width: w / 2);
''');
  }

  Future<void> test_kitFunctionArgument() async {
    const code = r'''
import 'package:bb_ui/bb_ui.dart';
void f() => showModalPanel(width: 560);
''';
    await assertDiagnostics(code, [at(code, '560')]);
  }

  Future<void> test_ownFunctionArgument() async {
    await assertNoDiagnostics(r'''
void resize({double width = 0}) {}
void f() => resize(width: 560);
''');
  }

  Future<void> test_notAStylePosition() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() => const Text('a', maxLines: 3);
''');
  }

  Future<void> test_tokenFileMayHoldNumbers() async {
    newFile('$testPackageLibPath/app_tokens.dart', r'''
import 'package:flutter/widgets.dart';
const pagePadding = EdgeInsets.all(20);
''');
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'app_tokens.dart';
Widget f() => const Padding(padding: pagePadding, child: Text(''));
''');
  }
}

@reflectiveTest
class NoMagicNumbersTest extends _RuleTest {
  @override
  AnalysisRule get subject => NoMagicNumbers();

  Future<void> test_unnamed() async {
    const code = r'''
int f(int x) => x * 37;
''';
    await assertDiagnostics(code, [at(code, '37')]);
  }

  Future<void> test_named() async {
    await assertNoDiagnostics(r'''
const _retries = 37;
int f(int x) => x * _retries;
''');
  }

  Future<void> test_neutral() async {
    await assertNoDiagnostics(r'''
int f(int x) => (x + 1) ~/ 2 - 0;
''');
  }
}

@reflectiveTest
class NoRawColorsTest extends _RuleTest {
  @override
  AnalysisRule get subject => NoRawColors();

  Future<void> test_colorLiteral() async {
    const code = r'''
import 'package:flutter/widgets.dart';
const c = Color(0xFF112233);
''';
    await assertDiagnostics(code, [at(code, 'Color(0xFF112233)')]);
  }

  Future<void> test_alphaLiteral() async {
    const code = r'''
import 'package:flutter/widgets.dart';
Color f(Color c) => c.withValues(alpha: .4);
''';
    await assertDiagnostics(code, [at(code, 'alpha: .4')]);
  }
}

@reflectiveTest
class NoRawTextStyleTest extends _RuleTest {
  @override
  AnalysisRule get subject => NoRawTextStyle();

  Future<void> test_typography() async {
    const code = r'''
import 'package:flutter/widgets.dart';
const s = TextStyle(fontSize: 13);
''';
    await assertDiagnostics(code, [at(code, 'TextStyle', after: '= ')]);
  }

  Future<void> test_highlightOnly() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
TextStyle f(Color c) => TextStyle(color: c);
''');
  }
}

@reflectiveTest
class UseGapTest extends _RuleTest {
  @override
  AnalysisRule get subject => UseGap();

  Future<void> test_spacerInColumn() async {
    const code = r'''
import 'package:bb_tokens/bb_tokens.dart';
import 'package:flutter/widgets.dart';
Widget f() => const Column(
  children: [Text('a'), SizedBox(height: Space.sm), Text('b')],
);
''';
    await assertDiagnostics(code, [at(code, 'SizedBox(height: Space.sm)')]);
  }

  Future<void> test_boxWithChild() async {
    await assertNoDiagnostics(r'''
import 'package:bb_tokens/bb_tokens.dart';
import 'package:flutter/widgets.dart';
Widget f() => const Column(
  children: [SizedBox(height: Space.sm, child: Text('a'))],
);
''');
  }
}

@reflectiveTest
class NoWindowSizeTest extends _RuleTest {
  @override
  AnalysisRule get subject => NoWindowSize();

  Future<void> test_sizeOf() async {
    const code = r'''
// The mock Flutter package has no MediaQuery.sizeOf; this stands in.
abstract final class MediaQuery {
  static double sizeOf(Object context) => 0;
}
double f(Object context) => MediaQuery.sizeOf(context);
''';
    await assertDiagnostics(code, [at(code, 'MediaQuery.sizeOf(context)')]);
  }
}

@reflectiveTest
class NoMaterialTest extends _RuleTest {
  @override
  AnalysisRule get subject => NoMaterial();

  Future<void> test_import() async {
    const code = r'''
// ignore: unused_import
import 'package:flutter/material.dart';
''';
    await assertDiagnostics(code, [
      at(code, "'package:flutter/material.dart'"),
    ]);
  }
}
