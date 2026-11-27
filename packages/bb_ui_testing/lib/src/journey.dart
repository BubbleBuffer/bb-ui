import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'journey_report.dart';

const _defaultScrollDy = -200.0;
const _defaultMaxScrolls = 50;

/// Executes a goal with single-action step maps. Selectors contain exactly one
/// of `key` (a String ValueKey), `text`, `tooltip`, or `semanticsLabel`.
///
/// Actions: `tap: selector`, `longPress: selector`,
/// `type: {find: selector, text: value}`, `scroll: {find: selector,
/// in: selector, dx: 0, dy: -200, maxScrolls: 50}`, `key: Escape`, `back: null`,
/// `expect: {find: selector, present: true}`, and `wait: milliseconds`.
/// Long presses count as taps; back counts as a key; assertions and waits cost
/// zero. Each scroll drag counts once, including drags before a failed search.
///
/// Menus annotate `tap` steps that leave at least one newly inserted, onstage
/// OverlayEntry after settling, including standard route pushes. Detection uses
/// public OverlayState diagnostics in widget tests. One tap counts at most one
/// menu, even when a route inserts several entries. Offstage entries, entries
/// inserted and removed within a step and changes within existing entries
/// fall outside the count. Missing diagnostics fail explicitly.
Future<JourneyRecord> runJourney(
  WidgetTester tester,
  Map<String, dynamic> journey, {
  JourneyReport? report,
}) async {
  final goal = journey['goal'];
  final steps = journey['steps'];
  if (goal is! String || goal.trim().isEmpty || steps is! List) {
    throw const FormatException(
      'A journey requires a nonempty goal and steps list.',
    );
  }
  final record = JourneyRecord(goal: goal, counts: JourneyCounts());
  report?.records.add(record);
  final semantics = tester.ensureSemantics();
  var failed = false;
  try {
    for (var index = 0; index < steps.length; index++) {
      record.failedStep = index + 1;
      try {
        await _runStep(tester, steps[index], record.counts);
      } catch (_) {
        // Keep the action failure when capturing its final frame also fails.
        try {
          await _screenshot(tester, report, record, index + 1);
        } catch (_) {
          // The original action exception is the useful failure.
        }
        rethrow;
      }
      await _screenshot(tester, report, record, index + 1);
      record.stepCount++;
      record.failedStep = null;
    }
    return record;
  } catch (_) {
    failed = true;
    rethrow;
  } finally {
    semantics.dispose();
    if (failed) {
      try {
        report?.save();
      } catch (_) {
        // Preserve the action/capture failure if its destination is unwritable.
      }
    } else {
      report?.save();
    }
  }
}

Future<void> _runStep(
  WidgetTester tester,
  Object? step,
  JourneyCounts counts,
) async {
  final map = _map(step, 'step');
  if (map.length != 1) {
    throw const FormatException('Each step needs one action.');
  }
  final action = map.keys.single;
  final value = map[action];
  switch (action) {
    case 'tap':
    case 'longPress':
      final target = _unique(_find(value).hitTestable());
      final before = action == 'tap' ? _entries(visibleOnly: false) : null;
      counts.taps++;
      if (action == 'tap') {
        await tester.tap(target, warnIfMissed: true);
      } else {
        await tester.longPress(target, warnIfMissed: true);
      }
      await tester.pumpAndSettle();
      if (before != null &&
          _entries(visibleOnly: true).difference(before).isNotEmpty) {
        counts.menus++;
      }
      return;
    case 'type':
      final config = _config(value, {'find', 'text'}, {'find', 'text'});
      final text = config['text'];
      if (text is! String) {
        throw const FormatException('type.text must be a string.');
      }
      final target = _unique(_find(config['find']));
      counts.textEntries++;
      await tester.enterText(target, text);
      await tester.pumpAndSettle();
      return;
    case 'scroll':
      final config = _config(
        value,
        {'find', 'in', 'dx', 'dy', 'maxScrolls'},
        {'find', 'in'},
      );
      final target = _find(config['find']);
      final container = _unique(_find(config['in']));
      final dx = _number(config['dx'] ?? 0, 'scroll.dx');
      final dy = _number(config['dy'] ?? _defaultScrollDy, 'scroll.dy');
      final maximum = _integer(
        config['maxScrolls'] ?? _defaultMaxScrolls,
        'scroll.maxScrolls',
      );
      if (dx == 0 && dy == 0) {
        throw const FormatException('Scroll offset cannot be zero.');
      }
      var gestures = 0;
      while (target.hitTestable().evaluate().isEmpty && gestures < maximum) {
        counts.scrolls++;
        gestures++;
        await tester.drag(container, Offset(dx, dy));
        await tester.pumpAndSettle();
      }
      expect(
        target.hitTestable(),
        findsOneWidget,
        reason: 'Scroll target must become visible.',
      );
      return;
    case 'key':
      final key = _key(value);
      counts.keys++;
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      return;
    case 'back':
      if (value != null) {
        throw const FormatException('back must have a null value.');
      }
      counts.keys++;
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.navigation.name,
        SystemChannels.navigation.codec.encodeMethodCall(
          const MethodCall('popRoute'),
        ),
        null,
      );
      await tester.pumpAndSettle();
      return;
    case 'expect':
      final config = _config(value, {'find', 'present'}, {'find'});
      final present = config['present'] ?? true;
      if (present is! bool) {
        throw const FormatException('expect.present must be boolean.');
      }
      expect(_find(config['find']), present ? findsWidgets : findsNothing);
      return;
    case 'wait':
      await tester.pump(Duration(milliseconds: _integer(value, 'wait')));
      return;
    default:
      throw FormatException('Unknown journey action: $action.');
  }
}

