// Release notes: one single-turn request per release, through whichever
// harness was chosen, cached by the exact prompt so a rerun only asks about
// what changed.

import 'dart:convert';
import 'dart:io';

import 'git.dart';
import 'harness.dart';
import 'versions.dart';

const kinds = ['breaking', 'feature', 'fix', 'docs', 'internal'];

class NoteEntry {
  NoteEntry({required this.kind, required this.text, this.symbols = const []});

  final String kind;
  final String text;

  /// Public API names the entry is about, for the doc and consumer checks.
  final List<String> symbols;

  Map<String, Object?> toJson() => {
    'kind': kind,
    'text': text,
    'symbols': symbols,
  };
}

class Notes {
  Notes({
    required this.release,
    required this.harness,
    this.summary = '',
    this.entries = const [],
    this.error,
    this.cached = false,
  });

  final Release release;
  final String harness;
  final String summary;
  final List<NoteEntry> entries;
  final String? error;
  final bool cached;

  bool get breaking => entries.any((e) => e.kind == 'breaking');

  Map<String, Object?> toJson() => {
    'package': release.package,
    'version': release.version,
    'commit': release.commit,
    'harness': harness,
    'summary': summary,
    'breaking': breaking,
    'entries': [for (final e in entries) e.toJson()],
    'error': error,
  };
}

/// Parses a model reply into entries, dropping malformed ones.
(String, List<NoteEntry>) parseNotes(String reply) {
  final json = extractJsonObject(reply);
  final entries = <NoteEntry>[];
  for (final e in (json['entries'] as List? ?? const [])) {
    if (e is! Map) continue;
    final kind = '${e['kind']}'.toLowerCase();
    final text = e['text'];
    if (!kinds.contains(kind) || text is! String || text.trim().isEmpty) {
      continue;
    }
    entries.add(
      NoteEntry(
        kind: kind,
        text: text.trim(),
        symbols: [
          for (final s in (e['symbols'] as List? ?? const []))
            if (s is String) s,
        ],
      ),
    );
  }
  return ('${json['summary'] ?? ''}'.trim(), entries);
}

/// The prompt for one release: its commits, the files it changed and the
/// diff of the package's public sources, cut to [maxDiff] characters.
String notesPrompt(
  Git git,
  Package package,
  Release release, {
  int maxDiff = 60000,
}) {
  final from = release.previous;
  final range = from == null ? [release.commit] : ['$from..${release.commit}'];
  final rangeDiff = from == null
      ? ['${release.commit}^!']
      : [from, release.commit];
  final log = git.run([
    'log',
    '--format=### %h %s%n%b',
    ...range,
    '--',
    package.dir,
  ]);
  final stat = from == null
      ? ''
      : git.run(['diff', '--stat=120', ...rangeDiff, '--', package.dir]);
  var diff = from == null
      ? ''
      : git.run([
          'diff',
          '--unified=2',
          ...rangeDiff,
          '--',
          '${package.dir}/lib',
          '${package.dir}/bin',
          '${package.dir}/README.md',
        ]);
  if (diff.length > maxDiff) {
    diff = '${diff.substring(0, maxDiff)}\n[diff cut at $maxDiff characters]';
  }
  final title = release.unreleased
      ? 'unreleased changes to ${package.name} after the last version'
      : '${package.name} ${release.version}';
  return '''
You write release notes for a Dart/Flutter package. Answer with one JSON
object and nothing else, in this shape:

{"summary": "one sentence for the whole release",
 "entries": [{"kind": "breaking|feature|fix|docs|internal",
              "text": "one line a consumer of the package can act on",
              "symbols": ["PublicClass", "PublicClass.member"]}]}

Rules:
- "breaking" means code that compiled against the previous version can stop
  compiling or behave differently: removed or renamed public names, new
  required parameters, changed defaults or visuals a test could catch.
- Merge commits that describe one change into one entry.
- "symbols" lists only public names that appear in the diff or the commit
  messages; leave it empty when none do.
- Use "internal" for CI, tests, tooling and refactors with no public effect.
- Do not invent changes that are not in the material below.

# $title
Previous version commit: ${from ?? '(none: first version)'}
Release commit: ${release.commit}

## Commits
$log
## Files changed
$stat
## Diff of public sources
$diff''';
}

String _hash(String s) {
  // Two 32-bit FNV-1a passes with different offsets: stable across runs and
  // platforms, enough to key a cache.
  String fnv(int h) {
    for (final b in utf8.encode(s)) {
      h = ((h ^ b) * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  return fnv(0x811c9dc5) + fnv(0x050c5d1f);
}

/// Writes notes for [releases], asking [harness] for those not in [cacheDir].
Future<List<Notes>> writeNotes(
  Git git,
  Package package,
  List<Release> releases,
  Harness harness, {
  required String cacheDir,
  int jobs = 4,
  int maxDiff = 60000,
  String? promptDir,
}) {
  Directory(cacheDir).createSync(recursive: true);
  if (promptDir != null) Directory(promptDir).createSync(recursive: true);
  return pooled([
    for (final release in releases)
      () async {
        final prompt = notesPrompt(git, package, release, maxDiff: maxDiff);
        final label = '${package.name}-${release.version ?? 'unreleased'}';
        if (promptDir != null) {
          File('$promptDir/$label.txt').writeAsStringSync(prompt);
        }
        final cache = File(
          '$cacheDir/$label-${_hash('${harness.id}\n$prompt')}.txt',
        );
        final cached = cache.existsSync();
        try {
          final reply = cached
              ? cache.readAsStringSync()
              : await harness.complete(prompt);
          final (summary, entries) = parseNotes(reply);
          if (!cached && harness is! EchoHarness) {
            cache.writeAsStringSync(reply);
          }
          return Notes(
            release: release,
            harness: harness.id,
            summary: summary,
            entries: entries,
            cached: cached,
          );
        } on Exception catch (e) {
          return Notes(release: release, harness: harness.id, error: '$e');
        }
      },
  ], jobs);
}
