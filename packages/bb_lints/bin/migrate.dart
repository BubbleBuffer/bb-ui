// dart run bb_lints:migrate <directory> [--type-scale <expr>] [--import <uri>]
//                                      [--no-import] [--no-format] [--dry-run]
//
// Applies the mechanical part of the bb_ui 0.8 migration to every library
// under <directory>, then formats the changed files. Run `dart analyze`
// afterwards: the bb_lints rules list what is left to do by hand.

import 'dart:io';

import 'package:bb_lints/migrate.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('-h') || args.contains('--help')) {
    stdout.writeln(
      'usage: dart run bb_lints:migrate <dir> [--type-scale <expr>] '
      '[--import <uri>] [--no-import] [--no-format] [--dry-run]',
    );
    exit(args.isEmpty ? 64 : 0);
  }
  String? value(String flag) {
    final i = args.indexOf(flag);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final options = MigrateOptions(
    typeScale: value('--type-scale') ?? 'TypeScale.pointer',
    import: args.contains('--no-import')
        ? null
        : value('--import') ?? 'package:bb_ui/bb_ui.dart',
    dryRun: args.contains('--dry-run'),
  );
  final changed = await migrate(args.first, options);
  for (final path in changed) {
    stdout.writeln('migrated $path');
  }
  // A repository that is not dart-formatted keeps its own layout.
  if (changed.isNotEmpty && !options.dryRun && !args.contains('--no-format')) {
    await Process.run('dart', ['format', ...changed], runInShell: true);
  }
  stdout.writeln('${changed.length} files changed.');
}
