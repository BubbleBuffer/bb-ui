import 'package:bb_ui_testing/src/coverage.dart';
import 'package:flutter_test/flutter_test.dart';

const _fixture = 'test/fixtures/lcov';

void main() {
  test('lcov covers executed widget and State builds', () {
    final report = scanWidgetCoverage(
      libPath: '$_fixture/lib',
      testPath: '$_fixture/test',
      lcovPath: '$_fixture/lcov.info',
    );
    final entries = {for (final entry in report.widgets) entry.name: entry};
    const cases = {
      'Card': true,
      'Notice': false, // Only an unrelated method hit and a name reference.
      'Counter': true,
    };
    for (final MapEntry(key: name, value: hit) in cases.entries) {
      final entry = entries[name]!;
      expect(entry.hit, hit, reason: name);
      expect(entry.covered, hit, reason: name);
      expect(entry.toJson(), containsPair('hit', hit), reason: name);
    }
  });
}
