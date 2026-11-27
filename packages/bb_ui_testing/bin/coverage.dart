import 'dart:convert';
import 'dart:io';

import 'package:bb_ui_testing/src/coverage.dart';

const _usage =
    'Usage: dart run bb_ui_testing:coverage '
    '[--lib lib] [--test test] [--allow coverage-allowlist.txt] '
    '[--json out.json] [--md out.md] [--private] [--goldens mapping.json] [--lcov path]';

void main(List<String> arguments) {
  try {
    final options = <String, String>{};
    var includePrivate = false;
    for (var i = 0; i < arguments.length; i++) {
      final argument = arguments[i];
      if (argument == '--help' || argument == '-h') {
        stdout.writeln(_usage);
        return;
      }
      if (argument == '--private') {
        includePrivate = true;
        continue;
      }
      if (![
            '--lib',
            '--test',
            '--allow',
            '--json',
            '--md',
            '--goldens',
            '--lcov',
          ].contains(argument) ||
          i + 1 == arguments.length ||
          arguments[i + 1].startsWith('--')) {
        throw FormatException('Unknown option or missing value: $argument');
      }
      options[argument] = arguments[++i];
    }
    final defaultAllow = File('coverage-allowlist.txt');
    final report = scanWidgetCoverage(
      libPath: options['--lib'] ?? 'lib',
      testPath: options['--test'] ?? 'test',
      allowMissingTestDirectory: !options.containsKey('--test'),
      allowPath:
          options['--allow'] ??
          (defaultAllow.existsSync() ? defaultAllow.path : null),
      includePrivate: includePrivate,
      lcovPath: options['--lcov'],
      goldens: options['--goldens'] == null || options['--lcov'] != null
          ? const {}
          : readGoldenMapping(options['--goldens']!),
    );
    stdout.writeln('Widget\tStatus\tHit\tSource');
    for (final entry in report.widgets) {
      stdout.writeln(
        '${entry.name}\t${entry.status}\t${entry.hit ?? ""}\t${entry.source}',
      );
    }
    stdout.writeln(report.summary);
    for (final name in report.staleAllowlist) {
      stderr.writeln('Stale allowlist entry (covered or nonexistent): $name');
    }
    if (options['--json'] case final path?) {
      _write(
        path,
        '${const JsonEncoder.withIndent('  ').convert(report.toJson())}\n',
      );
    }
    if (options['--md'] case final path?) {
      _write(path, report.toMarkdown());
    }
    exitCode = report.passed ? 0 : 1;
  } on FormatException catch (error) {
    stderr.writeln('$error\n$_usage');
    exitCode = 2;
  } on FileSystemException catch (error) {
    stderr.writeln(error);
    exitCode = 2;
  }
}

void _write(String path, String contents) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}
