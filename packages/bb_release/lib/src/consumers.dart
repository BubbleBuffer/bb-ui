// Downstream pins: repositories whose pubspec takes a package from this
// repository by git, which ref they pin, and how that ref relates to the
// default branch here.

import 'dart:convert';
import 'dart:io';

import 'git.dart';
import 'versions.dart';

/// One git dependency on this repository found in a consumer's pubspec.
class Pin {
  Pin({
    required this.repo,
    required this.file,
    this.dependency,
    this.ref,
    this.path,
    this.comment,
  });

  /// owner/name of the consumer.
  final String repo;

  /// Path of the pubspec inside the consumer.
  final String file;

  /// The dependency key (`bb_ui:`) when the source showed it.
  final String? dependency;
  final String? ref;

  /// The `path:` inside this repository, when given.
  final String? path;

  /// A trailing comment on the ref line, often a version a person wrote.
  final String? comment;
}

final _url = RegExp(r'^(\s*)(?:-\s*)?url:\s*["\x27]?([^"\x27\s#]+)');
final _key = RegExp(r'^(\s*)([A-Za-z0-9_]+):\s*(.*?)\s*$');

int _indent(String line) => line.length - line.trimLeft().length;

(String value, String? comment) _value(String raw) {
  final hash = raw.indexOf(' #');
  var value = hash >= 0 ? raw.substring(0, hash) : raw;
  final comment = hash >= 0 ? raw.substring(hash + 2).trim() : null;
  value = value.trim();
  if (value.length >= 2 &&
      (value[0] == '"' || value[0] == "'") &&
      value[value.length - 1] == value[0]) {
    value = value.substring(1, value.length - 1);
  }
  return (value, comment);
}

/// Finds git dependencies on [slug] in a pubspec or a fragment of one.
///
/// Fragments from code search can start or stop mid-block, so each `url:`
/// line is read with only the lines around it: the keys at its indent below
/// it, and the dependency name two levels above.
List<Pin> parsePins(
  String text, {
  required String repo,
  required String file,
  required String slug,
}) {
  final lines = const LineSplitter().convert(text);
  final pins = <Pin>[];
  for (var i = 0; i < lines.length; i++) {
    final m = _url.firstMatch(lines[i]);
    if (m == null) continue;
    if (githubSlug(m[2]!)?.toLowerCase() != slug.toLowerCase()) continue;
    final indent = m[1]!.length;

    String? ref, path, comment, dependency;
    // Siblings of url: inside the git: map, before and after it.
    for (final dir in [-1, 1]) {
      for (var j = i + dir; j >= 0 && j < lines.length; j += dir) {
        final line = lines[j];
        if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
        if (_indent(line) != indent) break;
        final k = _key.firstMatch(line);
        if (k == null) break;
        final (value, c) = _value(k[3]!);
        if (k[2] == 'ref') {
          ref = value;
          comment = c;
        } else if (k[2] == 'path') {
          path = value;
        }
      }
    }
    // Up to git:, then up to the dependency key.
    var level = indent;
    var seenGit = false;
    for (var j = i - 1; j >= 0; j--) {
      final line = lines[j];
      if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
      final n = _indent(line);
      if (n >= level) continue;
      final k = _key.firstMatch(line);
      if (k == null) break;
      if (!seenGit) {
        if (k[2] != 'git') break;
        seenGit = true;
        level = n;
        continue;
      }
      dependency = k[2];
      break;
    }
    pins.add(
      Pin(
        repo: repo,
        file: file,
        dependency: dependency,
        ref: ref,
        path: path,
        comment: comment,
      ),
    );
  }
  return pins;
}

/// A source of pubspec text in other repositories.
abstract class PinSource {
  List<Pin> find(String slug);
}

/// GitHub code search through the gh CLI. By default it reads the matched
/// fragments only; with [fetch] it downloads each matched pubspec whole,
/// which needs read access to the consumer's contents.
class GhSearch implements PinSource {
  GhSearch({required this.owner, this.fetch = false, this.extraQuery = ''});

  final String owner;
  final bool fetch;
  final String extraQuery;

  List<String> _gh(List<String> args) {
    final r = Process.runSync('gh', args);
    if (r.exitCode != 0) {
      throw StateError(
        'gh ${args.join(' ')} failed: ${(r.stderr as String).trim()}',
      );
    }
    return const LineSplitter()
        .convert(r.stdout as String)
        .where((l) => l.isNotEmpty)
        .toList();
  }

  @override
  List<Pin> find(String slug) {
    final name = slug.split('/').last;
    final q = 'org:$owner $name filename:pubspec.yaml $extraQuery'.trim();
    final items = _gh([
      'api',
      '-X',
      'GET',
      'search/code',
      '--paginate',
      '-H',
      'Accept: application/vnd.github.text-match+json',
      '-f',
      'q=$q',
      '-f',
      'per_page=100',
      '--jq',
      '.items[] | @json',
    ]).map((l) => jsonDecode(l) as Map<String, Object?>);

    final pins = <Pin>[];
    for (final item in items) {
      final repo = (item['repository'] as Map)['full_name'] as String;
      final file = item['path'] as String;
      if (repo.toLowerCase() == slug.toLowerCase()) continue;
      if (!file.endsWith('pubspec.yaml')) continue;
      final texts = <String>[];
      if (fetch) {
        texts.add(
          _gh([
            'api',
            '-H',
            'Accept: application/vnd.github.raw',
            'repos/$repo/contents/$file',
          ]).join('\n'),
        );
      } else {
        for (final t in (item['text_matches'] as List? ?? const [])) {
          texts.add((t as Map)['fragment'] as String);
        }
      }
      final found = <String>{};
      for (final text in texts) {
        for (final pin in parsePins(text, repo: repo, file: file, slug: slug)) {
          // Overlapping fragments repeat a block; keep one of each.
          if (found.add('${pin.dependency}|${pin.path}|${pin.ref}')) {
            pins.add(pin);
          }
        }
      }
    }
    pins.sort((a, b) => '${a.repo}/${a.file}'.compareTo('${b.repo}/${b.file}'));
    return pins;
  }
}

