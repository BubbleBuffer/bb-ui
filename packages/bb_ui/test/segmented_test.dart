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
  testWidgets('tap selects a segment and semantics mark the selected one', (
    t,
  ) async {
    final handle = t.ensureSemantics();
    var value = 'design';

    await _pump(
      t,
      StatefulBuilder(
        builder: (context, setState) => Segmented<String>(
          value: value,
          options: const [
            SegmentOption(value: 'design', label: 'Design'),
            SegmentOption(value: 'animate', label: 'Animate'),
            SegmentOption(value: 'preview', label: 'Preview'),
          ],
          onChanged: (next) => setState(() => value = next),
        ),
      ),
    );

    expect(
      t
          .getSemantics(find.bySemanticsLabel('Design'))
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    expect(
      t
          .getSemantics(find.bySemanticsLabel('Animate'))
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      Tristate.isFalse,
    );

    await t.tap(find.text('Animate'));
    await t.pump();

    expect(value, 'animate');
    expect(
      t
          .getSemantics(find.bySemanticsLabel('Design'))
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      Tristate.isFalse,
    );
    expect(
      t
          .getSemantics(find.bySemanticsLabel('Animate'))
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    handle.dispose();
  });
}
