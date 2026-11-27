# Widget coverage and test journeys

Add `bb_ui_testing` to a Flutter app with a Git dev dependency. Pin it to a
reviewed commit that contains the package. It uses the Flutter SDK and
`flutter_test`, requires Dart 3.13.4 or another compatible 3.x release, and
can run with your app's existing `bb_ui` pin.

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  bb_ui_testing:
    git:
      url: https://github.com/BubbleBuffer/bb-ui
      ref: <reviewed-commit>
      path: packages/bb_ui_testing
```

Run `flutter pub get` in the app before using either tool.

## Widget coverage

```sh
flutter test --coverage
dart run bb_ui_testing:coverage \
  --lcov coverage/lcov.info --allow coverage-allowlist.txt \
  --json build/widget-coverage.json --md build/widget-coverage.md
```

The tool lists classes declared in Dart files under `lib/` that extend
`StatelessWidget`, `StatefulWidget`, or another widget class discovered in the
same scan. Use `--private` to include classes whose names start with `_`.

With `--lcov`, the tool counts a widget as covered when the current test run
hit an executable line in its `build` body. For a stateful widget, it looks
for a class extending `State<WidgetName>` and checks that class's `build`. If
the scan finds the state class but cannot find its `build` body, any executed
line in that state class body counts. Use a report generated from the same
source revision you scan. The per-widget `hit` field records whether the scan
found a positive line hit. LCOV mode uses executed lines alone, so tests can
find widgets by key, text, or other properties.

### Source references

Omit `--lcov` to scan `test/` for references, or set another path with `--test`.
A widget is covered when its exact class name appears in a UTF-8 text file under
`test/`, including within a test description. To count golden files, pass
`--goldens FILE` with a JSON object that maps widget class names to PNG
basenames. You can give one basename or a list. A listed PNG found anywhere
under `test/` covers its widget.

```json
{
  "SearchPanel": "search_panel.png",
  "DeviceRow": ["device_row_light.png", "device_row_dark.png"]
}
```

### Reports and allowlists

The command prints a table and writes reports at the supplied `--json` and
`--md` paths. With no arguments it scans `lib/` and `test/` and uses
`coverage-allowlist.txt` if present. Use one widget name per line in the allowlist.
Blank lines and comments starting with `#` are ignored. If the default
`test/` directory is absent, the tool treats it as empty.

Exit code 1 means an uncovered widget needs a test or the allowlist has a stale
entry. Delete an entry when its widget gains coverage or leaves the scan. The
bb-ui test job collects LCOV for `packages/bb_ui`, checks its allowlist, and
publishes the LCOV file and both reports with the CI run.

## Test journeys

Put a journey under your app's `test/` directory. Give it a `goal` and a list of
`steps`, each with one action.

```yaml
goal: Save a note
steps:
  - tap:
      key: new-note
  - type:
      find:
        key: note-editor
      text: "Pick up the keys"
  - tap:
      tooltip: Save
  - expect:
      find:
        text: Note saved
```

Use `loadJourneyFile` with a YAML or JSON file, or pass the equivalent Dart map
directly to `runJourney`. JSON uses the same keys and values. YAML supports
space-indented maps and lists, comments, plain and single-quoted strings,
JSON-style double-quoted strings, booleans, nulls, numbers, and inline JSON
objects and arrays. Indent nested lists under their keys. Use JSON for more
complex string escaping or structure.

Pump your app as in any widget test, then run the journey.

```dart
import 'package:bb_ui_testing/bb_ui_testing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/app.dart';

void main() {
  testWidgets('save a note', (tester) async {
    await tester.pumpWidget(const App());
    final report = JourneyReport(
      path: 'build/journeys/report.json',
      screenshotDirectory: 'build/journeys/screenshots',
    );
    await runJourney(
      tester,
      loadJourneyFile('test/journeys/save_note.yaml'),
      report: report,
    );
    checkBudgets(report, 'test/journeys/budgets.json');
  });
}
```

Run it with `flutter test test/journeys_test.dart`. Reuse a report within a test
to collect multiple goals. Omit `screenshotDirectory` to skip PNGs and `path` to
keep the records in memory. Give test files that run in parallel distinct
output paths.

### Step reference

A finder is a map with exactly one string field. Use `key` for a
`ValueKey<String>`, `text` for exact widget text, `tooltip` for a tooltip
message, or `semanticsLabel` for an exact semantics label.

| Step | Value |
| --- | --- |
| `tap` | A finder for the target. |
| `longPress` | A finder for the target. |
| `type` | `find` for the editable target and `text` for the replacement string. |
| `scroll` | `find` for the target and `in` for the drag surface. Optional `dx` and `dy` are drag offsets in logical pixels, defaulting to `0` and `-200`. Optional `maxScrolls` defaults to `50`. Drags stop when the target is hit-testable. |
| `key` | A Flutter logical key name such as `Enter`, `Escape`, or `Arrow Down`. Case and spaces are ignored. |
| `back` | `null`. Dispatches the platform back request through the test binding. |
| `expect` | `find` for the target. Checks for at least one match. Set `present: false` to check for zero matches. |
| `wait` | A nonnegative integer in milliseconds. Advances the widget test clock. |

### Counts and reports

- `taps` counts taps and long presses.
- `textEntries` counts text entry steps.
- `scrolls` counts individual drag gestures, including those in an unsuccessful
  search. A target already within reach costs zero gestures.
- `keys` counts logical key presses and platform back requests.
- `menus` counts taps that leave a new onstage `OverlayEntry` after the widget
  tree settles. The driver compares entry identities from Flutter's debug
  `OverlayState` diagnostics before and after the tap. It considers mounted
  entries from the front of each onstage overlay through its first opaque
  entry. Standard route pushes insert entries too. One tap can add at most one
  menu, even if several entries appear. Long presses, changes within an
  existing entry such as inline menus and `OverlayPortal` content, and entries
  that disappear before settling are outside this count.

`expect` and `wait` add no actions. The total is the sum of `taps`,
`textEntries`, `scrolls`, and `keys`. Menu openings already contribute through
`taps`.

The JSON report has a `goals` array with a record for each run. Each record
contains `goal`, `counts`, `total`, `stepCount` (completed steps), and
`failedStep` (a one-based step number or `null`). The driver saves the record
when a step fails and propagates the failure. With screenshots enabled, it
captures a PNG after each attempted step.

### Budgets

Commit a JSON file with a `goals` map. Each goal can cap the total and
individual counts.

```json
{
  "goals": {
    "Save a note": {
      "total": 3,
      "taps": 2,
      "textEntries": 1,
      "scrolls": 0,
      "keys": 0,
      "menus": 1
    }
  }
}
```

`checkBudgets` fails if a goal has no budget or exceeds any of its limits. Each
overrun includes the goal, count, actual value, limit, and difference. To update
the budgets for the goals in the current report, run the test with
`BB_UI_UPDATE_BUDGETS=1` or pass `update: true` to `checkBudgets` in the test.
Run updates with `--concurrency=1` if multiple test files share the budget file.
Review the budget diff before committing it.
