import 'dart:ui' show Tristate;

import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
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
  testWidgets('formats 0.5 as 50% and invokes label callback', (t) async {
    var labelTapped = 0;
    await _pump(
      t,
      ZoomControl(
        zoom: 0.5,
        onZoomIn: () {},
        onZoomOut: () {},
        onLabelPressed: () => labelTapped++,
      ),
    );

    expect(find.text('50%'), findsOneWidget);
    await t.tap(find.text('50%'));
    await t.pump();
    expect(labelTapped, 1);
  });

  testWidgets('buttons disable at min and max', (t) async {
    final handle = t.ensureSemantics();
    var zoomOutCalls = 0;
    var zoomInCalls = 0;

    await _pump(
      t,
      ZoomControl(
        zoom: 0.25,
        min: 0.25,
        max: 4.0,
        onZoomOut: () => zoomOutCalls++,
        onZoomIn: () => zoomInCalls++,
      ),
    );

    expect(
      t
          .getSemantics(find.bySemanticsLabel('Zoom out'))
          .getSemanticsData()
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    expect(
      t
          .getSemantics(find.bySemanticsLabel('Zoom in'))
          .getSemanticsData()
          .flagsCollection
          .isEnabled,
      Tristate.isTrue,
    );

    await t.tap(find.bySemanticsLabel('Zoom out'));
    await t.tap(find.bySemanticsLabel('Zoom in'));
    await t.pump();
    expect(zoomOutCalls, 0);
    expect(zoomInCalls, 1);

    await _pump(
      t,
      ZoomControl(
        zoom: 4.0,
        min: 0.25,
        max: 4.0,
        onZoomOut: () => zoomOutCalls++,
        onZoomIn: () => zoomInCalls++,
      ),
    );

    expect(
      t
          .getSemantics(find.bySemanticsLabel('Zoom in'))
          .getSemanticsData()
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    expect(
      t
          .getSemantics(find.bySemanticsLabel('Zoom out'))
          .getSemanticsData()
          .flagsCollection
          .isEnabled,
      Tristate.isTrue,
    );

    await t.tap(find.bySemanticsLabel('Zoom in'));
    await t.tap(find.bySemanticsLabel('Zoom out'));
    await t.pump();
    expect(zoomInCalls, 1);
    expect(zoomOutCalls, 1);
    handle.dispose();
  });
}
