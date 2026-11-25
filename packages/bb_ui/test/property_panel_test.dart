import 'dart:ui' show Tristate;

import 'package:bb_ui/bb_ui.dart';
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
        home: Center(child: SizedBox(width: 280, child: child)),
      ),
    ),
  );
}

void main() {
  testWidgets('PropertySection toggles children and expanded semantics', (
    t,
  ) async {
    final handle = t.ensureSemantics();
    await _pump(
      t,
      const PropertySection(
        title: 'Geometry',
        children: [
          PropertyRow(
            label: 'Position',
            secondary: NumberField(label: 'Y', value: 20),
            child: NumberField(label: 'X', value: 10),
          ),
        ],
      ),
    );

    expect(find.text('Position'), findsOneWidget);
    expect(
      t
          .getSemantics(find.bySemanticsLabel('Geometry'))
          .getSemanticsData()
          .flagsCollection
          .isExpanded,
      Tristate.isTrue,
    );

    await t.tap(find.text('Geometry'));
    await t.pump();
    expect(find.text('Position'), findsNothing);
    expect(
      t
          .getSemantics(find.bySemanticsLabel('Geometry'))
          .getSemanticsData()
          .flagsCollection
          .isExpanded,
      Tristate.isFalse,
    );
    expect(t.takeException(), isNull);
    handle.dispose();
  });
}
