// SelectButton opens a popover on a wide window, even inside a narrow pane,
// and a sheet on a compact window. Both give each option the same key.

import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Size window) async {
  tester.view.physicalSize = window;
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
        home: Center(
          // A narrow pane, such as a dialog, with its own size class.
          child: SizedBox(
            width: Widths.form,
            child: SizeClassScope(
              sizeClass: SizeClass.compact,
              child: SelectButton<String>(
                key: const ValueKey('select'),
                value: 'One',
                options: const ['One', 'Two'],
                labelOf: (o) => o,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a narrow pane on a wide window opens a popover', (tester) async {
    await _pump(tester, const Size(1400, 900));
    await tester.tap(find.byKey(const ValueKey('select')));
    await tester.pumpAndSettle();
    expect(find.byType(MenuList), findsOneWidget);
    expect(find.byType(SheetSurface), findsNothing);
    expect(find.byKey(const ValueKey('option-Two')), findsOneWidget);
  });

  testWidgets('a compact window opens a sheet', (tester) async {
    await _pump(tester, const Size(390, 800));
    await tester.tap(find.byKey(const ValueKey('select')));
    await tester.pumpAndSettle();
    expect(find.byType(SheetSurface), findsOneWidget);
    expect(find.byKey(const ValueKey('option-Two')), findsOneWidget);
  });
}
