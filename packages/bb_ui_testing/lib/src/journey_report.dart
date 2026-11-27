import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Physical actions, plus the overlapping [menus] annotation.
class JourneyCounts {
  int taps = 0;
  int textEntries = 0;
  int scrolls = 0;
  int keys = 0;
  int menus = 0;

  /// Menu openings already count as taps and do not increase this sum.
  int get total => taps + textEntries + scrolls + keys;

  Map<String, int> toJson() => {
    'taps': taps,
    'textEntries': textEntries,
    'scrolls': scrolls,
    'keys': keys,
    'menus': menus,
  };
}

/// One goal execution. [failedStep] is one-based; [stepCount] counts successes.
class JourneyRecord {
  JourneyRecord({required this.goal, required this.counts});

  final String goal;
  final JourneyCounts counts;
  int stepCount = 0;
  int? failedStep;

  int get total => counts.total;

  Map<String, Object?> toJson() => {
    'goal': goal,
    'counts': counts.toJson(),
    'total': total,
    'stepCount': stepCount,
    'failedStep': failedStep,
  };
}

/// Collects goal records and optionally persists JSON and per-step PNGs.
///
/// Reuse one report across goals. Its JSON file is rewritten after every goal,
/// including failures. A record is added even when its goal throws.
class JourneyReport {
  JourneyReport({this.path, this.screenshotDirectory});

  final String? path;
  final String? screenshotDirectory;
  final List<JourneyRecord> records = [];

  Map<String, Object?> toJson() => {
    'goals': records.map((record) => record.toJson()).toList(),
  };

  void save() {
    final destination = path;
    if (destination == null) {
      return;
    }
    final file = File(destination);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(toJson())}\n',
    );
  }
}

/// Enforces maxima from `{"goals":{"goal name":{"total":4,"taps":2}}}`.
///
/// Every reported goal needs a budget; omitted count fields are unconstrained.
/// Failures and empty reports cannot pass or update budgets. Repeated goal runs
/// are checked independently; updating stores their maximum for each count.
/// Updating is explicit via [update] or `BB_UI_UPDATE_BUDGETS=1` / `true`.
void checkBudgets(
  JourneyReport report,
  String budgetFile, {
  bool update = false,
}) {
  if (report.records.isEmpty) {
    throw TestFailure('Cannot check budgets: the journey report is empty.');
  }
  for (final record in report.records) {
    if (record.failedStep != null) {
      throw TestFailure(
        'Cannot check budgets: "${record.goal}" failed at step ${record.failedStep}.',
      );
    }
  }
  final environment = Platform.environment['BB_UI_UPDATE_BUDGETS'];
  final shouldUpdate = update || environment == '1' || environment == 'true';
  final file = File(budgetFile);
  final Object? decoded = file.existsSync()
      ? jsonDecode(file.readAsStringSync())
      : <String, Object?>{'goals': <String, Object?>{}};
  if (decoded is! Map<String, dynamic> ||
      decoded.length != 1 ||
      decoded['goals'] is! Map<String, dynamic>) {
    throw FormatException(
      'Budget file must contain a goals object.',
      budgetFile,
    );
  }
  final goals = Map<String, dynamic>.from(decoded['goals'] as Map);
  final overruns = <String>[];
  final updated = <String, Map<String, int>>{};
  for (final record in report.records) {
    final actual = <String, int>{
      ...record.counts.toJson(),
      'total': record.total,
    };
    if (shouldUpdate) {
      final maximum = updated.putIfAbsent(record.goal, () => {...actual});
      for (final entry in actual.entries) {
        if (entry.value > maximum[entry.key]!) {
          maximum[entry.key] = entry.value;
        }
      }
      continue;
    }
    final budget = goals[record.goal];
    if (budget is! Map<String, dynamic> || budget.isEmpty) {
      overruns.add('"${record.goal}": missing budget');
      continue;
    }
    for (final entry in budget.entries) {
      final limit = entry.value;
      if (!actual.containsKey(entry.key) || limit is! int || limit < 0) {
        throw FormatException(
          'Invalid budget ${record.goal}.${entry.key}.',
          budgetFile,
        );
      }
      final observed = actual[entry.key]!;
      if (observed > limit) {
        overruns.add(
          '"${record.goal}" ${entry.key}: $observed > $limit (over by ${observed - limit})',
        );
      }
    }
  }
  if (shouldUpdate) {
    goals.addAll(updated);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert({'goals': goals})}\n',
    );
  } else if (overruns.isNotEmpty) {
    throw TestFailure('Journey budget exceeded:\n${overruns.join('\n')}');
  }
}
