// Release history read from git: a package releases a version in the commit
// that changes the `version:` line of its pubspec. Tags are optional; the
// history is the same whether or not anyone tagged the release.

import 'git.dart';

class Package {
  Package({required this.name, required this.dir, required this.version});

  final String name;

  /// Repository-relative directory, '.' for a root package.
  final String dir;
  final String version;

  String get pubspec => dir == '.' ? 'pubspec.yaml' : '$dir/pubspec.yaml';

  Map<String, Object?> toJson() => {
    'name': name,
    'dir': dir,
    'version': version,
  };
}

class Commit {
  Commit({
    required this.sha,
    required this.date,
    required this.subject,
    this.pr,
  });

  final String sha;
  final String date;
  final String subject;

  /// The pull request number from a `(#12)` or `Merge pull request #12`
  /// subject. For history imported from another repository it names a pull
  /// request there.
  final int? pr;

  Map<String, Object?> toJson() => {
    'sha': sha,
    'date': date,
    'subject': subject,
    'pr': pr,
  };
}

class Release {
  Release({
    required this.package,
    required this.version,
    required this.commit,
    required this.date,
    required this.previous,
    required this.commits,
    required this.tags,
  });

  final String package;

  /// null for the unreleased commits after the last version bump.
  final String? version;

  /// The bump commit, or the newest commit for the unreleased entry.
  final String commit;
  final String date;

  /// The bump commit of the version before, or null for the first one.
  final String? previous;

  /// Commits touching the package directory in (previous, commit], newest
  /// first.
  final List<Commit> commits;

  /// Tags naming this version (v1.2.3 or name-v1.2.3), wherever they point.
  final List<String> tags;

  bool get unreleased => version == null;

  Map<String, Object?> toJson() => {
    'package': package,
    'version': version,
    'commit': commit,
    'date': date,
    'previous': previous,
    'tags': tags,
    'commits': [for (final c in commits) c.toJson()],
  };
}

final _versionLine = RegExp(r'^version:\s*([^\s#]+)', multiLine: true);
final _nameLine = RegExp(r'^name:\s*([^\s#]+)', multiLine: true);
final _prSubject = RegExp(r'\(#(\d+)\)\s*$|^Merge pull request #(\d+)');

String? pubspecVersion(String pubspec) =>
    _versionLine.firstMatch(pubspec)?.group(1)?.replaceAll(RegExp('[\'"]'), '');

String? pubspecName(String pubspec) => _nameLine.firstMatch(pubspec)?.group(1);

int? prNumber(String subject) {
  final m = _prSubject.firstMatch(subject);
  if (m == null) return null;
  return int.parse(m[1] ?? m[2]!);
}

/// Packages with a version in their tracked pubspec at [rev].
List<Package> discoverPackages(Git git, {String rev = 'HEAD'}) {
  final files = git
      .run(['ls-tree', '-r', '--name-only', rev])
      .split('\n')
      .where((f) => f == 'pubspec.yaml' || f.endsWith('/pubspec.yaml'));
  final packages = <Package>[];
  for (final file in files) {
    final text = git.show(rev, file);
    if (text == null) continue;
    final name = pubspecName(text);
    final version = pubspecVersion(text);
    if (name == null || version == null) continue;
    final dir = file == 'pubspec.yaml'
        ? '.'
        : file.substring(0, file.length - '/pubspec.yaml'.length);
    packages.add(Package(name: name, dir: dir, version: version));
  }
  packages.sort((a, b) => a.dir.compareTo(b.dir));
  return packages;
}

List<Commit> _log(Git git, List<String> range, String dir) {
  final out = git.run([
    'log',
    '--format=%H%x1f%ad%x1f%s',
    '--date=short',
    ...range,
    '--',
    dir,
  ]);
  return [
    for (final line in out.split('\n'))
      if (line.isNotEmpty)
        () {
          final f = line.split('\x1f');
          return Commit(
            sha: f[0],
            date: f[1],
            subject: f[2],
            pr: prNumber(f[2]),
          );
        }(),
  ];
}

/// Every version [package] released up to [rev], oldest first, followed by
/// an unreleased entry when commits touch the package after the last bump.
List<Release> releases(
  Git git,
  Package package, {
  String rev = 'HEAD',
  Set<String> tags = const {},
}) {
  final touching = git
      .run([
        'log',
        '--reverse',
        '--format=%H%x1f%ad',
        '--date=short',
        rev,
        '--',
        package.pubspec,
      ])
      .split('\n')
      .where((l) => l.isNotEmpty)
      .map((l) => l.split('\x1f'));

  final bumps = <(String sha, String date, String version)>[];
  String? last;
  for (final [sha, date] in touching) {
    final text = git.show(sha, package.pubspec);
    final version = text == null ? null : pubspecVersion(text);
    if (version == null || version == last) continue;
    last = version;
    bumps.add((sha, date, version));
  }

  final result = <Release>[];
  String? previous;
  for (final (sha, date, version) in bumps) {
    final range = previous == null ? [sha] : ['$previous..$sha'];
    result.add(
      Release(
        package: package.name,
        version: version,
        commit: sha,
        date: date,
        previous: previous,
        commits: _log(git, range, package.dir),
        tags: tagsFor(package.name, version, tags),
      ),
    );
    previous = sha;
  }

  final head = git.run(['rev-parse', rev]).trim();
  final pending = previous == null
      ? const <Commit>[]
      : _log(git, ['$previous..$head'], package.dir);
  if (pending.isNotEmpty) {
    result.add(
      Release(
        package: package.name,
        version: null,
        commit: head,
        date: pending.first.date,
        previous: previous,
        commits: pending,
        tags: const [],
      ),
    );
  }
  return result;
}

/// Tags that name [version] of [package]: `v1.2.3`, `1.2.3`, `name-v1.2.3`
/// or `name/v1.2.3`.
List<String> tagsFor(String package, String version, Set<String> tags) => [
  for (final t in [
    'v$version',
    version,
    '$package-v$version',
    '$package/v$version',
  ])
    if (tags.contains(t)) t,
];

/// Tag names from the local clone, plus origin's when [remote] is set.
Set<String> tagNames(Git git, {bool remote = false}) {
  final names = git
      .run(['tag', '--list'])
      .split('\n')
      .where((t) => t.isNotEmpty)
      .toSet();
  if (remote) {
    final out = git.tryRun(['ls-remote', '--tags', '--refs', 'origin']) ?? '';
    for (final line in out.split('\n')) {
      final i = line.indexOf('refs/tags/');
      if (i >= 0) names.add(line.substring(i + 'refs/tags/'.length).trim());
    }
  }
  return names;
}

/// Compares dotted versions numerically, ignoring pre-release and build
/// suffixes after the first `-` or `+`.
int compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .split(RegExp(r'[-+]'))
      .first
      .split('.')
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
  final pa = parts(a), pb = parts(b);
  for (var i = 0; i < pa.length || i < pb.length; i++) {
    final x = i < pa.length ? pa[i] : 0, y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}
