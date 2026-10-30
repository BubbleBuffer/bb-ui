import 'package:bb_ui/bb_ui.dart';
import 'package:bb_ui_gallery/gallery.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {double width = 1000}) async {
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const GalleryApp(scene: GalleryScene.devices));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('selecting a row changes the detail panel', (tester) async {
    await _pump(tester);
    expect(find.text('Studio PC'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('row-living')));
    await tester.pumpAndSettle();
    final detail = find.byType(DetailPanel);
    expect(
      find.descendant(of: detail, matching: find.text('Living room')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('code fields group and upper-case what is typed', (tester) async {
    await _pump(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('id-field')),
        matching: find.byType(EditableText),
      ),
      'h4pd r8tn b7qk',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('code-field')),
        matching: find.byType(EditableText),
      ),
      '7kq2m9x',
    );
    await tester.pump();
    expect(find.text('H4PD-R8TN-B7QK'), findsOneWidget);
    expect(find.text('7KQ2-M9X'), findsOneWidget);
    expect(find.text('Typed: 12 of 16 and 7 of 8'), findsOneWidget);
  });

  testWidgets('the confirm dialog answers and the notice dismisses', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Forget'));
    await tester.pumpAndSettle();
    expect(find.text('Keep'), findsWidgets);
    await tester.tap(find.text('Keep').last);
    await tester.pumpAndSettle();
    expect(find.text('Confirm answer: Kept'), findsOneWidget);
    await tester.ensureVisible(find.byType(NoticeBanner).last);
    await tester.tap(
      find.descendant(
        of: find.byType(NoticeBanner).last,
        matching: find.byType(IconBtn),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("The stream didn't start"), findsNothing);
  });

  testWidgets('compact layout stacks the list and the detail', (tester) async {
    await _pump(tester, width: 390);
    expect(find.byType(DeviceRow), findsNWidgets(4));
    expect(find.byType(DetailPanel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
