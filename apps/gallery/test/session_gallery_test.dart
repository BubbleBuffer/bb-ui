import 'package:bb_ui/bb_ui.dart';
import 'package:bb_ui_gallery/gallery.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {double width = 1000}) async {
  tester.view.physicalSize = Size(width, 1700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const GalleryApp(scene: GalleryScene.session));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the display picker switches the shown display', (tester) async {
    await _pump(tester);
    expect(find.text('Showing display 1'), findsOneWidget);
    await tester.ensureVisible(find.byType(DisplayPicker));
    await tester.tap(find.text('Display 2'));
    await tester.pumpAndSettle();
    expect(find.text('Showing display 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a toast appears and closes by itself', (tester) async {
    await _pump(tester);
    await tester.ensureVisible(find.text('Show a toast'));
    await tester.tap(find.text('Show a toast'));
    await tester.pump();
    expect(find.text('Toast 1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.text('Toast 1'), findsNothing);
    expect(find.text('Toasts shown: 1'), findsOneWidget);
  });

  testWidgets('the strip reports stats on and off; compact scrolls', (
    tester,
  ) async {
    await _pump(tester, width: 390);
    expect(find.byType(EdgeStrip), findsOneWidget);
    expect(find.byType(EdgeTab), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
