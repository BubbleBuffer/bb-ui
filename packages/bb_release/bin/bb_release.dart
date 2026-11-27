import 'dart:convert';
import 'dart:io';

import 'package:bb_release/bb_release.dart';

const usage = '''
Usage: bb_release <command> [options]

Commands:
  versions    Every version each package released, from its pubspec history.
  consumers   Repositories that pin a package from this one, and how far
              behind they are.
  notes       Release notes per version, written by a coding agent harness.

Common options:
  --repo <dir>        Repository to read (default: the current directory).
  --out <dir>         Report directory (default: <repo>/build/release).
  --package <name>    Only this package; repeatable.

versions:
  --remote-tags       Also read origin's tags (git ls-remote).

consumers:
  --owner <owner>     GitHub owner to search (default: origin's owner).
  --fetch             Download each matched pubspec instead of reading
                      search fragments; needs read access to consumers.
  --no-git-fetch      Do not fetch pinned commits missing from this clone.
  --strict            Exit 1 when a pin is off main or missing.

notes:
  --since <version>   Only versions newer than this one.
  --unreleased        Also write notes for commits after the last bump.
  --harness <name>    claude (default), dsh, command or echo.
  --model <id>        The harness's model id (claude default: haiku).
  --command "<argv>"  For --harness command: prompt on stdin, reply on
                      stdout; {model} is replaced.
  --harness-arg <a>   Extra argument for claude or dsh; repeatable.
                      dsh is one read-only turn; set BB_RELEASE_DSH to its
                      executable (default: dsh on PATH).
  --jobs <n>          Requests in flight at once (default 4).
  --max-diff <n>      Characters of diff per prompt (default 60000).
  --timeout <s>       Seconds per request (default 300).
  --prompts           Also save each prompt under <out>/prompts.
  --internal          Keep internal entries in the CHANGELOG draft.
''';

class Args {
  Args(List<String> argv) {
    for (var i = 0; i < argv.length; i++) {
      final a = argv[i];
      if (!a.startsWith('--')) {
        positional.add(a);
        continue;
      }
      final eq = a.indexOf('=');
      final key = eq > 0 ? a.substring(2, eq) : a.substring(2);
      if (_flags.contains(key)) {
        flags.add(key);
      } else if (eq > 0) {
        options.putIfAbsent(key, () => []).add(a.substring(eq + 1));
      } else if (i + 1 < argv.length) {
        options.putIfAbsent(key, () => []).add(argv[++i]);
      } else {
        throw FormatException('--$key needs a value');
      }
    }
  }

  static const _flags = {
    'remote-tags',
    'fetch',
    'no-git-fetch',
    'strict',
    'unreleased',
    'prompts',
    'internal',
    'help',
  };

  final positional = <String>[];
  final flags = <String>{};
  final options = <String, List<String>>{};

  String? one(String key) => options[key]?.last;
  List<String> all(String key) => options[key] ?? const [];
  bool flag(String key) => flags.contains(key);
}

void _write(String path, String text) {
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(text);
  stdout.writeln('wrote $path');
}

String _json(Object? value) =>
    '${const JsonEncoder.withIndent('  ').convert(value)}\n';

/// Splits a command string on spaces, keeping quoted parts together.
List<String> splitCommand(String s) {
  final out = <String>[];
  final m = RegExp(r'''"([^"]*)"|'([^']*)'|(\S+)''').allMatches(s);
  for (final x in m) {
    out.add(x[1] ?? x[2] ?? x[3]!);
  }
  return out;
}

