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
  testWidgets('tapping reports press and selected exposes selected semantics', (
    t,
  ) async {
    final handle = t.ensureSemantics();
    String? pressed;
    await _pump(
      t,
      ToolRail(
        children: [
          ToolButton(
            icon: Ico.pointer,
            tooltip: 'Select',
            shortcut: 'V',
            selected: true,
            onPressed: () => pressed = 'select',
          ),
          ToolButton(
            icon: Ico.square,
            tooltip: 'Rectangle',
            shortcut: 'R',
            selected: false,
            onPressed: () => pressed = 'rect',
          ),
          const ToolRailSeparator(),
          const ToolButton(icon: Ico.lock, tooltip: 'Locked', onPressed: null),
        ],
      ),
    );

    final selectData = t
        .getSemantics(find.bySemanticsLabel('Select'))
        .getSemanticsData();
    expect(selectData.flagsCollection.isButton, isTrue);
    expect(selectData.flagsCollection.isSelected, Tristate.isTrue);
    expect(selectData.flagsCollection.isEnabled, Tristate.isTrue);

    final rectData = t
        .getSemantics(find.bySemanticsLabel('Rectangle'))
        .getSemanticsData();
    expect(rectData.flagsCollection.isButton, isTrue);
    expect(rectData.flagsCollection.isSelected, Tristate.isFalse);

    final lockedData = t
        .getSemantics(find.bySemanticsLabel('Locked'))
        .getSemanticsData();
    expect(lockedData.flagsCollection.isEnabled, Tristate.isFalse);

    await t.tap(find.bySemanticsLabel('Rectangle'));
    await t.pump();
    expect(pressed, 'rect');

    await t.tap(find.bySemanticsLabel('Locked'));
    await t.pump();
    expect(pressed, 'rect');
    handle.dispose();
  });
}
