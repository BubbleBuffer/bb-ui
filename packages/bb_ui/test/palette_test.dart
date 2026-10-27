// The command palette over neutral commands: fuzzy matching, grouping and
// filtering, the keyboard (arrows stop at the ends, Enter, Escape, Tab),
// disabled commands, the empty and no-match states, and showCommandPalette's
// focus restore. Nothing here knows a host's commands.

import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  bool mobile = false,
  bool dark = false,
}) async {
  tester.view.physicalSize = mobile
      ? const Size(390, 800)
      : const Size(900, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    AppTheme(
      colors: dark ? AppColors.darkTheme : AppColors.light,
      formFactor: mobile ? FormFactor.mobile : FormFactor.desktop,
      child: WidgetsApp(
        color: const Color(0xFFFFFFFF),
        pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, animation, secondary) => builder(context),
        ),
        home: home,
      ),
    ),
  );
  // The palette takes focus after its first frame.
  await tester.pump();
}

const _commands = [
  PaletteCommand(id: 'home', title: 'Go home', icon: Ico.home),
  PaletteCommand(
    id: 'new',
    title: 'New page',
    group: 'Pages',
    icon: Ico.compose,
    shortcutLabel: 'Ctrl+N',
  ),
  PaletteCommand(
    id: 'open',
    title: 'Open page',
    subtitle: 'by title',
    group: 'Pages',
  ),
  PaletteCommand(
    id: 'trash',
    title: 'Move to trash',
    group: 'Pages',
    enabled: false,
    disabledReason: 'No page open',
  ),
  PaletteCommand(
    id: 'sidebar',
    title: 'Toggle sidebar',
    group: 'View',
    shortcutLabel: 'Ctrl+B',
  ),
  PaletteCommand(id: 'terminal', title: 'Show terminal', group: 'View'),
];

Finder _row(String id) => find.byKey(ValueKey('palette-row-$id'));

/// Whether the active mark sits on row [id]; the mark exists once.
bool _isActive(WidgetTester tester, String id) {
  final bar = find.byKey(const ValueKey('palette-active-bar'));
  if (bar.evaluate().length != 1) return false;
  return tester.getTopLeft(bar).dy == tester.getTopLeft(_row(id)).dy;
}

/// The ids of the rows drawn, top to bottom.
List<String> _ids(
  WidgetTester tester, [
  List<PaletteCommand> from = _commands,
]) {
  final shown = [
    for (final command in from)
      if (_row(command.id).evaluate().isNotEmpty) command.id,
  ];
  shown.sort(
    (a, b) =>
        tester.getTopLeft(_row(a)).dy.compareTo(tester.getTopLeft(_row(b)).dy),
  );
  return shown;
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump();
}

/// A palette with its callbacks recorded.
class _Probe {
  final ran = <String>[];
  var closed = 0;
  Widget palette({
    List<PaletteCommand> commands = _commands,
    String initialQuery = '',
  }) => CommandPalette(
    commands: commands,
    initialQuery: initialQuery,
    onRun: (c) => ran.add(c.id),
    onClose: () => closed++,
  );
}

