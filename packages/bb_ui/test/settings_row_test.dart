// SettingsRow keeps its control at the right edge at its own width and
// gives the label the rest; a control too wide to sit beside the label goes
// under it.

import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _rowWidth = 600.0;

Future<void> _pump(WidgetTester tester, Widget trailing) async {
  await tester.pumpWidget(
    AppTheme(
      colors: AppColors.light,
      density: Density.pointer,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: _rowWidth,
            child: SettingsRow(
              key: const ValueKey('row'),
              label: 'Device ID',
              description: 'Shown to the other device when pairing.',
              trailing: trailing,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a short control sits at the right edge', (tester) async {
    await _pump(tester, const Text('0.1.0', key: ValueKey('value')));
    final row = tester.getRect(find.byKey(const ValueKey('row')));
    final value = tester.getRect(find.byKey(const ValueKey('value')));
    expect(value.right, row.right);
    // The label gets everything left of the control.
    final label = tester.getRect(find.text('Device ID'));
    expect(label.left, row.left);
  });

  testWidgets('a control too wide to share the row goes under the label', (
    tester,
  ) async {
    await _pump(
      tester,
      const SizedBox(key: ValueKey('wide'), width: _rowWidth, height: 1),
    );
    final wide = tester.getRect(find.byKey(const ValueKey('wide')));
    final label = tester.getRect(find.text('Device ID'));
    expect(wide.top, greaterThan(label.bottom));
    expect(wide.width, _rowWidth);
    expect(tester.takeException(), isNull);
  });
}
