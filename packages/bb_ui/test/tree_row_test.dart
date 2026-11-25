import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/gestures.dart';
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
        home: Center(child: SizedBox(width: 280, child: child)),
      ),
    ),
  );
}

void main() {
  testWidgets('chevron tap toggles without selecting the row', (t) async {
    var expanded = false;
    var selected = 0;

    await _pump(
      t,
      StatefulBuilder(
        builder: (context, setState) => TreeRow(
          label: 'Group',
          expanded: expanded,
          chevronKey: const ValueKey('chevron'),
          onToggleExpanded: () => setState(() => expanded = !expanded),
          onPressed: (_) => selected++,
        ),
      ),
    );

    await t.tap(find.byKey(const ValueKey('chevron')));
    await t.pump();
    expect(expanded, isTrue);
    expect(selected, 0);

    await t.tap(find.text('Group'));
    await t.pump();
    expect(selected, 1);
  });

  testWidgets('trailing actions appear on hover', (t) async {
    await _pump(
      t,
      TreeRow(
        label: 'Backdrop',
        onPressed: (_) {},
        trailing: const [Text('Hide', key: ValueKey('trailing-action'))],
      ),
    );

    expect(find.byKey(const ValueKey('trailing-action')), findsNothing);

    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(t.getCenter(find.text('Backdrop')));
    await t.pump();

    expect(find.byKey(const ValueKey('trailing-action')), findsOneWidget);
  });

  testWidgets('secondary tap reports the pointer position, not a press', (
    t,
  ) async {
    Offset? at;
    var pressed = 0;
    await _pump(
      t,
      TreeRow(
        label: 'Layer',
        onPressed: (_) => pressed++,
        onSecondaryTap: (p) => at = p,
      ),
    );

    final target = t.getCenter(find.text('Layer'));
    await t.tapAt(target, buttons: kSecondaryButton);
    await t.pump();

    expect(at, target);
    expect(pressed, 0);
  });

  testWidgets('press reports Shift and Ctrl/Cmd', (t) async {
    final presses = <TreeRowPress>[];
    await _pump(t, TreeRow(label: 'Layer', onPressed: presses.add));

    await t.tap(find.text('Layer'));
    await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await t.tap(find.text('Layer'));
    await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.tap(find.text('Layer'));
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(presses.map((p) => (p.shift, p.toggle)), [
      (false, false),
      (true, false),
      (false, true),
    ]);
  });

  group('rename', () {
    Future<List<String>> pumpRow(WidgetTester t) async {
      final renamed = <String>[];
      await _pump(
        t,
        TreeRow(label: 'Layer', onPressed: (_) {}, onRename: renamed.add),
      );
      await t.tap(find.text('Layer'));
      await t.tap(find.text('Layer'));
      await t.pump();
      return renamed;
    }

    testWidgets('double-click edits; Enter commits the trimmed text', (
      t,
    ) async {
      final renamed = await pumpRow(t);
      expect(find.byType(EditableText), findsOneWidget);
      expect(
        t.widget<EditableText>(find.byType(EditableText)).controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 5),
      );

      await t.enterText(find.byType(EditableText), '  Mask ');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump();

      expect(renamed, ['Mask']);
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets('Escape cancels without a rename', (t) async {
      final renamed = await pumpRow(t);
      await t.enterText(find.byType(EditableText), 'Mask');
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pump();

      expect(renamed, isEmpty);
      expect(find.byType(EditableText), findsNothing);
      expect(find.text('Layer'), findsOneWidget);
    });

    testWidgets('empty or unchanged text is not a rename', (t) async {
      final renamed = await pumpRow(t);
      await t.enterText(find.byType(EditableText), '   ');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump();
      expect(renamed, isEmpty);
      expect(find.byType(EditableText), findsNothing);

      await t.tap(find.text('Layer'));
      await t.tap(find.text('Layer'));
      await t.pump();
      await t.enterText(find.byType(EditableText), ' Layer ');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump();
      expect(renamed, isEmpty);
    });

    testWidgets('F2 starts a rename on the focused row', (t) async {
      final renamed = <String>[];
      await _pump(
        t,
        TreeRow(label: 'Layer', onPressed: (_) {}, onRename: renamed.add),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.f2);
      await t.pump();
      expect(find.byType(EditableText), findsOneWidget);
    });
  });
}
