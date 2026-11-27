import 'dart:convert';
import 'dart:io';

import 'package:bb_ui_testing/bb_ui_testing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'route pushes count once; back and long press are physical actions',
    (tester) async {
      var longPresses = 0;
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFFFFFFFF),
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondaryAnimation) => Center(
              child: GestureDetector(
                onTap: () => Navigator.of(context).push<void>(
                  PageRouteBuilder<void>(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        Center(
                          child: Semantics(
                            label: 'Destination',
                            excludeSemantics: true,
                            child: const Text('Next page'),
                          ),
                        ),
                  ),
                ),
                onLongPress: () => longPresses++,
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      );
      final record = await runJourney(tester, {
        'goal': 'Open and return',
        'steps': [
          {
            'tap': {'text': 'Go'},
          },
          {
            'expect': {
              'find': {'semanticsLabel': 'Destination'},
            },
          },
          {'back': null},
          {
            'longPress': {'text': 'Go'},
          },
        ],
      });
      expect(record.counts.taps, 2);
      expect(record.counts.keys, 1);
      expect(record.counts.menus, 1);
      expect(record.total, 3);
      expect(longPresses, 1);
    },
  );

  testWidgets('four physical steps count one menu and persist JSON and PNGs', (
    tester,
  ) async {
    final temporary = Directory.systemTemp.createTempSync('bb-journey-');
    addTearDown(() => temporary.deleteSync(recursive: true));
    await tester.pumpWidget(const _Fixture());
    final report = JourneyReport(
      path: '${temporary.path}/report.json',
      screenshotDirectory: '${temporary.path}/screenshots',
    );
    final record = await runJourney(
      tester,
      decodeJourneyFile('''
goal: Edit a title
steps:
  - tap:
      key: open
  - tap:
      text: Close
  - type:
      find:
        key: title
      text: Updated
  - key: Arrow Left
'''),
      report: report,
    );

    expect(record.counts.toJson(), {
      'taps': 2,
      'textEntries': 1,
      'scrolls': 0,
      'keys': 1,
      'menus': 1,
    });
    expect(record.total, 4);
    expect(record.stepCount, 4);
    expect(record.failedStep, isNull);
    expect(
      tester
          .widget<EditableText>(find.byKey(const ValueKey('title')))
          .controller
          .selection,
      const TextSelection.collapsed(offset: 6),
    );
    final saved = jsonDecode(File(report.path!).readAsStringSync()) as Map;
    expect(saved['goals'], [record.toJson()]);
    final images = Directory(report.screenshotDirectory!)
        .listSync()
        .whereType<File>()
        .toList();
    expect(images.length, 4);
    expect(images.first.readAsBytesSync().take(8), [
      137,
      80,
      78,
      71,
      13,
      10,
      26,
      10,
    ]);
  });

  testWidgets('assertions and waits cost zero and failure records its step', (
    tester,
  ) async {
    final temporary = Directory.systemTemp.createTempSync(
      'bb-journey-failure-',
    );
    addTearDown(() => temporary.deleteSync(recursive: true));
    await tester.pumpWidget(const _Fixture());
    final report = JourneyReport(path: '${temporary.path}/report.json');
    await expectLater(
      () async => runJourney(tester, {
        'goal': 'Check title',
        'steps': [
          {
            'expect': {
              'find': {'key': 'title'},
            },
          },
          {'wait': 0},
          {
            'expect': {
              'find': {'text': 'missing'},
              'present': false,
            },
          },
          {
            'tap': {'key': 'missing'},
          },
        ],
      }, report: report),
      throwsA(isA<TestFailure>()),
    );
    expect(report.records.single.total, 0);
    expect(report.records.single.stepCount, 3);
    expect(report.records.single.failedStep, 4);
    final saved = jsonDecode(File(report.path!).readAsStringSync()) as Map;
    expect((saved['goals'] as List).single['failedStep'], 4);
  });

  testWidgets('scroll counts each drag until a lazy target becomes hittable', (
    tester,
  ) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFFFFFFFF),
        builder: (context, child) => ListView.builder(
          key: const ValueKey('list'),
          itemExtent: 100,
          itemCount: 30,
          itemBuilder: (context, index) => Text('Row $index'),
        ),
      ),
    );
    final record = await runJourney(tester, {
      'goal': 'Find row',
      'steps': [
        {
          'scroll': {
            'find': {'text': 'Row 20'},
            'in': {'key': 'list'},
            'dy': -200,
          },
        },
        {
          'expect': {
            'find': {'text': 'Row 20'},
          },
        },
      ],
    });
    expect(record.counts.scrolls, greaterThan(1));
    expect(record.total, record.counts.scrolls);
    expect(find.text('Row 20').hitTestable(), findsOneWidget);
  });

  testWidgets('exhausted scroll preserves every attempted drag', (
    tester,
  ) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFFFFFFFF),
        builder: (context, child) => ListView(
          key: const ValueKey('list'),
          children: const [Text('Only row')],
        ),
      ),
    );
    final report = JourneyReport();
    await expectLater(
      () async => runJourney(tester, {
        'goal': 'Missing row',
        'steps': [
          {
            'scroll': {
              'find': {'text': 'Missing'},
              'in': {'key': 'list'},
              'maxScrolls': 3,
            },
          },
        ],
      }, report: report),
      throwsA(isA<TestFailure>()),
    );
    expect(report.records.single.counts.scrolls, 3);
    expect(report.records.single.failedStep, 1);
  });

  test('budgets report overruns for total and every constrained count', () {
    final temporary = Directory.systemTemp.createTempSync('bb-budget-');
    addTearDown(() => temporary.deleteSync(recursive: true));
    final budget = File('${temporary.path}/budget.json')
      ..writeAsStringSync(
        jsonEncode({
          'goals': {
            'Edit': {
              'total': 2,
              'taps': 1,
              'textEntries': 0,
              'scrolls': 0,
              'keys': 0,
              'menus': 0,
            },
            'Other': {'total': 0},
          },
        }),
      );
    final report = JourneyReport()
      ..records.addAll([
        JourneyRecord(
          goal: 'Edit',
          counts: JourneyCounts()
            ..taps = 2
            ..textEntries = 1
            ..scrolls = 1
            ..keys = 1
            ..menus = 1,
        ),
        JourneyRecord(goal: 'Other', counts: JourneyCounts()),
      ]);
    expect(
      () => checkBudgets(report, budget.path),
      throwsA(
        isA<TestFailure>().having(
          (failure) => failure.message,
          'overrun details',
          allOf(
            contains('total: 5 > 2 (over by 3)'),
            contains('taps: 2 > 1 (over by 1)'),
            contains('textEntries: 1 > 0 (over by 1)'),
            contains('scrolls: 1 > 0 (over by 1)'),
            contains('keys: 1 > 0 (over by 1)'),
            contains('menus: 1 > 0 (over by 1)'),
          ),
        ),
      ),
    );
    checkBudgets(report, budget.path, update: true);
    checkBudgets(report, budget.path);
    final saved = jsonDecode(budget.readAsStringSync()) as Map;
    expect(saved['goals']['Edit']['total'], 5);
    expect(saved['goals']['Other']['total'], 0);
  });
}

