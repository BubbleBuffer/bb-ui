import 'dart:convert';
import 'dart:io';

import 'package:bb_ui_testing/src/coverage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory fixture;
  late String lib;
  late String tests;

  void write(String path, String source) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(source);
  }

  setUp(() {
    fixture = Directory.systemTemp.createTempSync('bb_ui_coverage_');
    lib = '${fixture.path}/lib';
    tests = '${fixture.path}/test';
    Directory(lib).createSync();
    Directory(tests).createSync();
  });
  tearDown(() => fixture.deleteSync(recursive: true));

  test('discovers transitive generic widgets and counts exact test tokens', () {
    write('$lib/widgets.dart', '''
class Leaf extends Middle<int> {}
class Middle<T extends Object>
    extends Base<T> {}
abstract class Base<T> extends ui.StatelessWidget {}
class Stateful extends StatefulWidget {}
class _Private extends StatelessWidget {}
class Plain {}
// class CommentWidget extends StatelessWidget {}
final text = "class StringWidget extends StatelessWidget {}";
''');
    write('$tests/widgets_test.dart', '''
// Leaf Middle
const text = 'Base Stateful';
''');
    final report = scanWidgetCoverage(libPath: lib, testPath: tests);
    expect(report.widgets.map((entry) => entry.name), [
      'Base',
      'Leaf',
      'Middle',
      'Stateful',
    ]);
    expect(report.covered, 4);
    expect(report.passed, isTrue);
    expect(report.toJson()['summary'], containsPair('covered', 4));
    expect(report.toMarkdown(), contains('| Leaf | covered |'));
    final privateReport = scanWidgetCoverage(
      libPath: lib,
      testPath: tests,
      includePrivate: true,
    );
    expect(privateReport.uncovered, 1);
  });

  test('uncovered widget fails and substring references do not cover it', () {
    write('$lib/widget.dart', 'class Card extends StatefulWidget {}');
    write('$tests/widget_test.dart', '// CardView MyCard Card2 _Card');
    final report = scanWidgetCoverage(libPath: lib, testPath: tests);
    expect(report.uncovered, 1);
    expect(report.widgets.single.status, 'uncovered');
    expect(report.passed, isFalse);
  });

  test('duplicate library-local names produce separate widget rows', () {
    write('$lib/first.dart', 'class _Header extends StatelessWidget {}');
    write('$lib/second.dart', 'class _Header extends StatefulWidget {}');
    write('$lib/unrelated.dart', 'class _Header extends Object {}');
    final hidden = scanWidgetCoverage(libPath: lib, testPath: tests);
    expect(hidden.widgets, isEmpty);
    final uncovered = scanWidgetCoverage(
      libPath: lib,
      testPath: tests,
      includePrivate: true,
    );
    expect(uncovered.uncovered, 2);
    expect(uncovered.widgets.map((entry) => entry.source), [
      'first.dart',
      'second.dart',
    ]);
    write('$tests/widget_test.dart', '// _Header');
    final covered = scanWidgetCoverage(
      libPath: lib,
      testPath: tests,
      includePrivate: true,
    );
    expect(covered.covered, 2);
    expect(covered.passed, isTrue);
  });

  test('missing test directory can represent an empty default scan', () {
    write('$lib/widget.dart', 'class Card extends StatelessWidget {}');
    Directory(tests).deleteSync();
    final report = scanWidgetCoverage(
      libPath: lib,
      testPath: tests,
      allowMissingTestDirectory: true,
    );
    expect(report.uncovered, 1);
    expect(report.passed, isFalse);
    expect(
      () => scanWidgetCoverage(libPath: lib, testPath: tests),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('allowlisted uncovered widget passes with blank lines and comments', () {
    write('$lib/widget.dart', 'class Card extends StatelessWidget {}');
    final allow = '${fixture.path}/coverage-allowlist.txt';
    write(allow, '# intentional debt\n\nCard # waiting for test\n');
    final report = scanWidgetCoverage(
      libPath: lib,
      testPath: tests,
      allowPath: allow,
    );
    expect(report.allowed, 1);
    expect(report.widgets.single.status, 'allowed');
    expect(report.staleAllowlist, isEmpty);
    expect(report.passed, isTrue);
  });

  test('covered and nonexistent allowlist entries fail as stale', () {
    write('$lib/widget.dart', 'class Card extends StatelessWidget {}');
    write('$tests/widget_test.dart', '// Card');
    final allow = '${fixture.path}/coverage-allowlist.txt';
    write(allow, 'Card\nGone\n');
    final report = scanWidgetCoverage(
      libPath: lib,
      testPath: tests,
      allowPath: allow,
    );
    expect(report.staleAllowlist, ['Card', 'Gone']);
    expect(report.allowed, 0);
    expect(report.covered, 1);
    expect(report.passed, isFalse);
  });

  test('existing mapped golden covers widget and makes allowance stale', () {
    write('$lib/widget.dart', 'class Card extends StatelessWidget {}');
    write('$tests/goldens/card.light.png', 'fixture');
    final mapping = '${fixture.path}/goldens.json';
    write(
      mapping,
      jsonEncode({
        'Card': ['card.light.png', 'missing.png'],
      }),
    );
    final allow = '${fixture.path}/coverage-allowlist.txt';
    write(allow, 'Card\n');
    final report = scanWidgetCoverage(
      libPath: lib,
      testPath: tests,
      allowPath: allow,
      goldens: readGoldenMapping(mapping),
    );
    expect(report.covered, 1);
    expect(report.widgets.single.tests, isEmpty);
    expect(report.widgets.single.goldens, ['goldens/card.light.png']);
    expect(report.staleAllowlist, ['Card']);
  });

  test('missing mapped PNG gives no coverage; malformed mappings fail', () {
    write('$lib/widget.dart', 'class Card extends StatelessWidget {}');
    final report = scanWidgetCoverage(
      libPath: lib,
      testPath: tests,
      goldens: {
        'Card': ['missing.png'],
      },
    );
    expect(report.uncovered, 1);
    final mapping = '${fixture.path}/goldens.json';
    write(mapping, '{"Card": [4]}');
    expect(() => readGoldenMapping(mapping), throwsFormatException);
    write(mapping, '{"Card": "../card.png"}');
    expect(() => readGoldenMapping(mapping), throwsFormatException);
  });
}