Map<String, dynamic> _map(Object? value, String name) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw FormatException('$name must be an object.');
  }
  return Map<String, dynamic>.from(value);
}

Map<String, dynamic> _config(
  Object? value,
  Set<String> allowed,
  Set<String> required,
) {
  final config = _map(value, 'action configuration');
  if (!allowed.containsAll(config.keys) ||
      !config.keys.toSet().containsAll(required)) {
    throw FormatException(
      'Expected required keys $required and only keys $allowed.',
    );
  }
  return config;
}

Finder _find(Object? value) {
  final selector = _map(value, 'selector');
  if (selector.length != 1 || selector.values.single is! String) {
    throw const FormatException(
      'A selector needs exactly one string property.',
    );
  }
  final text = selector.values.single as String;
  return switch (selector.keys.single) {
    'key' => find.byKey(ValueKey<String>(text)),
    'text' => find.text(text),
    'tooltip' => find.byTooltip(text),
    'semanticsLabel' => find.bySemanticsLabel(text),
    _ => throw FormatException('Unknown selector: ${selector.keys.single}.'),
  };
}

Finder _unique(Finder target) {
  expect(
    target,
    findsOneWidget,
    reason: 'Journey action needs exactly one target.',
  );
  return target;
}

double _number(Object? value, String name) {
  if (value is! num || !value.isFinite) {
    throw FormatException('$name must be finite.');
  }
  return value.toDouble();
}

int _integer(Object? value, String name) {
  if (value is! int || value < 0) {
    throw FormatException('$name must be a nonnegative integer.');
  }
  return value;
}

LogicalKeyboardKey _key(Object? value) {
  if (value is! String || value.isEmpty) {
    throw const FormatException('key must be a key name.');
  }
  final normalized = value.replaceAll(' ', '').toLowerCase();
  for (final key in LogicalKeyboardKey.knownLogicalKeys) {
    if (key.keyLabel.replaceAll(' ', '').toLowerCase() == normalized ||
        key.debugName?.replaceAll(' ', '').toLowerCase() == normalized) {
      return key;
    }
  }
  throw FormatException('Unknown logical key: $value.');
}

Set<OverlayEntry> _entries({required bool visibleOnly}) {
  final entries = <OverlayEntry>{};
  for (final element
      in find.bySubtype<Overlay>(skipOffstage: visibleOnly).evaluate()) {
    final overlay = (element as StatefulElement).state as OverlayState;
    List<OverlayEntry>? overlayEntries;
    for (final property in overlay.toDiagnosticsNode().getProperties()) {
      final value = property.value;
      if (value is List<OverlayEntry>) {
        overlayEntries = value;
      }
    }
    if (overlayEntries == null) {
      throw UnsupportedError(
        'Journey menu counting requires OverlayState entry diagnostics in debug tests.',
      );
    }
    for (final entry in overlayEntries.reversed) {
      if (!visibleOnly || entry.mounted) {
        entries.add(entry);
      }
      if (visibleOnly && entry.opaque) {
        break;
      }
    }
  }
  return entries;
}

Future<void> _screenshot(
  WidgetTester tester,
  JourneyReport? report,
  JourneyRecord record,
  int step,
) async {
  final directory = report?.screenshotDirectory;
  if (directory == null) {
    return;
  }
  final slug = record.goal.replaceAll(RegExp('[^a-zA-Z0-9_-]+'), '_');
  final run = report!.records.length;
  final result = await tester.runAsync(() async {
    try {
      final image = await captureImage(tester.binding.rootElement!);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null) {
          throw StateError('Could not encode journey screenshot.');
        }
        final file = File('$directory/$run-$slug-step-$step.png');
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
      } finally {
        image.dispose();
      }
      return (error: null, stack: null);
    } catch (error, stack) {
      // runAsync otherwise reports callback errors to the test binding directly.
      return (error: error, stack: stack);
    }
  });
  if (result == null) {
    throw StateError('Journey screenshot capture did not complete.');
  }
  if (result.error != null) {
    Error.throwWithStackTrace(result.error!, result.stack!);
  }
}