class _Fixture extends StatefulWidget {
  const _Fixture();

  @override
  State<_Fixture> createState() => _FixtureState();
}

class _FixtureState extends State<_Fixture> {
  final controller = TextEditingController();
  final focus = FocusNode();
  final entries = <OverlayEntry>[];

  @override
  void dispose() {
    for (final entry in entries) {
      entry.remove();
      entry.dispose();
    }
    controller.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WidgetsApp(
    color: const Color(0xFFFFFFFF),
    builder: (context, child) => Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) => Column(
            children: [
              GestureDetector(
                key: const ValueKey('open'),
                onTap: () {
                  entries.addAll([
                    OverlayEntry(
                      builder: (_) => const Positioned(
                        left: 0,
                        top: 200,
                        child: Text('Backdrop'),
                      ),
                    ),
                    OverlayEntry(
                      builder: (_) => Positioned(
                        left: 0,
                        top: 100,
                        child: GestureDetector(
                          onTap: () {
                            for (final entry in entries) {
                              entry.remove();
                              entry.dispose();
                            }
                            entries.clear();
                          },
                          child: const Text('Close'),
                        ),
                      ),
                    ),
                  ]);
                  Overlay.of(context).insertAll(entries);
                },
                child: const Text('Open'),
              ),
              EditableText(
                key: const ValueKey('title'),
                controller: controller,
                focusNode: focus,
                style: const TextStyle(),
                cursorColor: const Color(0xFF000000),
                backgroundCursorColor: const Color(0xFFFFFFFF),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
