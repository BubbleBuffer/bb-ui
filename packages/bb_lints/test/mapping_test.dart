import 'package:bb_lints/migrate.dart';
import 'package:bb_lints/src/mapping.dart';
import 'package:test/test.dart';

void main() {
  test('spacing snaps to the nearest step, ties going up', () {
    const steps = [(8.0, 'sm'), (12.0, 'md'), (16.0, 'lg')];
    expect(nearest(steps, 8), 'sm');
    expect(nearest(steps, 10), 'md');
    expect(nearest(steps, 9), 'sm');
    expect(nearest(steps, 14), 'lg');
  });

  test('hand-written type specs map to the nearest role', () {
    expect(roleFor(16, 20, mono: false, weight: 640).$1, 'title');
    expect(roleFor(16, 24, mono: false, weight: 500).$1, 'body');
    expect(roleFor(12, 16, mono: true).$1, 'codeSmall');
    expect(roleFor(12, 16, mono: false, weight: 500).$1, 'uiSmall');
    expect(roleFor(11, 14, mono: false).$1, 'caption');
    expect(roleFor(32, 34, mono: false, weight: 700).$1, 'display');
  });

  test('a monospace constant keeps a code role', () {
    expect(roleFor(12.5, 20, mono: true).$1, 'code');
  });

  test('integer weights map to Weight', () {
    expect(weightFor(400), 'Weight.regular');
    expect(weightFor(640), 'Weight.display');
    expect(weightFor(700), 'Weight.bold');
  });
}