enum PinStatus {
  /// Pins the default branch's newest release of the package.
  current,

  /// Pins an older commit on the default branch.
  behind,

  /// Pins a commit the default branch does not contain. GitHub may delete
  /// such commits, which breaks the consumer's `pub get`.
  offMain,

  /// The ref resolves to nothing here.
  missing,

  /// No ref: the consumer follows the default branch through its lockfile.
  unpinned,
}

class PinReport {
  PinReport({
    required this.pin,
    required this.status,
    this.package,
    this.commit,
    this.version,
    this.latest,
    this.releasesBehind = 0,
    this.commitsBehind = 0,
    this.note,
  });

  final Pin pin;
  final PinStatus status;

  /// The package of this repository the pin takes, when it can be told.
  final Package? package;
  final String? commit;

  /// The package version at the pinned commit.
  final String? version;

  /// The newest released version on the default branch.
  final String? latest;
  final int releasesBehind;

  /// Commits touching the package between the pin and the default branch.
  final int commitsBehind;
  final String? note;

  Map<String, Object?> toJson() => {
    'repo': pin.repo,
    'file': pin.file,
    'dependency': pin.dependency,
    'path': pin.path,
    'ref': pin.ref,
    'refComment': pin.comment,
    'status': status.name,
    'package': package?.name,
    'commit': commit,
    'version': version,
    'latest': latest,
    'releasesBehind': releasesBehind,
    'commitsBehind': commitsBehind,
    'note': note,
  };
}

final _sha = RegExp(r'^[0-9a-f]{7,40}$');

/// Which package a pin takes: by its `path:`, else by its dependency name,
/// else the root package if there is one.
Package? packageFor(Pin pin, List<Package> packages) {
  if (pin.path != null) {
    final dir = pin.path!.replaceAll(RegExp(r'^\./|/$'), '');
    for (final p in packages) {
      if (p.dir == dir) return p;
    }
    return null;
  }
  for (final p in packages) {
    if (p.name == pin.dependency) return p;
  }
  for (final p in packages) {
    if (p.dir == '.') return p;
  }
  return null;
}

/// Resolves [pin] against the local clone. With [fetch], fetches a missing
/// commit or tag from origin first.
PinReport checkPin(
  Git git,
  Pin pin,
  List<Package> packages,
  Map<String, List<Release>> history, {
  bool fetch = true,
}) {
  final main = git.defaultBranch();
  final package = packageFor(pin, packages);
  final released = package == null
      ? const <Release>[]
      : history[package.name]!.where((r) => !r.unreleased).toList();
  final latest = released.isEmpty ? null : released.last.version;

  final ref = pin.ref;
  if (ref == null || ref.isEmpty) {
    return PinReport(
      pin: pin,
      status: PinStatus.unpinned,
      package: package,
      latest: latest,
      note: 'no ref: resolves to whatever the lockfile recorded',
    );
  }

  String? commit = _sha.hasMatch(ref)
      ? (git.resolve(ref))
      : (git.resolve('refs/tags/$ref') ?? git.resolve('origin/$ref'));
  if (commit == null && fetch) {
    git.tryRun([
      'fetch',
      '--quiet',
      'origin',
      _sha.hasMatch(ref) ? ref : 'refs/tags/$ref:refs/tags/$ref',
    ]);
    commit = _sha.hasMatch(ref)
        ? git.resolve(ref)
        : git.resolve('refs/tags/$ref');
  }
  if (commit == null) {
    return PinReport(
      pin: pin,
      status: PinStatus.missing,
      package: package,
      latest: latest,
      note: 'ref not found on origin',
    );
  }

  final version = package == null
      ? null
      : pubspecVersion(git.show(commit, package.pubspec) ?? '');
  final onMain = git.isAncestor(commit, main);
  // Without a known package, count every commit after the pin.
  final behind = int.parse(
    git.run([
      'rev-list',
      '--count',
      '$commit..$main',
      '--',
      ?package?.dir,
    ]).trim(),
  );
  final releasesBehind = version == null
      ? 0
      : released.where((r) => compareVersions(r.version!, version) > 0).length;

  String? note;
  if (!onMain) {
    final base = git.tryRun(['merge-base', commit, main])?.trim();
    note =
        'not on $main${base == null ? '' : '; forked at ${base.substring(0, 7)}'}';
  } else if (package == null) {
    note =
        'package unknown: the source showed neither path: nor the '
        'dependency name; --fetch reads the whole pubspec';
  } else if (releasesBehind == 0 && behind > 0) {
    note = '$behind unreleased commits after it';
  }

  final status = !onMain
      ? PinStatus.offMain
      : (package == null ? behind == 0 : releasesBehind == 0)
      ? PinStatus.current
      : PinStatus.behind;
  return PinReport(
    pin: pin,
    status: status,
    package: package,
    commit: commit,
    version: version,
    latest: latest,
    releasesBehind: releasesBehind,
    commitsBehind: behind,
    note: note,
  );
}
