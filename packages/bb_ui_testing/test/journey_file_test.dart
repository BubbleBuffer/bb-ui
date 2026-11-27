import 'dart:convert';
import 'dart:io';

import 'package:bb_ui_testing/src/journey_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('JSON and supported YAML describe the same journey', () {
    final expected = <String, dynamic>{
      'goal': "Save a user's #1 note",
      'steps': [
        {
          'type': {
            'find': {'key': 'note'},
            'text': 'A quoted "note"',
          },
        },
        {
          'tap': {'key': 'save'},
        },
        {
          'expect': {
            'find': {'text': 'Saved'},
            'present': true,
          },
        },
        {'wait': 12.5},
        {'back': null},
      ],
    };
    const yaml = r'''
goal: 'Save a user''s #1 note' # outside the string
steps:
  - type:
      find:
        key: note
      text: "A quoted \"note\""
  - tap: {"key": "save"}
  - expect:
      find: {"text": "Saved"}
      present: true
  - wait: 12.5
  - back: ~
''';
    expect(decodeJourneyFile(jsonEncode(expected)), expected);
    expect(decodeJourneyFile(yaml), expected);
  });

  test('loads a file synchronously and accepts empty steps', () {
    final directory = Directory.systemTemp.createTempSync('bb-journey-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/journey.yaml')
      ..writeAsStringSync('goal: Smoke test\nsteps: []\n');
    expect(loadJourneyFile(file.path), {'goal': 'Smoke test', 'steps': []});
  });

  test('preserves plain scalar text and numeric scalar types', () {
    final journey = decodeJourneyFile('''
goal: Don't lose https://example.test/#fragment
steps:
  - key: "Escape" # comment
  - wait: 1e2
  - expect:
      find:
        text: 'false'
      present: false
''');
    expect(journey['goal'], "Don't lose https://example.test/#fragment");
    expect(journey['steps'], [
      {'key': 'Escape'},
      {'wait': 100.0},
      {
        'expect': {
          'find': {'text': 'false'},
          'present': false,
        },
      },
    ]);
  });

  test('reports structural and unsupported YAML errors', () {
    const invalid = [
      '',
      'goal: \nsteps: []',
      'goal: Test\nsteps: {}',
      'goal: Test\nsteps:\n  - tap: {}\n    back: null',
      'goal: Test\nsteps:\n  - explode: null',
      'goal: Test\nsteps: []\nextra: true',
      'goal: Test\ngoal: Again\nsteps: []',
      'goal: Test\nsteps:\n\t- back: null',
      'goal: |\n  Multiline\nsteps: []',
      'goal: &anchor Test\nsteps: []',
      'goal: Test\nsteps: [back: null]',
      ' goal: Indented\n steps: []',
      'goal: Test\nsteps:\n  - tap:\n      key: save\n     text: Oops',
      'goal: "Unclosed\nsteps: []',
    ];
    for (final source in invalid) {
      expect(
        () => decodeJourneyFile(source, sourceName: 'broken.yaml'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            startsWith('broken.yaml:'),
          ),
        ),
        reason: source,
      );
    }
  });
}
