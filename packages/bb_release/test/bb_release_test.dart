import 'dart:convert';
import 'dart:io';

import 'package:bb_release/bb_release.dart';
import 'package:test/test.dart';

/// A scratch repository with a package that bumps its version, a commit
/// between bumps, and a side branch that never reaches main.
class Scratch {
  Scratch() : dir = Directory.systemTemp.createTempSync('bb_release_test_') {
    git = Git(dir.path);
    git.run(['init', '--quiet', '--initial-branch=main']);
    git.run(['config', 'user.email', 'test@example.com']);
    git.run(['config', 'user.name', 'test']);
    git.run(['config', 'commit.gpgsign', 'false']);
  }

  final Directory dir;
  late final Git git;

  String commit(Map<String, String> files, String message) {
    for (final MapEntry(:key, :value) in files.entries) {
      File('${dir.path}/$key')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(value);
    }
    git.run(['add', '-A']);
    git.run(['commit', '--quiet', '-m', message]);
    return git.run(['rev-parse', 'HEAD']).trim();
  }

  void dispose() => dir.deleteSync(recursive: true);
}

String pubspec(String version) => 'name: kit\nversion: $version\n';

void main() {
  group('pubspec fields', () {
    test('version and name', () {
      expect(pubspecVersion("name: a\nversion: '1.2.3' # note\n"), '1.2.3');
      expect(pubspecVersion('name: a\n'), isNull);
      expect(pubspecName('name: bb_ui\nversion: 1.0.0\n'), 'bb_ui');
    });

    test('pull request numbers', () {
      expect(prNumber('Add the palette (0.6.0) (#3)'), 3);
      expect(prNumber('Merge pull request #13 from owner/branch'), 13);
      expect(prNumber('0.9.0: tokens'), isNull);
    });

    test('version order', () {
      expect(compareVersions('0.10.0', '0.9.1'), greaterThan(0));
      expect(compareVersions('1.0.0', '1.0'), 0);
      expect(compareVersions('1.0.0-dev.1', '1.0.0'), 0);
    });

    test('tags naming a version', () {
      expect(tagsFor('kit', '1.0.0', {'v1.0.0', 'kit-v1.0.0', 'v1.0.1'}), [
        'v1.0.0',
        'kit-v1.0.0',
      ]);
    });

    test('GitHub slugs', () {
      expect(githubSlug('https://github.com/acme/kit.git'), 'acme/kit');
      expect(githubSlug('git@github.com:acme/kit'), 'acme/kit');
      expect(githubSlug('https://example.com/acme/kit'), isNull);
    });
  });

  group('parsePins', () {
    test('a whole pubspec', () {
      const text = '''
dependencies:
  kit:
    git:
      url: https://github.com/acme/kit
      ref: abc1234 # v1.0.0
      path: packages/kit
  other:
    git:
      url: https://github.com/acme/other
      ref: main
''';
      final pins = parsePins(
        text,
        repo: 'acme/app',
        file: 'pubspec.yaml',
        slug: 'acme/kit',
      );
      expect(pins, hasLength(1));
      expect(pins.single.dependency, 'kit');
      expect(pins.single.ref, 'abc1234');
      expect(pins.single.comment, 'v1.0.0');
      expect(pins.single.path, 'packages/kit');
    });

    test('a search fragment that starts inside the git map', () {
      const text = '''
    git:
      url: https://github.com/ACME/kit.git
      ref: "abc1234"
''';
      final pin = parsePins(
        text,
        repo: 'acme/app',
        file: 'pubspec.yaml',
        slug: 'acme/kit',
      ).single;
      expect(pin.dependency, isNull);
      expect(pin.ref, 'abc1234');
      expect(pin.path, isNull);
    });

    test('keys before url and no ref', () {
      const text = '''
  kit:
    git:
      path: packages/kit
      url: https://github.com/acme/kit
''';
      final pin = parsePins(
        text,
        repo: 'acme/app',
        file: 'pubspec.yaml',
        slug: 'acme/kit',
      ).single;
      expect(pin.dependency, 'kit');
      expect(pin.path, 'packages/kit');
      expect(pin.ref, isNull);
    });
  });

  group('model replies', () {
    test('JSON inside prose and fences', () {
      const reply =
          'Here you go:\n```json\n{"summary": "a {b}", "entries": [{"kind": "Fix", "text": "x \\"y\\"", "symbols": ["A"]}, {"kind": "nope", "text": "z"}]}\n```';
      final (summary, entries) = parseNotes(reply);
      expect(summary, 'a {b}');
      expect(entries, hasLength(1));
      expect(entries.single.kind, 'fix');
      expect(entries.single.text, 'x "y"');
      expect(entries.single.symbols, ['A']);
    });

    test('no JSON', () {
      expect(() => extractJsonObject('sorry'), throwsFormatException);
    });

    test('pooled keeps order', () async {
      final out = await pooled([
        for (var i = 0; i < 5; i++)
          () => Future.delayed(Duration(milliseconds: 5 - i), () => i),
      ], 2);
      expect(out, [0, 1, 2, 3, 4]);
    });
  });

  group('history and pins', () {
    late Scratch s;
    late String v1, between, v2, side;

    setUp(() {
      s = Scratch();
      v1 = s.commit({
        'kit/pubspec.yaml': pubspec('1.0.0'),
        'kit/lib/a.dart': '// a\n',
      }, 'Release 1.0.0 (#1)');
      s.commit({'README.md': 'outside the package\n'}, 'Docs');
      between = s.commit({'kit/lib/a.dart': '// a2\n'}, 'Change a');
      v2 = s.commit({
        'kit/pubspec.yaml': pubspec('1.1.0'),
      }, 'Release 1.1.0 (#2)');
      s.git.run(['checkout', '--quiet', '-b', 'side', v1]);
      side = s.commit({'kit/lib/b.dart': '// b\n'}, 'Side work');
      s.git.run(['checkout', '--quiet', 'main']);
      s.git.run(['tag', 'v1.0.0', v1]);
      s.commit({'kit/lib/c.dart': '// c\n'}, 'After 1.1.0');
    });

    tearDown(() => s.dispose());

    test('versions come from pubspec bumps', () {
      final package = discoverPackages(s.git).single;
      expect(package.dir, 'kit');
      final list = releases(s.git, package, tags: tagNames(s.git));
      expect([for (final r in list) r.version], ['1.0.0', '1.1.0', null]);
      expect(list[0].tags, ['v1.0.0']);
      expect(list[1].tags, isEmpty);
      expect(
        [for (final c in list[1].commits) c.subject],
        ['Release 1.1.0 (#2)', 'Change a'],
      );
      expect(list[1].commits.first.pr, 2);
      expect(list[2].unreleased, isTrue);
      expect(list[2].commits.single.subject, 'After 1.1.0');
    });

    PinReport check(String? ref, {String? path = 'kit'}) {
      final packages = discoverPackages(s.git);
      final history = {for (final p in packages) p.name: releases(s.git, p)};
      return checkPin(
        s.git,
        Pin(repo: 'acme/app', file: 'pubspec.yaml', ref: ref, path: path),
        packages,
        history,
        fetch: false,
      );
    }

    test('a pin on the latest release is current', () {
      final r = check(v2);
      expect(r.status, PinStatus.current);
      expect(r.version, '1.1.0');
      expect(r.commitsBehind, 1);
      expect(r.note, contains('unreleased'));
    });

    test('an older pin is behind', () {
      final r = check(between);
      expect(r.status, PinStatus.behind);
      expect(r.version, '1.0.0');
      expect(r.latest, '1.1.0');
      expect(r.releasesBehind, 1);
    });

    test('a tag pin resolves', () {
      expect(check('v1.0.0').version, '1.0.0');
    });

    test('a side-branch pin is off main', () {
      final r = check(side);
      expect(r.status, PinStatus.offMain);
      expect(r.note, contains('forked at ${v1.substring(0, 7)}'));
    });

    test('unknown refs and no ref', () {
      expect(
        check('0000000000000000000000000000000000000000').status,
        PinStatus.missing,
      );
      expect(check(null).status, PinStatus.unpinned);
    });

    test('an unknown package counts every commit', () {
      final r = check(between, path: 'elsewhere');
      expect(r.package, isNull);
      expect(r.status, PinStatus.behind);
      expect(r.commitsBehind, 2);
    });
  });

  group('dsh events', () {
    String events(List<Map<String, Object?>> list) =>
        list.map(jsonEncode).join('\n');
    Map<String, Object?> status(String phase, [Object? reason]) => {
      'type': 'status',
      'phase': phase,
      'reason': ?reason,
    };
    Map<String, Object?> text(String t) => {'type': 'text', 'text': t};
    Map<String, Object?> fin(Object reason, [String? t]) => {
      'type': 'final',
      'reason': reason,
      'text': ?t,
    };

    test('reply text and failures', () {
      const done = {'kind': 'completed'};
      // The final event carries the whole reply.
      expect(
        dshReply(
          events([
            status('turn_start'),
            text('{"summary":"a"}'),
            status('turn_end', done),
            fin(done, '{"summary":"a"}'),
          ]),
        ),
        '{"summary":"a"}',
      );
      // Without a final event the text events are joined.
      expect(
        dshReply(events([text('{"summary":'), text('"b"}')])),
        '{"summary":"b"}',
      );
      // A run that did not complete is an error, and so is an empty one.
      expect(
        () => dshReply(
          events([
            status('turn_end', {'kind': 'timeout'}),
          ]),
        ),
        throwsA(predicate((e) => '$e'.contains('timeout'))),
      );
      expect(() => dshReply(''), throwsA(isA<HarnessException>()));
    });
  });
}
