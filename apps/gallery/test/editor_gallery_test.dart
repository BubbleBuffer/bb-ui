import 'package:bb_ui/bb_ui.dart';
import 'package:bb_ui_gallery/gallery.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {double width = 1000}) async {
  tester.view.physicalSize = Size(width, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const GalleryApp(scene: GalleryScene.editor));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('editor gallery renders controls, opens picker, switches theme', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Editor controls'), findsOneWidget);
    expect(find.byType(ToolRail), findsWidgets);
    expect(find.byType(NumberField), findsWidgets);
    expect(find.byType(BbSlider), findsWidgets);
    expect(find.byType(Segmented<String>), findsWidgets);
    expect(find.byType(ColorPickerPanel), findsOneWidget);
    expect(find.byType(TreeRow), findsWidgets);
    expect(find.byType(ZoomControl), findsWidgets);
    expect(find.byType(PropertySection), findsWidgets);

    await tester.ensureVisible(
      find.byKey(const ValueKey('inspector-fill-swatch')),
    );
    await tester.tap(find.byKey(const ValueKey('inspector-fill-swatch')));
    await tester.pumpAndSettle();
    expect(find.byType(ColorPickerPanel), findsNWidgets(2));

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.byType(ColorPickerPanel), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('theme-toggle')));
    await tester.tap(find.byKey(const ValueKey('theme-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Use light theme'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
