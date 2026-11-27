import 'dart:convert';
import 'dart:io';

/// Loads a JSON journey or the YAML subset described by [decodeJourneyFile].
Map<String, dynamic> loadJourneyFile(String path) =>
    decodeJourneyFile(File(path).readAsStringSync(), sourceName: path);

/// Decodes a journey without third-party parser dependencies.
///
/// YAML supports space-indented mappings and sequences, plain strings, single
/// quoted strings (escape a quote with two quotes), JSON double quoted strings,
/// true/false, null/~, numbers, comments, and inline JSON objects/arrays.
/// Mapping keys must be identifiers. Tabs, multiline scalars, anchors, aliases,
/// tags, YAML flow collections, and multiple documents are unsupported. Quote
/// strings that look like another scalar type. Deeper action validation belongs
/// to the journey runner.
Map<String, dynamic> decodeJourneyFile(String source, {String? sourceName}) {
  try {
    final yamlInput = source.replaceFirst(RegExp(r'^\uFEFF'), '');
    final input = yamlInput.trim();
    final Object? value;
    if (input.startsWith('{') || input.startsWith('[')) {
      value = jsonDecode(input);
    } else {
      value = _YamlSubset(yamlInput).parse();
    }
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Journey must be a mapping.');
    }
    if (value.keys.any((key) => key != 'goal' && key != 'steps')) {
      throw const FormatException('Journey accepts only goal and steps.');
    }
    final goal = value['goal'];
    if (goal is! String || goal.trim().isEmpty) {
      throw const FormatException('Journey goal must be a nonempty string.');
    }
    final steps = value['steps'];
    if (steps is! List) {
      throw const FormatException('Journey steps must be a list.');
    }
    const actions = {
      'tap',
      'longPress',
      'type',
      'scroll',
      'key',
      'back',
      'expect',
      'wait',
    };
    for (var index = 0; index < steps.length; index++) {
      final step = steps[index];
      if (step is! Map<String, dynamic> || step.length != 1) {
        throw FormatException('Step ${index + 1} must contain one action.');
      }
      if (!actions.contains(step.keys.single)) {
        throw FormatException(
          'Step ${index + 1} has unknown action "${step.keys.single}".',
        );
      }
    }
    return value;
  } on FormatException catch (error) {
    if (sourceName == null) rethrow;
    throw FormatException('$sourceName: ${error.message}');
  }
}

class _Line {
  _Line(this.indent, this.text, this.number);

  final int indent;
  final String text;
  final int number;
}

class _YamlSubset {
  _YamlSubset(String source) {
    final rawLines = const LineSplitter().convert(source);
    for (var index = 0; index < rawLines.length; index++) {
      final raw = rawLines[index];
      if (RegExp(r'^\s*\t').hasMatch(raw)) {
        throw FormatException('Line ${index + 1}: use spaces for indentation.');
      }
      final text = _withoutComment(raw).trimRight();
      if (text.trim().isEmpty) continue;
      final indent = text.length - text.trimLeft().length;
      _lines.add(_Line(indent, text.substring(indent), index + 1));
    }
  }

  final List<_Line> _lines = [];
  int _position = 0;

  Object? parse() {
    if (_lines.isEmpty) throw const FormatException('Journey is empty.');
    if (_lines.first.indent != 0) _fail('Root must start at column one.');
    final value = _block(0);
    if (_position != _lines.length) _fail('Unexpected indentation.');
    return value;
  }

  bool _isSequence(String text) => text == '-' || text.startsWith('- ');

  Object _block(int indent) => _isSequence(_lines[_position].text)
      ? _sequence(indent)
      : _mapping(indent);

  List<Object?> _sequence(int indent) {
    final result = <Object?>[];
    while (_position < _lines.length && _lines[_position].indent == indent) {
      final line = _lines[_position];
      if (!_isSequence(line.text)) _fail('Expected a sequence item.');
      final rest = line.text.substring(1).trimLeft();
      _position++;
      if (rest.isEmpty) {
        result.add(_child(indent));
      } else if (_entry.hasMatch(rest)) {
        // A compact item such as "- tap:" begins a mapping after the marker.
        final mappingIndent = indent + line.text.length - rest.length;
        _lines.insert(_position, _Line(mappingIndent, rest, line.number));
        result.add(_mapping(mappingIndent));
      } else {
        result.add(_scalar(rest, line.number));
      }
      if (_position < _lines.length && _lines[_position].indent > indent) {
        _fail('Unexpected indentation after sequence item.');
      }
    }
    return result;
  }

  static final _entry = RegExp(
    r'^(?<key>[A-Za-z_][A-Za-z0-9_-]*):(?:\s+(?<value>.*)|$)',
  );

  Map<String, dynamic> _mapping(int indent) {
    final result = <String, dynamic>{};
    while (_position < _lines.length && _lines[_position].indent == indent) {
      final line = _lines[_position];
      final match = _entry.firstMatch(line.text);
      if (match == null) _fail('Expected an identifier followed by a colon.');
      final key = match.namedGroup('key')!;
      if (result.containsKey(key)) _fail('Duplicate key "$key".');
      final rest = match.namedGroup('value') ?? '';
      _position++;
      result[key] = rest.isEmpty ? _child(indent) : _scalar(rest, line.number);
      if (_position < _lines.length && _lines[_position].indent > indent) {
        _fail('Unexpected indentation after "$key".');
      }
    }
    return result;
  }

  Object? _child(int indent) {
    if (_position == _lines.length || _lines[_position].indent <= indent) {
      return null;
    }
    return _block(_lines[_position].indent);
  }

  Object? _scalar(String text, int line) {
    if (text.startsWith('"') || text.startsWith('[') || text.startsWith('{')) {
      try {
        return jsonDecode(text);
      } on FormatException {
        throw FormatException('Line $line: invalid JSON string or collection.');
      }
    }
    if (text.startsWith("'")) {
      if (!RegExp(r"^'(?:[^']|'')*'$", dotAll: true).hasMatch(text)) {
        throw FormatException('Line $line: invalid single quoted string.');
      }
      return text.substring(1, text.length - 1).replaceAll("''", "'");
    }
    if (text == 'true') return true;
    if (text == 'false') return false;
    if (text == 'null' || text == '~') return null;
    if (RegExp(r'^-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?$')
        .hasMatch(text)) {
      final number = num.tryParse(text);
      if (number != null && number.isFinite) return number;
      throw FormatException('Line $line: number is out of range.');
    }
    if (RegExp(r'^[!&*|>@`%]').hasMatch(text) ||
        text == '---' ||
        text == '...' ||
        text.contains(': ')) {
      throw FormatException('Line $line: unsupported YAML syntax; quote it.');
    }
    return text;
  }

  Never _fail(String message) =>
      throw FormatException('Line ${_lines[_position].number}: $message');

  static String _withoutComment(String text) {
    String? quote;
    for (var index = 0; index < text.length; index++) {
      final char = text[index];
      if (quote == '"' && char == '\\') {
        index++;
      } else if (quote != null && char == quote) {
        if (quote == "'" && index + 1 < text.length && text[index + 1] == "'") {
          index++;
        } else {
          quote = null;
        }
      } else if (quote == null) {
        if (char == '#' && (index == 0 || text[index - 1].trim().isEmpty)) {
          return text.substring(0, index);
        }
        if ((char == '"' || char == "'") &&
            (index == 0 || RegExp(r'[\s\[\{:,]').hasMatch(text[index - 1]))) {
          quote = char;
        }
      }
    }
    return text;
  }
}
