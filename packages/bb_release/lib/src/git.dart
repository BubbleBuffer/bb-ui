// Thin wrappers over the git command line. Every call runs in one repository
// directory and fails loudly unless the caller asks for a soft result.

import 'dart:io';

class GitException implements Exception {
  GitException(this.args, this.code, this.stderr);

  final List<String> args;
  final int code;
  final String stderr;

  @override
  String toString() => 'git ${args.join(' ')} exited $code: ${stderr.trim()}';
}

class Git {
  Git(this.dir);

  final String dir;

  /// Runs git and returns stdout. Throws [GitException] on a nonzero exit.
  String run(List<String> args) {
    final result = Process.runSync('git', args, workingDirectory: dir);
    if (result.exitCode != 0) {
      throw GitException(args, result.exitCode, result.stderr as String);
    }
    return result.stdout as String;
  }

  /// Runs git and returns stdout, or null on a nonzero exit.
  String? tryRun(List<String> args) {
    final result = Process.runSync('git', args, workingDirectory: dir);
    return result.exitCode == 0 ? result.stdout as String : null;
  }

  bool succeeds(List<String> args) =>
      Process.runSync('git', args, workingDirectory: dir).exitCode == 0;

  /// The file at [path] in [rev], or null when it does not exist there.
  String? show(String rev, String path) => tryRun(['show', '$rev:$path']);

  bool hasCommit(String rev) => succeeds(['cat-file', '-e', '$rev^{commit}']);

  bool isAncestor(String ancestor, String rev) =>
      succeeds(['merge-base', '--is-ancestor', ancestor, rev]);

  String? resolve(String rev) =>
      tryRun(['rev-parse', '--verify', '--quiet', '$rev^{commit}'])?.trim();

  /// The default branch as a revision: origin/HEAD when the clone knows it,
  /// then origin/main or origin/master, otherwise HEAD.
  String defaultBranch() => _defaultBranch ??= () {
    final ref = tryRun(['symbolic-ref', '--quiet', 'refs/remotes/origin/HEAD']);
    if (ref != null) return ref.trim().replaceFirst('refs/remotes/', '');
    for (final b in ['origin/main', 'origin/master']) {
      if (resolve(b) != null) return b;
    }
    return 'HEAD';
  }();

  String? _defaultBranch;

  /// owner/name of the origin remote on GitHub, or null.
  String? originSlug() {
    final url = tryRun(['remote', 'get-url', 'origin'])?.trim();
    return url == null ? null : githubSlug(url);
  }
}

final _slug = RegExp(r'github\.com[/:]([^/\s]+)/([^/\s]+?)(?:\.git)?/?$');

/// owner/name from a GitHub URL, or null for any other URL.
String? githubSlug(String url) {
  final m = _slug.firstMatch(url.trim());
  return m == null ? null : '${m[1]}/${m[2]}';
}
