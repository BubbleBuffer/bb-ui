import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(600, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    AppTheme(
      colors: AppColors.light,
      density: Density.pointer,
      child: WidgetsApp(
        color: const Color(0xFFFFFFFF),
        pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        ),
        home: Center(child: SizedBox(width: 160, child: child)),
      ),
    ),
  );
}

void main() {
  test(
    'parseNumberInput and formatNumberValue handle separators and bounds',
    () {
      const cases =
          <(String input, double? min, double? max, double? expected)>[
            ('1,5', null, null, 1.5),
            ('1.5', null, null, 1.5),
            (' -12,25 ', null, null, -12.25),
            ('abc', null, null, null),
            ('', null, null, null),
            ('1.2.3', null, null, null),
            ('150', 0, 100, 100),
            ('-10', 0, 100, 0),
          ];

      for (final (input, min, max, expected) in cases) {
        expect(
          parseNumberInput(input, min: min, max: max),
          expected,
          reason: 'input=$input min=$min max=$max',
        );
      }

      expect(formatNumberValue(1.5), '1.5');
      expect(formatNumberValue(2.0), '2');
      expect(formatNumberValue(-0.0), '0');
      expect(formatNumberValue(1.2345, precision: 2), '1.23');
    },
  );

  testWidgets(
    'typing commits changed-then-end and invalid restores last valid',
    (t) async {
      final events = <String>[];
      var current = 10.0;
      await _pump(
        t,
        StatefulBuilder(
          builder: (context, setState) => NumberField(
            fieldKey: const ValueKey('num-field'),
            label: 'X',
            value: current,
            min: 0,
            max: 50,
            onChanged: (v) {
              events.add('change:$v');
              setState(() => current = v);
            },
            onChangeEnd: (v) => events.add('end:$v'),
          ),
        ),
      );

      await t.enterText(find.byKey(const ValueKey('num-field')), '1,5');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump();
      expect(events, ['change:1.5', 'end:1.5']);
      expect(find.text('1.5'), findsOneWidget);

      events.clear();
      await t.enterText(find.byKey(const ValueKey('num-field')), 'abc');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump();
      expect(events, isEmpty);
      expect(find.text('1.5'), findsOneWidget);

      await t.enterText(find.byKey(const ValueKey('num-field')), '120');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump();
      expect(events, ['change:50.0', 'end:50.0']);
      expect(find.text('50'), findsOneWidget);
    },
  );

  testWidgets(
    'scrubbing label fires onChanged several times then one onChangeEnd',
    (t) async {
      final changed = <double>[];
      final ended = <double>[];
      var current = 10.0;

      await _pump(
        t,
        StatefulBuilder(
          builder: (context, setState) => NumberField(
            labelKey: const ValueKey('num-label'),
            label: 'X',
            value: current,
            step: 1,
            onChanged: (v) {
              changed.add(v);
              setState(() => current = v);
            },
            onChangeEnd: (v) => ended.add(v),
          ),
        ),
      );

      final gesture = await t.startGesture(
        t.getCenter(find.byKey(const ValueKey('num-label'))),
      );
      await gesture.moveBy(const Offset(8, 0));
      await gesture.moveBy(const Offset(8, 0));
      await gesture.up();
      await t.pump();

      expect(changed.length, greaterThanOrEqualTo(2));
      expect(ended, [changed.last]);
    },
  );

  testWidgets(
    'Escape during scrub or edit restores starting value and calls onChangeCancel',
    (t) async {
      final cancelled = <double>[];
      final ended = <double>[];
      var current = 20.0;

      await _pump(
        t,
        StatefulBuilder(
          builder: (context, setState) => NumberField(
            fieldKey: const ValueKey('num-field'),
            labelKey: const ValueKey('num-label'),
            label: 'X',
            value: current,
            onChanged: (v) => setState(() => current = v),
            onChangeEnd: (v) => ended.add(v),
            onChangeCancel: (v) {
              cancelled.add(v);
              setState(() => current = v);
            },
          ),
        ),
      );

      // Escape during scrub.
      final gesture = await t.startGesture(
        t.getCenter(find.byKey(const ValueKey('num-label'))),
      );
      await gesture.moveBy(const Offset(16, 0));
      await t.pump();
      expect(current, greaterThan(20.0));
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pump();
      await gesture.up();
      await t.pump();
      expect(cancelled, [20.0]);
      expect(ended, isEmpty);
      expect(current, 20.0);

      // Escape during text edit.
      await t.enterText(find.byKey(const ValueKey('num-field')), '99');
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pump();
      expect(cancelled, [20.0, 20.0]);
      expect(ended, isEmpty);
      expect(find.text('20'), findsOneWidget);
    },
  );
}