Future<int> main(List<String> argv) async {
  final Args args;
  try {
    args = Args(argv);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n\n$usage');
    return 2;
  }
  if (args.positional.isEmpty || args.flag('help')) {
    stdout.write(usage);
    return args.flag('help') ? 0 : 2;
  }

  final root = Git(args.one('repo') ?? Directory.current.path)
      .tryRun(['rev-parse', '--show-toplevel'])
      ?.trim();
  if (root == null) {
    stderr.writeln(
      'not a git repository: ${args.one('repo') ?? Directory.current.path}',
    );
    return 2;
  }
  final git = Git(root);
  final out = args.one('out') ?? '$root/build/release';
  final slug = git.originSlug() ?? root.split('/').last;

  var packages = discoverPackages(git);
  final only = args.all('package');
  if (only.isNotEmpty) {
    final unknown = only.where((n) => !packages.any((p) => p.name == n));
    if (unknown.isNotEmpty) {
      stderr.writeln('unknown package: ${unknown.join(', ')}');
      return 2;
    }
  }
  final selected = only.isEmpty
      ? packages
      : packages.where((p) => only.contains(p.name)).toList();

  final tags = tagNames(git, remote: args.flag('remote-tags'));
  Map<String, List<Release>> historyOf(List<Package> list) => {
    for (final p in list) p.name: releases(git, p, tags: tags),
  };

  switch (args.positional.first) {
    case 'versions':
      final history = historyOf(selected);
      _write(
        '$out/versions.json',
        _json({
          'repo': slug,
          'packages': [for (final p in selected) p.toJson()],
          'releases': {
            for (final e in history.entries)
              e.key: [for (final r in e.value) r.toJson()],
          },
        }),
      );
      _write('$out/versions.md', versionsMarkdown(slug, history));
      for (final MapEntry(key: name, value: list) in history.entries) {
        final released = list.where((r) => !r.unreleased).toList();
        final untagged = released.where((r) => r.tags.isEmpty).length;
        final pending = list
            .where((r) => r.unreleased)
            .fold(0, (n, r) => n + r.commits.length);
        stdout.writeln(
          '$name: ${released.length} versions, latest ${released.lastOrNull?.version ?? '-'}'
          ', $untagged untagged, $pending unreleased commits',
        );
      }
      return 0;

    case 'consumers':
      final owner = args.one('owner') ?? slug.split('/').first;
      final List<Pin> pins;
      try {
        pins = GhSearch(owner: owner, fetch: args.flag('fetch')).find(slug);
      } on StateError catch (e) {
        stderr.writeln(e.message);
        return 1;
      }
      final history = historyOf(packages);
      final reports = [
        for (final pin in pins)
          checkPin(
            git,
            pin,
            packages,
            history,
            fetch: !args.flag('no-git-fetch'),
          ),
      ].where((r) => only.isEmpty || only.contains(r.package?.name)).toList();
      _write(
        '$out/consumers.json',
        _json({
          'repo': slug,
          'owner': owner,
          'source': args.flag('fetch') ? 'contents' : 'search fragments',
          'pins': [for (final r in reports) r.toJson()],
        }),
      );
      _write('$out/consumers.md', consumersMarkdown(slug, reports));
      final counts = <PinStatus, int>{};
      for (final r in reports) {
        counts[r.status] = (counts[r.status] ?? 0) + 1;
      }
      stdout.writeln(
        '${reports.length} pins in ${reports.map((r) => r.pin.repo).toSet().length} repositories: '
        '${[for (final s in PinStatus.values)
          if (counts[s] != null) '${counts[s]} ${s.name}'].join(', ')}',
      );
      final bad = reports.where(
        (r) => r.status == PinStatus.offMain || r.status == PinStatus.missing,
      );
      for (final r in bad) {
        stderr.writeln(
          '${r.status.name}: ${r.pin.repo} ${r.pin.file} ${r.pin.ref}',
        );
      }
      return args.flag('strict') && bad.isNotEmpty ? 1 : 0;

    case 'notes':
      final Harness harness;
      try {
        harness = Harness.create(
          args.one('harness') ?? 'claude',
          model: args.one('model'),
          command: splitCommand(args.one('command') ?? ''),
          extra: args.all('harness-arg'),
          timeout: Duration(seconds: int.parse(args.one('timeout') ?? '300')),
        );
      } on HarnessException catch (e) {
        stderr.writeln(e.message);
        return 2;
      }
      final since = args.one('since');
      final all = <Notes>[];
      for (final p in selected) {
        final list = releases(git, p, tags: tags).where((r) {
          if (r.unreleased) return args.flag('unreleased');
          return since == null || compareVersions(r.version!, since) > 0;
        }).toList();
        if (list.isEmpty) continue;
        stdout.writeln(
          '${p.name}: ${list.length} releases through ${harness.id}',
        );
        final notes = await writeNotes(
          git,
          p,
          list,
          harness,
          cacheDir: '$out/cache',
          jobs: int.parse(args.one('jobs') ?? '4'),
          maxDiff: int.parse(args.one('max-diff') ?? '60000'),
          promptDir: args.flag('prompts') ? '$out/prompts' : null,
        );
        for (final n in notes) {
          final state = n.error != null
              ? 'failed: ${n.error}'
              : n.cached
              ? 'cached'
              : '${n.entries.length} entries';
          stdout.writeln('  ${n.release.version ?? 'unreleased'}: $state');
        }
        _write(
          '$out/${p.name}/CHANGELOG.md',
          changelogMarkdown(p.name, notes, internal: args.flag('internal')),
        );
        all.addAll(notes);
      }
      _write(
        '$out/notes.json',
        _json({
          'repo': slug,
          'harness': harness.id,
          'notes': [for (final n in all) n.toJson()],
        }),
      );
      return all.any((n) => n.error != null) ? 1 : 0;
  }
  stderr.writeln('unknown command ${args.positional.first}\n\n$usage');
  return 2;
}
