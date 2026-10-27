import 'package:bb_ui/bb_ui.dart';
import 'package:bb_ui_gallery/gallery.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {double width = 1600}) async {
  tester.view.physicalSize = Size(width, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const GalleryApp(scene: GalleryScene.palette));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the panel filters, runs the selection and skips a disabled one',
    (tester) async {
      await _pump(tester);
      final panel = find.byKey(const ValueKey('sample-palette'));
      Finder row(String id) => find.descendant(
        of: panel,
        matching: find.byKey(ValueKey('palette-row-$id')),
      );
      expect(row('page.new'), findsOneWidget);
      expect(row('page.trash'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('sample-field')), 'tgl');
      await tester.pumpAndSettle();
      expect(row('view.sidebar'), findsOneWidget);
      expect(row('page.new'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Ran: Toggle sidebar'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('sample-field')),
        'trash',
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Ran: Toggle sidebar'), findsOneWidget);
      expect(find.text('No page open'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the button opens the palette and a command runs', (
    tester,
  ) async {
    await _pump(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('palette-open')));
    await tester.tap(find.byKey(const ValueKey('palette-open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('palette-field-focus')), findsWidgets);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Nothing run yet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('palette-open')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Ran: New page'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the compact specimen switches theme and keeps its rows', (
    tester,
  ) async {
    await _pump(tester, width: 390);
    await tester.tap(find.byKey(const ValueKey('theme-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Use light theme'), findsOneWidget);
    final theme = AppTheme.of(
      tester.element(find.byType(CommandPalette).first),
    );
    expect(theme.colors.dark, isTrue);
    expect(theme.formFactor, FormFactor.mobile);
    expect(find.byKey(const ValueKey('palette-cancel')), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
