// The search widgets over neutral view models: highlight ranges, the result
// row's lines and tones, the grouped list, the filter chips, and the panel's
// keyboard selection, notes and reset. Nothing here knows a host's hits.

import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  FormFactor formFactor = FormFactor.desktop,
  bool dark = false,
}) async {
  tester.view.physicalSize = const Size(700, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    AppTheme(
      colors: dark ? AppColors.darkTheme : AppColors.light,
      formFactor: formFactor,
      child: WidgetsApp(
        color: const Color(0xFFFFFFFF),
        builder: (context, _) => Overlay(
          initialEntries: [OverlayEntry(builder: (_) => child)],
        ),
      ),
    ),
  );
}

SearchResult _result(String id, {String title = 'Title', String? type}) =>
    SearchResult(
      id: id,
      title: '$title $id',
      snippet: 'Snippet of $id',
      rowKey: ValueKey('row-$id'),
      typeLabel: type,
    );

List<SearchResultSection> _sections() => [
  SearchResultSection(
    id: 'a',
    label: 'First',
    results: [_result('a1'), _result('a2')],
  ),
  SearchResultSection(id: 'b', label: 'Second', results: [_result('b1')]),
];

/// The marked and plain text of the first [Text.rich] under [finder].
List<(String, bool)> _spans(WidgetTester tester, Finder finder) {
  final text = tester.widget<Text>(finder);
  final root = text.textSpan! as TextSpan;
  return [
    for (final span in root.children!.cast<TextSpan>())
      (span.text!, span.style?.backgroundColor != null),
  ];
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

void main() {
  group('termHighlights', () {
    test('matches terms in any case, in order', () {
      expect(termHighlights('Garden shed and garden', ['garden']), const [
        TextRange(start: 0, end: 6),
        TextRange(start: 16, end: 22),
      ]);
      expect(termHighlights('a cat, a dog', ['DOG', 'cat']), const [
        TextRange(start: 2, end: 5),
        TextRange(start: 9, end: 12),
      ]);
    });

    test('treats terms as literal text', () {
      expect(termHighlights('a.b axb', ['a.b']), const [
        TextRange(start: 0, end: 3),
      ]);
      expect(termHighlights('(x)', ['(x']), const [
        TextRange(start: 0, end: 2),
      ]);
    });

    test('gives none without terms or a match', () {
      expect(termHighlights('text', const []), isEmpty);
      expect(termHighlights('text', ['zzz']), isEmpty);
      expect(termHighlights('', ['a']), isEmpty);
    });
  });

  group('HighlightedText', () {
    testWidgets('is a plain Text without ranges', (tester) async {
      await _pump(
        tester,
        const HighlightedText('Some text', style: TextStyle(fontSize: 14)),
      );
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, 'Some text');
      expect(text.textSpan, isNull);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('marks the ranges and keeps the text between', (tester) async {
      await _pump(
        tester,
        const HighlightedText(
          'Garden and garden!',
          style: TextStyle(fontSize: 14),
          highlights: [
            TextRange(start: 0, end: 6),
            TextRange(start: 11, end: 17),
          ],
          maxLines: 2,
        ),
      );
      expect(_spans(tester, find.byType(Text)), [
        ('Garden', true),
        (' and ', false),
        ('garden', true),
        ('!', false),
      ]);
      expect(tester.widget<Text>(find.byType(Text)).maxLines, 2);
    });
  });

  group('SearchResultRow', () {
    testWidgets('draws title, secondary line and snippet; taps', (
      tester,
    ) async {
      var taps = 0;
      await _pump(
        tester,
        SizedBox(
          height: SearchResultRow.extent(false),
          child: SearchResultRow(
            result: const SearchResult(
              id: 'r',
              title: 'Garden plan',
              secondary: 'Projects / House',
              secondaryKey: ValueKey('path'),
              snippet: 'Beds along the fence',
              snippetKey: ValueKey('snippet'),
              icon: Ico.page,
              rowKey: ValueKey('row'),
            ),
            onTap: () => taps++,
          ),
        ),
      );
      expect(find.text('Garden plan'), findsOneWidget);
      expect(find.byKey(const ValueKey('path')), findsOneWidget);
      expect(find.text('Projects / House'), findsOneWidget);
      expect(find.byKey(const ValueKey('snippet')), findsOneWidget);
      expect(find.text('GARDEN PLAN'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('row')));
      expect(taps, 1);
    });

    testWidgets('leaves out empty secondary and snippet lines', (
      tester,
    ) async {
      await _pump(
        tester,
        SizedBox(
          height: 64,
          child: SearchResultRow(
            result: const SearchResult(
              id: 'r',
              title: 'Only a title',
              secondaryKey: ValueKey('path'),
              snippetKey: ValueKey('snippet'),
            ),
            onTap: () {},
          ),
        ),
      );
      expect(find.text('Only a title'), findsOneWidget);
      expect(find.byKey(const ValueKey('path')), findsNothing);
      expect(find.byKey(const ValueKey('snippet')), findsNothing);
    });

    testWidgets('title tones: normal, muted and stand-in', (tester) async {
      Future<TextStyle> style(SearchTitleTone tone) async {
        await _pump(
          tester,
          SizedBox(
            height: 64,
            child: SearchResultRow(
              result: SearchResult(id: 'r', title: 'Name', titleTone: tone),
              onTap: () {},
            ),
          ),
        );
        return tester.widget<Text>(find.text('Name')).style!;
      }

      final colors = AppColors.light;
      final normal = await style(SearchTitleTone.normal);
      final muted = await style(SearchTitleTone.muted);
      final standIn = await style(SearchTitleTone.standIn);
      expect(normal.color, colors.textPrimary);
      expect(normal.fontStyle, isNot(FontStyle.italic));
      expect(muted.color, colors.textSecondary);
      expect(standIn.color, colors.textTertiary);
      expect(standIn.fontStyle, FontStyle.italic);
    });

    testWidgets('draws the type label only when asked', (tester) async {
      Future<void> pump({required bool show}) => _pump(
        tester,
        SizedBox(
          height: 64,
          child: SearchResultRow(
            result: _result('r', type: 'Document'),
            showTypeLabel: show,
            onTap: () {},
          ),
        ),
      );
      await pump(show: false);
      expect(find.text('DOCUMENT'), findsNothing);
      await pump(show: true);
      expect(find.text('DOCUMENT'), findsOneWidget);
    });

    testWidgets('a host leading widget replaces the icon', (tester) async {
      await _pump(
        tester,
        SizedBox(
          height: 64,
          child: SearchResultRow(
            result: const SearchResult(
              id: 'r',
              title: 'Name',
              leading: SizedBox(key: ValueKey('lead'), width: 20, height: 20),
            ),
            onTap: () {},
          ),
        ),
      );
      expect(find.byKey(const ValueKey('lead')), findsOneWidget);
      expect(find.byType(Icon20), findsNothing);
    });
  });

  group('SearchResultsList', () {
    testWidgets('draws a header per section, then its rows', (tester) async {
      final picked = <String>[];
      await _pump(
        tester,
        SearchResultsList(
          sections: _sections(),
          mobile: false,
          active: 1,
          onPick: (r) => picked.add(r.id),
        ),
      );
      expect(find.byKey(const ValueKey('search-group-a')), findsOneWidget);
      expect(find.byKey(const ValueKey('search-group-b')), findsOneWidget);
      expect(find.text('FIRST'), findsOneWidget);
      expect(find.text('SECOND'), findsOneWidget);
      expect(find.byKey(const ValueKey('row-a1')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('row-b1')));
      expect(picked, ['b1']);
    });

    testWidgets('marks only the active row on desktop', (tester) async {
      await _pump(
        tester,
        SearchResultsList(
          sections: _sections(),
          mobile: false,
          active: 2,
          onPick: (_) {},
        ),
      );
      final marked = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .where(
            (box) =>
                box.decoration is BoxDecoration &&
                (box.decoration as BoxDecoration).color ==
                    AppColors.light.bgHover,
          );
      expect(marked, hasLength(1));
    });
  });

  group('SearchTypeChips', () {
    testWidgets('keys chips by id and reports taps', (tester) async {
      final taps = <String>[];
      await _pump(
        tester,
        SearchTypeChips(
          chips: [
            SearchTypeChip(
              id: 'all',
              label: 'All',
              selected: true,
              onTap: () => taps.add('all'),
            ),
            SearchTypeChip(
              id: 'value-x',
              label: 'X',
              selected: true,
              removable: true,
              onTap: () => taps.add('x'),
            ),
          ],
        ),
      );
      expect(find.byKey(const ValueKey('search-type-all')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('search-type-value-x')),
        findsOneWidget,
      );
      // Only the removable chip ends with a close mark.
      expect(find.byType(Icon20), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('search-type-value-x')));
      await tester.tap(find.byKey(const ValueKey('search-type-all')));
      expect(taps, ['x', 'all']);
    });

    testWidgets('a selected chip is filled', (tester) async {
      await _pump(
        tester,
        SearchTypeChips(
          chips: [
            SearchTypeChip(
              id: 'on',
              label: 'On',
              selected: true,
              onTap: () {},
            ),
            SearchTypeChip(
              id: 'off',
              label: 'Off',
              selected: false,
              onTap: () {},
            ),
          ],
        ),
      );
      Color? fill(String id) {
        final box = tester.widget<Container>(
          find.descendant(
            of: find.byKey(ValueKey('search-type-$id')),
            matching: find.byType(Container),
          ),
        );
        return (box.decoration! as BoxDecoration).color;
      }

      expect(fill('on'), AppColors.light.textPrimary);
      expect(fill('off'), isNull);
    });
  });

  group('SearchPanel', () {
    Widget panel({
      required TextEditingController controller,
      required List<SearchResultSection>? sections,
      required List<String> picked,
      Object? reset,
      String? narrowed,
      String? correction,
      ValueChanged<String>? onQuery,
    }) => SizedBox(
      width: 640,
      height: 520,
      child: SearchPanel(
        key: const ValueKey('panel'),
        controller: controller,
        fieldKey: const ValueKey('field'),
        onQueryChanged: onQuery ?? (_) {},
        onPick: (r) => picked.add(r.id),
        sections: sections,
        idleNote: 'Type to search.',
        narrowedNote: narrowed,
        correction: correction,
        selectionResetKey: reset,
        filters: const Text('filters'),
      ),
    );

    testWidgets('arrows move the selection and Enter picks it', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final picked = <String>[];
      await _pump(
        tester,
        panel(
          controller: controller,
          sections: _sections(),
          picked: picked,
        ),
      );
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.enter);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.enter);
      // Past the last row it wraps to the first, and up wraps to the last.
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.enter);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(picked, ['a1', 'b1', 'a1', 'b1']);
    });

    testWidgets('the selection resets when the reset key changes', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final picked = <String>[];
      final sections = _sections();
      Future<void> show(Object reset) => _pump(
        tester,
        panel(
          controller: controller,
          sections: sections,
          picked: picked,
          reset: reset,
        ),
      );
      await show(1);
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.arrowDown);
      // The same key keeps the selection across a rebuild.
      await show(1);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(picked, ['a2']);
      await show(2);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(picked, ['a2', 'a1']);
    });

    testWidgets('says what to do, and when nothing matches', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        panel(controller: controller, sections: null, picked: []),
      );
      expect(find.text('Type to search.'), findsOneWidget);
      expect(find.text('filters'), findsOneWidget);
      await _pump(
        tester,
        panel(controller: controller, sections: const [], picked: []),
      );
      expect(find.text('No results'), findsOneWidget);
      expect(find.text('Type to search.'), findsNothing);
    });

    testWidgets('shows the narrowed and corrected lines', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        panel(
          controller: controller,
          sections: _sections(),
          picked: [],
          narrowed: 'Titles only',
          correction: 'garden',
        ),
      );
      expect(find.text('Titles only'), findsOneWidget);
      final hint = tester.widget<Text>(
        find.byKey(const ValueKey('search-correction-hint')),
      );
      expect(hint.textSpan!.toPlainText(), 'Showing results for garden');
      await _pump(
        tester,
        panel(controller: controller, sections: _sections(), picked: []),
      );
      expect(
        find.byKey(const ValueKey('search-narrowed-hint')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('search-correction-hint')),
        findsNothing,
      );
    });

    testWidgets('typing reports the query; the field takes focus', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final queries = <String>[];
      await _pump(
        tester,
        panel(
          controller: controller,
          sections: null,
          picked: [],
          onQuery: queries.add,
        ),
      );
      await tester.pump();
      await tester.enterText(find.byKey(const ValueKey('field')), 'garden');
      expect(queries, ['garden']);
      expect(controller.text, 'garden');
    });

    testWidgets('a tap on a row picks it', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final picked = <String>[];
      await _pump(
        tester,
        panel(
          controller: controller,
          sections: _sections(),
          picked: picked,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('row-a2')));
      expect(picked, ['a2']);
    });
  });
}