void main() {
  group('fuzzyMatch', () {
    test('an empty query matches everything and marks nothing', () {
      final m = fuzzyMatch('  ', 'New page')!;
      expect(m.ranges, isEmpty);
      expect(m.score, 0);
    });

    test('ignores case and spaces in the query', () {
      expect(fuzzyMatch('NEW', 'New page')!.ranges, const [
        TextRange(start: 0, end: 3),
      ]);
      expect(fuzzyMatch('new pa', 'New page')!.ranges, const [
        TextRange(start: 0, end: 3),
        TextRange(start: 4, end: 6),
      ]);
    });

    test('a spread-out match marks each run', () {
      expect(fuzzyMatch('npg', 'New page')!.ranges, const [
        TextRange(start: 0, end: 1),
        TextRange(start: 4, end: 5),
        TextRange(start: 6, end: 7),
      ]);
    });

    test('characters out of order do not match', () {
      expect(fuzzyMatch('wn', 'New'), isNull);
      expect(fuzzyMatch('xyz', 'New page'), isNull);
    });

    test('contiguous beats spread, word start beats mid-word, early wins', () {
      int score(String q, String t) => fuzzyMatch(q, t)!.score;
      expect(score('pag', 'New page'), greaterThan(score('npg', 'New page')));
      expect(score('pa', 'New page'), greaterThan(score('ag', 'New page')));
      expect(score('new', 'New page'), greaterThan(score('page', 'New page')));
      expect(score('s', 'Show'), greaterThan(score('s', 'Toggle sidebar')));
    });
  });

  group('the list', () {
    testWidgets('draws ungrouped rows first, then groups in host order', (
      tester,
    ) async {
      await _pump(tester, _Probe().palette());
      expect(_ids(tester), [
        'home',
        'new',
        'open',
        'trash',
        'sidebar',
        'terminal',
      ]);
      expect(find.text('PAGES'), findsOneWidget);
      expect(find.text('VIEW'), findsOneWidget);
      expect(find.text('Ctrl+N'), findsOneWidget);
      expect(find.text('by title'), findsOneWidget);
      // The first row starts selected.
      expect(_isActive(tester, 'home'), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('typing filters, keeps groups and drops empty ones', (
      tester,
    ) async {
      await _pump(tester, _Probe().palette());
      await _type(tester, 'page');
      expect(_ids(tester), ['new', 'open']);
      expect(find.text('PAGES'), findsOneWidget);
      expect(find.text('VIEW'), findsNothing);
      await _type(tester, 'tgl');
      expect(_ids(tester), ['sidebar']);
      expect(find.text('PAGES'), findsNothing);
      expect(_isActive(tester, 'sidebar'), isTrue);
    });

    testWidgets('the better match comes first within a group', (tester) async {
      const commands = [
        PaletteCommand(id: 'late', title: 'Open recent', group: 'G'),
        PaletteCommand(id: 'early', title: 'Recent files', group: 'G'),
      ];
      await _pump(tester, _Probe().palette(commands: commands));
      expect(_ids(tester, commands), ['late', 'early']);
      await _type(tester, 'rec');
      expect(_ids(tester, commands), ['early', 'late']);
    });

    testWidgets('a subtitle matches, below any title match', (tester) async {
      const commands = [
        PaletteCommand(id: 'a', title: 'Alpha', subtitle: 'about beta'),
        PaletteCommand(id: 'b', title: 'Beta'),
      ];
      await _pump(tester, _Probe().palette(commands: commands));
      await _type(tester, 'beta');
      expect(_ids(tester, commands), ['b', 'a']);
    });

    testWidgets('matches are marked in the title', (tester) async {
      await _pump(tester, _Probe().palette());
      await _type(tester, 'new');
      final text = tester.widget<Text>(
        find.descendant(of: _row('new'), matching: find.byType(Text)).first,
      );
      final root = text.textSpan! as TextSpan;
      final marked = [
        for (final span in root.children!.cast<TextSpan>())
          if (span.style?.backgroundColor != null) span.text,
      ];
      expect(marked, ['New']);
    });

    testWidgets('a long list scrolls to keep the selection in view', (
      tester,
    ) async {
      final commands = [
        for (var i = 0; i < 40; i++)
          PaletteCommand(id: 'c$i', title: 'Command $i'),
      ];
      await _pump(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 560,
            height: 300,
            child: _Probe().palette(commands: commands),
          ),
        ),
      );
      for (var i = 0; i < 25; i++) {
        await _key(tester, LogicalKeyboardKey.arrowDown);
      }
      await tester.pump();
      expect(_row('c25'), findsOneWidget);
      expect(_isActive(tester, 'c25'), isTrue);
      final panel = tester.getRect(find.byType(CommandPalette));
      final row = tester.getRect(_row('c25'));
      expect(row.top, greaterThanOrEqualTo(panel.top));
      expect(row.bottom, lessThanOrEqualTo(panel.bottom));
      for (var i = 0; i < 25; i++) {
        await _key(tester, LogicalKeyboardKey.arrowUp);
      }
      await tester.pump();
      expect(_isActive(tester, 'c0'), isTrue);
    });
  });

  group('the keyboard', () {
    testWidgets('arrows move and stop at the ends', (tester) async {
      await _pump(tester, _Probe().palette());
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_isActive(tester, 'home'), isTrue);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_isActive(tester, 'new'), isTrue);
      for (var i = 0; i < 10; i++) {
        await _key(tester, LogicalKeyboardKey.arrowDown);
      }
      expect(_isActive(tester, 'terminal'), isTrue);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_isActive(tester, 'sidebar'), isTrue);
    });

    testWidgets('Enter runs the selected command once', (tester) async {
      final probe = _Probe();
      await _pump(tester, probe.palette());
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(probe.ran, ['new']);
      await _key(tester, LogicalKeyboardKey.numpadEnter);
      expect(probe.ran, ['new', 'new']);
      expect(probe.closed, 0);
    });

    testWidgets('a tap runs a command', (tester) async {
      final probe = _Probe();
      await _pump(tester, probe.palette());
      await tester.tap(_row('sidebar'));
      await tester.pump();
      expect(probe.ran, ['sidebar']);
    });

    testWidgets('moving the mouse over a row selects it', (tester) async {
      await _pump(tester, _Probe().palette());
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(_row('open')));
      await tester.pump();
      expect(_isActive(tester, 'open'), isTrue);
    });

    testWidgets('Escape asks to close and Tab keeps focus in the field', (
      tester,
    ) async {
      final probe = _Probe();
      await _pump(tester, probe.palette());
      final focused = FocusManager.instance.primaryFocus;
      expect(focused, isNotNull);
      await _key(tester, LogicalKeyboardKey.tab);
      expect(FocusManager.instance.primaryFocus, same(focused));
      expect(probe.closed, 0);
      await _key(tester, LogicalKeyboardKey.escape);
      expect(probe.closed, 1);
      expect(probe.ran, isEmpty);
    });

    testWidgets('the field takes focus on open and shows the focus line', (
      tester,
    ) async {
      await _pump(tester, _Probe().palette());
      expect(find.byKey(const ValueKey('palette-field-focus')), findsOneWidget);
      expect(find.text('Esc'), findsOneWidget);
      expect(find.byKey(const ValueKey('palette-cancel')), findsNothing);
    });
  });

  group('disabled commands', () {
    testWidgets('are listed, can be selected and show why, but never run', (
      tester,
    ) async {
      final probe = _Probe();
      await _pump(tester, probe.palette());
      expect(_row('trash'), findsOneWidget);
      expect(find.text('No page open'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await _key(tester, LogicalKeyboardKey.arrowDown);
      }
      expect(_isActive(tester, 'trash'), isTrue);
      await _key(tester, LogicalKeyboardKey.enter);
      await tester.tap(_row('trash'));
      await tester.pump();
      expect(probe.ran, isEmpty);
      expect(probe.closed, 0);
      // An enabled one still runs afterwards.
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(probe.ran, ['sidebar']);
    });
  });

  group('empty and no-match', () {
    testWidgets('no commands and no match show the note and run nothing', (
      tester,
    ) async {
      final probe = _Probe();
      await _pump(tester, probe.palette(commands: const []));
      expect(find.byKey(const ValueKey('palette-empty')), findsOneWidget);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(probe.ran, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a query nothing matches shows the note, then recovers', (
      tester,
    ) async {
      final probe = _Probe();
      await _pump(tester, probe.palette());
      await _type(tester, 'zzz');
      expect(find.text('No matching commands'), findsOneWidget);
      expect(_ids(tester), isEmpty);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(probe.ran, isEmpty);
      await _type(tester, 'home');
      expect(find.byKey(const ValueKey('palette-empty')), findsNothing);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(probe.ran, ['home']);
    });

    testWidgets('the initial query filters at once', (tester) async {
      await _pump(tester, _Probe().palette(initialQuery: 'term'));
      expect(_ids(tester), ['terminal']);
    });
  });

  group('showCommandPalette', () {
    late BuildContext homeContext;
    late FocusNode homeFocus;
    late List<PaletteCommand> shown;

    Future<void> pumpHome(
      WidgetTester tester, {
      bool mobile = false,
      List<PaletteCommand> commands = _commands,
    }) async {
      shown = commands;
      homeFocus = FocusNode(debugLabel: 'home');
      addTearDown(homeFocus.dispose);
      await _pump(
        tester,
        Focus(
          focusNode: homeFocus,
          autofocus: true,
          child: Builder(
            builder: (context) {
              homeContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
        mobile: mobile,
      );
      await tester.pump();
      expect(homeFocus.hasPrimaryFocus, isTrue);
    }

    Future<PaletteCommand?> open() =>
        showCommandPalette(homeContext, commands: shown);

    testWidgets('Escape closes with nothing and focus goes back', (
      tester,
    ) async {
      await pumpHome(tester);
      final result = open();
      await tester.pumpAndSettle();
      expect(find.byType(CommandPalette), findsOneWidget);
      expect(homeFocus.hasPrimaryFocus, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(await result, isNull);
      expect(find.byType(CommandPalette), findsNothing);
      expect(homeFocus.hasPrimaryFocus, isTrue);
    });

    testWidgets('Enter returns the command after focus is back', (
      tester,
    ) async {
      await pumpHome(tester);
      final result = open();
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'sid');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect((await result)?.id, 'sidebar');
      expect(find.byType(CommandPalette), findsNothing);
      expect(homeFocus.hasPrimaryFocus, isTrue);
    });

    testWidgets('a disabled command keeps the palette open', (tester) async {
      await pumpHome(tester);
      var done = false;
      open().then((_) => done = true);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'trash');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.tap(_row('trash'));
      await tester.pumpAndSettle();
      expect(find.byType(CommandPalette), findsOneWidget);
      expect(done, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(done, isTrue);
    });

    testWidgets('a tap outside closes it', (tester) async {
      await pumpHome(tester);
      final result = open();
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(4, 690));
      await tester.pumpAndSettle();
      expect(await result, isNull);
      expect(homeFocus.hasPrimaryFocus, isTrue);
    });

    testWidgets('the desktop panel is 560 wide near the top', (tester) async {
      await pumpHome(tester);
      open();
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byType(CommandPalette));
      expect(rect.width, 560);
      expect(rect.top, closeTo(700 * 0.14, 1));
      expect(rect.height, lessThanOrEqualTo(700 * 0.6));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    });

    testWidgets('on a phone it fills the screen and Cancel closes it', (
      tester,
    ) async {
      await pumpHome(tester, mobile: true);
      final result = open();
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(CommandPalette)),
        const Rect.fromLTWH(0, 0, 390, 800),
      );
      expect(find.text('Esc'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('palette-cancel')));
      await tester.pumpAndSettle();
      expect(await result, isNull);
      expect(homeFocus.hasPrimaryFocus, isTrue);
    });
  });
}
