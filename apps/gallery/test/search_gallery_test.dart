import 'package:bb_ui/bb_ui.dart';
import 'package:bb_ui_gallery/gallery.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {double width = 1600}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const GalleryApp(scene: GalleryScene.search));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the panel filters by kind and by query, and Enter opens', (
    tester,
  ) async {
    await _pump(tester);
    Finder row(String id) => find.byKey(ValueKey('sample-$id'));
    expect(row('garden-plan'), findsOneWidget);
    expect(row('garden-chat'), findsOneWidget);
    expect(find.byKey(const ValueKey('search-group-document')), findsOneWidget);
    expect(find.byKey(const ValueKey('search-narrowed-hint')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('search-type-chats')));
    await tester.pumpAndSettle();
    expect(row('garden-plan'), findsNothing);
    expect(row('garden-chat'), findsOneWidget);
    expect(find.byKey(const ValueKey('search-narrowed-hint')), findsOneWidget);
    // Tapping the selected chip returns to all kinds.
    await tester.tap(find.byKey(const ValueKey('search-type-chats')));
    await tester.pumpAndSettle();
    expect(row('garden-plan'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('sample-field')), 'beans');
    await tester.pumpAndSettle();
    expect(row('seed-list'), findsOneWidget);
    expect(row('garden-plan'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Opened: Seed list'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('sample-field')), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No results'), findsWidgets);
    await tester.enterText(find.byKey(const ValueKey('sample-field')), '');
    await tester.pumpAndSettle();
    expect(find.text('Search sample titles and text.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('matches are marked in titles and snippets', (tester) async {
    await _pump(tester);
    final texts = tester.widgetList<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('sample-garden-plan')),
        matching: find.byType(Text),
      ),
    );
    final marked = [
      for (final text in texts)
        if (text.textSpan case final TextSpan root)
          for (final span in root.children ?? const <InlineSpan>[])
            if (span is TextSpan &&
                span.style?.backgroundColor == AppColors.light.textSelection)
              span.text,
    ];
    // The title marks the word; this sample's snippet does not contain it.
    expect(marked, ['Garden']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the compact specimen switches theme and stays usable', (
    tester,
  ) async {
    await _pump(tester, width: 390);
    await tester.tap(find.byKey(const ValueKey('theme-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Use light theme'), findsOneWidget);
    final theme = AppTheme.of(tester.element(find.byType(SearchPanel)));
    expect(theme.colors.dark, isTrue);
    expect(theme.formFactor, FormFactor.mobile);
    expect(find.text('DOCUMENT'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
