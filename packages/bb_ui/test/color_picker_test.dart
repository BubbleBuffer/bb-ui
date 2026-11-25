import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(800, 600);
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
        home: Center(child: child),
      ),
    ),
  );
}

void main() {
  test('hex parsing and formatting round trip including alpha and invalid', () {
    const cases = <(String input, Color? color, String? formatted)>[
      ('#F0A', Color(0xFFFF00AA), '#FF00AA'),
      ('#de945f', Color(0xFFDE945F), '#DE945F'),
      ('DE945F', Color(0xFFDE945F), '#DE945F'),
      ('#DE945F80', Color(0x80DE945F), '#DE945F80'),
      ('#12', null, null),
      ('#12345', null, null),
      ('#GGGGGG', null, null),
      ('', null, null),
    ];

    for (final (input, expectedColor, expectedFormatted) in cases) {
      final parsed = parseHexColor(input);
      expect(parsed, expectedColor, reason: 'input=$input');
      if (parsed != null) {
        expect(
          formatHexColor(parsed),
          expectedFormatted,
          reason: 'input=$input',
        );
      }
    }
    expect(
      formatHexColor(const Color(0xFFDE945F), includeAlpha: true),
      '#DE945FFF',
    );
  });

  testWidgets('dragging in SV area fires onChanged then one onChangeEnd', (
    t,
  ) async {
    final changed = <Color?>[];
    final ended = <Color?>[];
    Color? current = const Color(0xFFDE945F);

    await _pump(
      t,
      StatefulBuilder(
        builder: (context, setState) => ColorPickerPanel(
          color: current,
          onChanged: (c) {
            changed.add(c);
            setState(() => current = c);
          },
          onChangeEnd: (c) => ended.add(c),
        ),
      ),
    );

    final sv = find.byKey(const ValueKey('color-picker-sv-area'));
    final gesture = await t.startGesture(
      t.getTopLeft(sv) + const Offset(20, 20),
    );
    await gesture.moveBy(const Offset(40, 20));
    await gesture.moveBy(const Offset(40, 20));
    await gesture.up();
    await t.pump();

    expect(changed.length, greaterThanOrEqualTo(2));
    expect(ended, [changed.last]);
  });

  testWidgets('showColorPicker opens popover anchored to trigger', (t) async {
    Color? picked = const Color(0xFFDE945F);
    await _pump(
      t,
      Builder(
        builder: (context) => SwatchButton(
          key: const ValueKey('trigger'),
          color: picked,
          onPressed: () => showColorPicker(
            context,
            color: picked,
            onChanged: (c) => picked = c,
            onChangeEnd: (c) => picked = c,
          ),
        ),
      ),
    );

    await t.tap(find.byKey(const ValueKey('trigger')));
    await t.pumpAndSettle();
    expect(find.byType(ColorPickerPanel), findsOneWidget);
  });
}
