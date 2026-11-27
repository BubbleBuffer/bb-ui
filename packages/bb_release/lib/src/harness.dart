// Harness adapters: the one place that knows how to hand a prompt to a
// coding agent's command line and read its answer back. The release stages
// only see [Harness.complete], so the same pipeline runs on Claude Code,
// opencode, or any command that reads a prompt and prints a reply.

import 'dart:convert';
import 'dart:io';

class HarnessException implements Exception {
  HarnessException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class Harness {
  /// A short id for caches and reports, such as `claude:haiku`.
  String get id;

  /// Sends [prompt] as one single-turn request and returns the reply text.
  Future<String> complete(String prompt);

  /// Builds an adapter from command-line settings.
  ///
  /// [name] is `claude`, `opencode`, `command` or `echo`. [model] is the
  /// harness's own model id. [command] is the argv for `command`, where
  /// `{model}` is replaced and the prompt goes to stdin. [extra] is appended
  /// to the argv of `claude` and `opencode`.
  factory Harness.create(
    String name, {
    String? model,
    List<String> command = const [],
    List<String> extra = const [],
    Duration timeout = const Duration(minutes: 5),
  }) {
    switch (name) {
      case 'claude':
        return ClaudeHarness(
          model: model ?? 'haiku',
          extra: extra,
          timeout: timeout,
        );
      case 'opencode':
        if (model == null) {
          throw HarnessException(
            'opencode needs --model provider/model; `opencode models` lists them',
          );
        }
        return OpencodeHarness(model: model, extra: extra, timeout: timeout);
      case 'command':
        if (command.isEmpty) {
          throw HarnessException('command needs --command "<argv>"');
        }
        return CommandHarness(command, model: model, timeout: timeout);
      case 'echo':
        return EchoHarness();
    }
    throw HarnessException(
      'unknown harness "$name" (claude, opencode, command, echo)',
    );
  }
}

Future<String> _run(
  List<String> argv, {
  String? stdin,
  required Duration timeout,
  String? workingDirectory,
}) async {
  final Process process;
  try {
    process = await Process.start(
      argv.first,
      argv.sublist(1),
      workingDirectory: workingDirectory,
    );
  } on ProcessException catch (e) {
    throw HarnessException('cannot start ${argv.first}: ${e.message}');
  }
  final out = process.stdout.transform(utf8.decoder).join();
  final err = process.stderr.transform(utf8.decoder).join();
  if (stdin != null) process.stdin.write(stdin);
  await process.stdin.close();
  final code = await process.exitCode.timeout(
    timeout,
    onTimeout: () {
      process.kill();
      throw HarnessException(
        '${argv.first} timed out after ${timeout.inSeconds}s',
      );
    },
  );
  if (code != 0) {
    throw HarnessException('${argv.first} exited $code: ${(await err).trim()}');
  }
  return out;
}

/// Claude Code in print mode with no tools, MCP servers or saved session:
/// the prompt carries all the context and the reply is text only.
class ClaudeHarness implements Harness {
  ClaudeHarness({
    required this.model,
    this.extra = const [],
    required this.timeout,
  });

  final String model;
  final List<String> extra;
  final Duration timeout;

  @override
  String get id => 'claude:$model';

  List<String> get argv => [
    'claude',
    '-p',
    '--model',
    model,
    '--output-format',
    'json',
    '--tools',
    '',
    '--strict-mcp-config',
    '--no-session-persistence',
    ...extra,
  ];

  @override
  Future<String> complete(String prompt) async {
    final out = await _run(argv, stdin: prompt, timeout: timeout);
    final Object? json;
    try {
      json = jsonDecode(out);
    } on FormatException {
      return out;
    }
    if (json is Map && json['is_error'] == true) {
      throw HarnessException('claude: ${json['result'] ?? json['subtype']}');
    }
    return json is Map && json['result'] is String
        ? json['result'] as String
        : out;
  }
}

/// opencode's non-interactive `run`. opencode runs an agent with tools, so
/// each request gets an empty temporary directory holding only the prompt,
/// attached as a file so its length is not limited by the OS argument size.
/// `--pure` leaves out external plugins.
class OpencodeHarness implements Harness {
  OpencodeHarness({
    required this.model,
    this.extra = const [],
    required this.timeout,
  });

  final String model;
  final List<String> extra;
  final Duration timeout;

  @override
  String get id => 'opencode:$model';

  @override
  Future<String> complete(String prompt) async {
    final dir = Directory.systemTemp.createTempSync('bb_release_');
    try {
      final file = File('${dir.path}/prompt.md')..writeAsStringSync(prompt);
      return await _run(
        [
          'opencode',
          'run',
          '--pure',
          '--model',
          model,
          '--dir',
          dir.path,
          '--file',
          file.path,
          ...extra,
          '--',
          'Follow the instructions in the attached prompt.md. Do not use tools. '
              'Reply with the JSON object only.',
        ],
        timeout: timeout,
        workingDirectory: dir.path,
      );
    } finally {
      dir.deleteSync(recursive: true);
    }
  }
}

/// Any command that reads the prompt on stdin and prints the reply.
class CommandHarness implements Harness {
  CommandHarness(this.command, {this.model, required this.timeout});

  final List<String> command;
  final String? model;
  final Duration timeout;

  @override
  String get id => 'command:${command.first}${model == null ? '' : ':$model'}';

  @override
  Future<String> complete(String prompt) => _run(
    [for (final a in command) a.replaceAll('{model}', model ?? '')],
    stdin: prompt,
    timeout: timeout,
  );
}

/// Returns a fixed empty answer without calling anything, so a run can be
/// checked end to end and its prompts inspected for free.
class EchoHarness implements Harness {
  @override
  String get id => 'echo';

  @override
  Future<String> complete(String prompt) async =>
      '{"summary": "(echo harness: no model was called)", "entries": []}';
}

/// Runs [tasks] with at most [jobs] in flight, keeping their order.
Future<List<T>> pooled<T>(List<Future<T> Function()> tasks, int jobs) async {
  final results = List<T?>.filled(tasks.length, null);
  var next = 0;
  Future<void> worker() async {
    while (next < tasks.length) {
      final i = next++;
      results[i] = await tasks[i]();
    }
  }

  await Future.wait([
    for (var w = 0; w < jobs && w < tasks.length; w++) worker(),
  ]);
  return results.cast<T>();
}

/// The first JSON object in [reply], allowing code fences and prose around
/// it.
Map<String, Object?> extractJsonObject(String reply) {
  final start = reply.indexOf('{');
  if (start < 0) throw const FormatException('no JSON object in the reply');
  var depth = 0;
  var inString = false;
  for (var i = start; i < reply.length; i++) {
    final c = reply[i];
    if (inString) {
      if (c == r'\') {
        i++;
      } else if (c == '"') {
        inString = false;
      }
      continue;
    }
    if (c == '"') {
      inString = true;
    } else if (c == '{') {
      depth++;
    } else if (c == '}' && --depth == 0) {
      final value = jsonDecode(reply.substring(start, i + 1));
      if (value is Map<String, Object?>) return value;
      break;
    }
  }
  throw const FormatException('unterminated JSON object in the reply');
}
