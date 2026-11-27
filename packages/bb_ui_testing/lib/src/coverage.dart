import 'dart:convert';
import 'dart:io';

import 'lcov.dart';
import 'widget_source.dart';

/// Widget declarations and matching test references found by a source scan.
class WidgetCoverage {
  WidgetCoverage({
    required this.widgets,
    required this.staleAllowlist,
    required this.libPath,
    required this.testPath,
    this.lcovPath,
  });

  final List<WidgetCoverageEntry> widgets;
  final List<String> staleAllowlist;
  final String libPath;
  final String testPath;
  final String? lcovPath;

  int get covered => widgets.where((entry) => entry.covered).length;
  int get allowed => widgets.where((entry) => entry.allowed).length;
  int get uncovered => widgets.length - covered - allowed;
  bool get passed => uncovered == 0 && staleAllowlist.isEmpty;

  Map<String, Object?> toJson() => {
    'lib': libPath,
    'test': testPath,
    if (lcovPath != null) 'lcov': lcovPath,
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
      ..writeln(
        '| Widget | Status | Hit | Source | Test references | Goldens |',
      )
      ..writeln('| --- | --- | --- | --- | --- | --- |');
    for (final entry in widgets) {
      buffer.writeln(
        '| ${entry.name} | ${entry.status} | ${entry.hit ?? ""} | ${_cell(entry.source)} | '
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
    this.hit,
  });

  final String name;
  final String source;
  final List<String> tests;
  final bool allowed;
  final List<String> goldens;
  final bool? hit;
  bool get covered => hit ?? (tests.isNotEmpty || goldens.isNotEmpty);
  String get status =>
      covered ? 'covered' : (allowed ? 'allowed' : 'uncovered');

  Map<String, Object?> toJson() => {
    'name': name,
    'source': source,
    'status': status,
    'tests': tests,
    'goldens': goldens,
    'hit': hit,
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
  String? lcovPath,
}) {
  final sources = _files(libPath).where((file) => file.path.endsWith('.dart'));
  final tests = lcovPath == null
      ? _files(testPath, allowMissing: allowMissingTestDirectory)
      : <File>[];
  final declarations =
      <
        ({
          String name,
          String parent,
          String source,
          String path,
          WidgetSourceClass parsed,
        })
      >[];
  for (final file in sources) {
    for (final declaration in parseWidgetSource(file.readAsStringSync())) {
      declarations.add((
        name: declaration.name,
        parent: declaration.parent,
        source: _relative(file.path, libPath),
        path: file.path,
        parsed: declaration,
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
  final statefulNames = <String>{'StatefulWidget'};
  var addedStateful = true;
  while (addedStateful) {
    addedStateful = false;
    for (final declaration in declarations) {
      if (statefulNames.contains(declaration.parent) &&
          statefulNames.add(declaration.name)) {
        addedStateful = true;
      }
    }
  }
  final lcov = lcovPath == null ? null : LcovHits(lcovPath, libPath);
  bool hasHit(WidgetSourceClass declaration, String path) {
    final span = declaration.build ?? declaration.body;
    return span != null && lcov!.forFile(path).any(span.contains);
  }

  final hits = <(String, String), bool>{};
  for (final widget in widgets) {
    if (lcov == null) {
      continue;
    }
    final bool hit;
    if (statefulNames.contains(widget.parent)) {
      var states = declarations
          .where((state) => state.parsed.stateWidget == widget.name)
          .toList();
      final local = states.where((state) => state.path == widget.path).toList();
      if (local.isNotEmpty) {
        states = local;
      }
      hit = states.any((state) => hasHit(state.parsed, state.path));
    } else {
      final span = widget.parsed.build;
      hit = span != null && lcov.forFile(widget.path).any(span.contains);
    }
    hits[(widget.source, widget.name)] = hit;
  }
  bool declarationHit(String source, String name) =>
      hits[(source, name)] ?? false;
  final references = <String, List<String>>{};
  final pngs = <String>[];
  final identifier = RegExp(r'[A-Za-z_$][A-Za-z0-9_$]*');
  for (final file in tests) {
    final path = _relative(file.path, testPath);
    if (path.endsWith('.png')) {
      pngs.add(path);
      continue;
    }
    final String contents;
    try {
      contents = utf8.decode(file.readAsBytesSync());
    } on FormatException {
      continue;
    }
    if (contents.contains('\u0000')) {
      continue;
    }
    final tokens = identifier
        .allMatches(contents)
        .map((m) => m.group(0))
        .toSet();
    for (final name in names.where(tokens.contains)) {
      references.putIfAbsent(name, () => []).add(path);
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
  final goldenEvidence = <String, List<String>>{
    for (final name in names)
      name: [
        for (final png in pngs)
          if ((goldens[name] ?? []).contains(png.split('/').last)) png,
      ],
  };
  bool isCovered(String name) => lcov != null
      ? widgets
            .where((widget) => widget.name == name)
            .every((widget) => declarationHit(widget.source, name))
      : references.containsKey(name) ||
            (goldenEvidence[name]?.isNotEmpty ?? false);
  final stale =
      allowlist
          .where((name) => !names.contains(name) || isCovered(name))
          .toList()
        ..sort();
  return WidgetCoverage(
    libPath: libPath,
    testPath: testPath,
    lcovPath: lcovPath,
    staleAllowlist: stale,
    widgets: [
      for (final declaration in widgets)
        WidgetCoverageEntry(
          name: declaration.name,
          source: declaration.source,
          tests: references[declaration.name] ?? [],
          allowed:
              allowlist.contains(declaration.name) &&
              !(lcov == null
                  ? isCovered(declaration.name)
                  : declarationHit(declaration.source, declaration.name)),
          goldens: goldenEvidence[declaration.name]!,
          hit: lcov == null
              ? null
              : declarationHit(declaration.source, declaration.name),
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

List<File> _files(String path, {bool allowMissing = false}) {
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
