import 'dart:convert';
import 'dart:io';

const _tripleQuoteLength = 3;
const _qualifiedParentOffset = 3;

/// Widget declarations and matching test references found by a source scan.
class WidgetCoverage {
  WidgetCoverage({
    required this.widgets,
    required this.staleAllowlist,
    required this.libPath,
    required this.testPath,
  });

  final List<WidgetCoverageEntry> widgets;
  final List<String> staleAllowlist;
  final String libPath;
  final String testPath;

  int get covered => widgets.where((entry) => entry.covered).length;
  int get allowed => widgets.where((entry) => entry.allowed).length;
  int get uncovered => widgets.length - covered - allowed;
  bool get passed => uncovered == 0 && staleAllowlist.isEmpty;

  Map<String, Object?> toJson() => {
    'lib': libPath,
    'test': testPath,
    'summary': {
      'total': widgets.length,
      'covered': covered,
      'allowed': allowed,
      'uncovered': uncovered,
      'staleAllowlist': staleAllowlist.length,
      'passed': passed,
    },
    'widgets': widgets.map((entry) => entry.toJson()).toList(),
    'staleAllowlist': staleAllowlist,
  };

  String get summary =>
      '${widgets.length} widgets: $covered covered, $allowed allowed, '
      '$uncovered uncovered; ${staleAllowlist.length} stale allowlist entries.';

  String toMarkdown() {
    final buffer = StringBuffer('# Widget coverage\n\n$summary\n\n')
      ..writeln('| Widget | Status | Source | Test references | Goldens |')
      ..writeln('| --- | --- | --- | --- | --- |');
    for (final entry in widgets) {
      buffer.writeln(
        '| ${entry.name} | ${entry.status} | ${_cell(entry.source)} | '
        '${_cell(entry.tests.join(', '))} | '
        '${_cell(entry.goldens.join(', '))} |',
      );
    }
    if (staleAllowlist.isNotEmpty) {
      buffer.write(
        '\nStale allowlist entries (covered or nonexistent): '
        '${staleAllowlist.join(', ')}.\n',
      );
    }
    return buffer.toString();
  }
}

String _cell(String value) => value.replaceAll('|', r'\|');

class WidgetCoverageEntry {
  WidgetCoverageEntry({
    required this.name,
    required this.source,
    required this.tests,
    required this.allowed,
    required this.goldens,
  });

  final String name;
  final String source;
  final List<String> tests;
  final bool allowed;
  final List<String> goldens;
  bool get covered => tests.isNotEmpty || goldens.isNotEmpty;
  String get status =>
      covered ? 'covered' : (allowed ? 'allowed' : 'uncovered');

  Map<String, Object?> toJson() => {
    'name': name,
    'source': source,
    'status': status,
    'tests': tests,
    'goldens': goldens,
  };
}

/// Counts exact identifier tokens in raw test text, including comments/strings.
WidgetCoverage scanWidgetCoverage({
  String libPath = 'lib',
  String testPath = 'test',
  String? allowPath,
  bool includePrivate = false,
  bool allowMissingTestDirectory = false,
  Map<String, List<String>> goldens = const {},
}) {
  final sources = _files(libPath, '.dart');
  final tests = _files(
    testPath,
    '.dart',
    allowMissing: allowMissingTestDirectory,
  );
  final declarations = <({String name, String parent, String source})>[];
  for (final file in sources) {
    for (final declaration in _classes(file.readAsStringSync())) {
      declarations.add((
        name: declaration.name,
        parent: declaration.parent,
        source: _relative(file.path, libPath),
      ));
    }
  }
  final widgetNames = <String>{'StatelessWidget', 'StatefulWidget'};
  var changed = true;
  while (changed) {
    changed = false;
    for (final declaration in declarations) {
      if (widgetNames.contains(declaration.parent) &&
          widgetNames.add(declaration.name)) {
        changed = true;
      }
    }
  }
  final widgets =
      declarations
          .where(
            (declaration) =>
                widgetNames.contains(declaration.parent) &&
                (includePrivate || !declaration.name.startsWith('_')),
          )
          .toList()
        ..sort((a, b) {
          final byName = a.name.compareTo(b.name);
          return byName != 0 ? byName : a.source.compareTo(b.source);
        });
  final names = widgets.map((widget) => widget.name).toSet();
  final references = <String, List<String>>{};
  for (final file in tests) {
    final tokens = RegExp(r'[A-Za-z_$][A-Za-z0-9_$]*')
        .allMatches(file.readAsStringSync())
        .map((match) => match.group(0)!)
        .toSet();
    for (final name in names.where(tokens.contains)) {
      references
          .putIfAbsent(name, () => [])
          .add(_relative(file.path, testPath));
    }
  }
  final allowlist = <String>{};
  if (allowPath != null) {
    for (final line in File(allowPath).readAsLinesSync()) {
      final name = line.split('#').first.trim();
      if (name.isNotEmpty) {
        allowlist.add(name);
      }
    }
  }
  final pngs = _files(
    testPath,
    '.png',
    allowMissing: allowMissingTestDirectory,
  ).map((file) => _relative(file.path, testPath)).toList();
  final goldenEvidence = <String, List<String>>{
    for (final name in names)
      name: [
        for (final png in pngs)
          if ((goldens[name] ?? []).contains(png.split('/').last)) png,
      ],
  };
  bool isCovered(String name) =>
      references.containsKey(name) ||
      (goldenEvidence[name]?.isNotEmpty ?? false);
  final stale =
      allowlist
          .where((name) => !names.contains(name) || isCovered(name))
          .toList()
        ..sort();
  return WidgetCoverage(
    libPath: libPath,
    testPath: testPath,
    staleAllowlist: stale,
    widgets: [
      for (final declaration in widgets)
        WidgetCoverageEntry(
          name: declaration.name,
          source: declaration.source,
          tests: references[declaration.name] ?? [],
          allowed:
              allowlist.contains(declaration.name) &&
              !isCovered(declaration.name),
          goldens: goldenEvidence[declaration.name]!,
        ),
    ],
  );
}

