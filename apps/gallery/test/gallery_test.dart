import 'package:bb_ui/bb_ui.dart';
import 'package:bb_ui_gallery/gallery.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('controls update samples, draft, selection and stack', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const GalleryApp());
    await tester.tap(find.text('Add sample'));
    await tester.pumpAndSettle();
    expect(find.text('Samples added: 1'), findsOneWidget);
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(find.text('Samples added: 0'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'A new collection');
    await tester.pump();
    // Text-selection handles render in the Navigator overlay and need a theme.
    expect(tester.takeException(), isNull);
    expect(find.text('Preview: A new collection'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('selection-checkbox')));
    await tester.pumpAndSettle();
    expect(find.text('Sample not selected'), findsOneWidget);
    expect(find.text('A stack keeps related items together.'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('stack-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('A stack keeps related items together.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact gallery switches theme and remains scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const GalleryApp());
    await tester.tap(find.byKey(const ValueKey('theme-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Use light theme'), findsOneWidget);
    final theme = AppTheme.of(tester.element(find.byType(PrimitiveGallery)));
    expect(theme.colors.dark, isTrue);
    await tester.ensureVisible(find.text('Semantic colours'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
