import 'dart:io';

/// Positive DA lines merged across LCOV records for an exact source path.
class LcovHits {
  LcovHits(String path, String libPath) {
    final roots = <String>{Directory.current.absolute.path};
    var directory = Directory(libPath).absolute.parent;
    while (true) {
      roots.add(directory.path);
      final parent = directory.parent;
      if (parent.path == directory.path) {
        break;
      }
      directory = parent;
    }
    var paths = <String>[];
    for (final line in File(path).readAsLinesSync()) {
      if (line.startsWith('SF:')) {
        final source = line.substring('SF:'.length).replaceAll('\\', '/');
        paths =
            (RegExp(r'^(?:[A-Za-z]:/|/)').hasMatch(source)
                    ? [source]
                    : [for (final root in roots) '$root/$source'])
                .map(_normalize)
                .toSet()
                .toList();
      } else if (line.startsWith('DA:') && paths.isNotEmpty) {
        final fields = line.substring('DA:'.length).split(',');
        if (fields.length < 2) {
          continue;
        }
        final number = int.tryParse(fields.first);
        final count = int.tryParse(fields[1]);
        if (number == null || number <= 0 || count == null || count <= 0) {
          continue;
        }
        for (final candidate in paths) {
          _lines.putIfAbsent(candidate, () => {}).add(number);
        }
      } else if (line == 'end_of_record') {
        paths = [];
      }
    }
  }

  final _lines = <String, Set<int>>{};
  Set<int> forFile(String path) =>
      _lines[_normalize(File(path).absolute.path)] ?? {};
}

String _normalize(String path) {
  final normalized = path.replaceAll('\\', '/');
  final parts = <String>[];
  for (final part in normalized.split('/')) {
    if (part == '.' || part.isEmpty) {
      continue;
    }
    if (part == '..' && parts.isNotEmpty) {
      parts.removeLast();
    } else {
      parts.add(part);
    }
  }
  final result = parts.join('/');
  return Platform.isWindows || RegExp(r'^[A-Za-z]:/').hasMatch(normalized)
      ? result.toLowerCase()
      : result;
}