Map<String, List<String>> readGoldenMapping(String path) {
  final value = jsonDecode(File(path).readAsStringSync());
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Golden mapping must be a JSON object.');
  }
  return value.map((name, files) {
    final values = files is String ? [files] : files;
    if (values is! List ||
        values.any(
          (item) =>
              item is! String ||
              !item.endsWith('.png') ||
              item.contains('/') ||
              item.contains(r'\'),
        )) {
      throw FormatException('Goldens for $name must be PNG basenames.');
    }
    return MapEntry(name, values.cast<String>());
  });
}

List<File> _files(String path, String extension, {bool allowMissing = false}) {
  final directory = Directory(path);
  if (!directory.existsSync()) {
    if (allowMissing) {
      return [];
    }
    throw FileSystemException('Scan directory does not exist', path);
  }
  return directory
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) => file.path.endsWith(extension))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

String _relative(String path, String root) {
  final absoluteRoot = Directory(root).absolute.path.replaceAll('\\', '/');
  final absolutePath = File(path).absolute.path.replaceAll('\\', '/');
  return absolutePath.substring(
    absoluteRoot.length + (absoluteRoot.endsWith('/') ? 0 : 1),
  );
}

Iterable<({String name, String parent})> _classes(String source) sync* {
  final tokens = RegExp(r'[A-Za-z_$][A-Za-z0-9_$]*|[^\s]')
      .allMatches(_withoutCommentsAndStrings(source))
      .map((match) => match.group(0)!)
      .toList();
  for (var i = 0; i + 1 < tokens.length; i++) {
    if (tokens[i] != 'class') {
      continue;
    }
    final name = tokens[i + 1];
    var depth = 0;
    for (var j = i + 2; j < tokens.length; j++) {
      final token = tokens[j];
      if (token == '<') {
        depth++;
      }
      if (token == '>') {
        depth--;
      }
      if (depth == 0 && (token == '{' || token == ';' || token == '=')) {
        break;
      }
      if (depth == 0 && token == 'extends' && j + 1 < tokens.length) {
        var parent = tokens[j + 1];
        if (j + _qualifiedParentOffset < tokens.length &&
            tokens[j + 2] == '.') {
          parent = tokens[j + _qualifiedParentOffset];
        }
        yield (name: name, parent: parent);
        break;
      }
    }
  }
}

// Skip nested block comments and single/triple quoted strings. Interpolation
// stays inside the skipped string because declarations cannot occur there.
String _withoutCommentsAndStrings(String source) {
  final output = StringBuffer();
  var i = 0;
  while (i < source.length) {
    if (source.startsWith('//', i)) {
      final end = source.indexOf('\n', i + 2);
      i = end < 0 ? source.length : end;
      output.write(' ');
    } else if (source.startsWith('/*', i)) {
      var depth = 1;
      i += 2;
      while (i < source.length && depth > 0) {
        if (source.startsWith('/*', i)) {
          depth++;
          i += 2;
        } else if (source.startsWith('*/', i)) {
          depth--;
          i += 2;
        } else {
          i++;
        }
      }
      output.write(' ');
    } else if (source[i] == '"' || source[i] == "'") {
      final quote = source[i];
      final raw = i > 0 && source[i - 1] == 'r';
      final tripleQuote = quote * _tripleQuoteLength;
      final delimiter = source.startsWith(tripleQuote, i) ? tripleQuote : quote;
      i += delimiter.length;
      while (i < source.length) {
        if (!raw && source[i] == r'\') {
          i += 2;
        } else if (source.startsWith(delimiter, i)) {
          i += delimiter.length;
          break;
        } else {
          i++;
        }
      }
      output.write(' ');
    } else {
      output.write(source[i++]);
    }
  }
  return output.toString();
}
