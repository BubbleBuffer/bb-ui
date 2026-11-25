import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/rendering.dart';
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
        home: Center(child: SizedBox(width: 240, child: child)),
      ),
    ),
  );
}

void main() {
  testWidgets('dragging fires onChanged then one onChangeEnd', (t) async {
    final changed = <double>[];
    final ended = <double>[];
    var value = 0.2;

    await _pump(
      t,
      StatefulBuilder(
        builder: (context, setState) => BbSlider(
          value: value,
          semanticLabel: 'Opacity',
          onChanged: (v) {
            changed.add(v);
            setState(() => value = v);
          },
          onChangeEnd: (v) => ended.add(v),
        ),
      ),
    );

    final gesture = await t.startGesture(t.getCenter(find.byType(BbSlider)));
    await gesture.moveBy(const Offset(30, 0));
    await gesture.moveBy(const Offset(30, 0));
    await gesture.up();
    await t.pump();

    expect(changed.length, greaterThanOrEqualTo(2));
    expect(ended, [changed.last]);
  });

  testWidgets('Escape during drag cancels with starting value', (t) async {
    final cancelled = <double>[];
    final ended = <double>[];
    var value = 0.3;

    await _pump(
      t,
      StatefulBuilder(
        builder: (context, setState) => BbSlider(
          value: value,
          semanticLabel: 'Opacity',
          onChanged: (v) => setState(() => value = v),
          onChangeEnd: (v) => ended.add(v),
          onChangeCancel: (v) {
            cancelled.add(v);
            setState(() => value = v);
          },
        ),
      ),
    );

    final gesture = await t.startGesture(t.getCenter(find.byType(BbSlider)));
    await gesture.moveBy(const Offset(40, 0));
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pump();
    await gesture.up();
    await t.pump();

    expect(cancelled, [0.3]);
    expect(ended, isEmpty);
    expect(value, 0.3);
  });

  testWidgets('semantics increase action changes the value', (t) async {
    final handle = t.ensureSemantics();
    final changed = <double>[];
    final ended = <double>[];
    var value = 0.5;

    await _pump(
      t,
      StatefulBuilder(
        builder: (context, setState) => BbSlider(
          value: value,
          semanticLabel: 'Opacity',
          onChanged: (v) {
            changed.add(v);
            setState(() => value = v);
          },
          onChangeEnd: (v) => ended.add(v),
        ),
      ),
    );

    final node = t.getSemantics(find.bySemanticsLabel('Opacity'));
    final data = node.getSemanticsData();
    expect(data.flagsCollection.isSlider, isTrue);
    expect(data.hasAction(SemanticsAction.increase), isTrue);

    node.owner!.performAction(node.id, SemanticsAction.increase);
    await t.pump();

    expect(changed, hasLength(1));
    expect(changed.single, greaterThan(0.5));
    expect(ended, [changed.single]);
    handle.dispose();
  });
}
