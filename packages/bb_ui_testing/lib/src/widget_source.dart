/// Inclusive source line interval used by the lexical LCOV audit.
class SourceLines {
  const SourceLines(this.first, this.last);
  final int first;
  final int last;
  bool contains(int line) => line >= first && line <= last;
}

class WidgetSourceClass {
  WidgetSourceClass(
    this.name,
    this.parent,
    this.stateWidget,
    this.body,
    this.build,
  );
  final String name;
  final String parent;
  final String? stateWidget;
  final SourceLines? body;
  final SourceLines? build;
}

class _Token {
  const _Token(this.text, this.line);
  final String text;
  final int line;
}

const _tripleQuoteLength = 3;
const _escapeLength = 2;

/// Blanks comments and strings without moving any source line or character.
String maskDartSource(String source) {
  final result = StringBuffer();
  var i = 0;
  void blank(int start, int end) {
    for (var j = start; j < end && j < source.length; j++) {
      result.write(source[j] == '\n' ? '\n' : ' ');
    }
  }

  while (i < source.length) {
    final start = i;
    if (source.startsWith('//', i)) {
      final end = source.indexOf('\n', i);
      i = end < 0 ? source.length : end;
    } else if (source.startsWith('/*', i)) {
      var depth = 1;
      i += '/*'.length;
      while (i < source.length && depth > 0) {
        if (source.startsWith('/*', i)) {
          depth++;
          i += '/*'.length;
        } else if (source.startsWith('*/', i)) {
          depth--;
          i += '*/'.length;
        } else {
          i++;
        }
      }
    } else if (source[i] == '"' || source[i] == "'") {
      final quote = source[i];
      final raw = i > 0 && source[i - 1] == 'r';
      final triple = quote * _tripleQuoteLength;
      final delimiter = source.startsWith(triple, i) ? triple : quote;
      i += delimiter.length;
      while (i < source.length) {
        if (!raw && source[i] == r'\') {
          i += _escapeLength;
        } else if (source.startsWith(delimiter, i)) {
          i += delimiter.length;
          break;
        } else {
          i++;
        }
      }
    } else {
      result.write(source[i++]);
      continue;
    }
    blank(start, i);
  }
  return result.toString();
}

List<WidgetSourceClass> parseWidgetSource(String source) {
  final masked = maskDartSource(source);
  final tokens = <_Token>[];
  var line = 1;
  var offset = 0;
  for (final match in RegExp(
    r'[A-Za-z_$][A-Za-z0-9_$]*|=>|[^\s]',
  ).allMatches(masked)) {
    while (offset < match.start) {
      if (masked[offset++] == '\n') {
        line++;
      }
    }
    tokens.add(_Token(match.group(0)!, line));
  }
  int close(int start, String open, String end) {
    var depth = 0;
    for (var i = start; i < tokens.length; i++) {
      if (tokens[i].text == open) {
        depth++;
      }
      if (tokens[i].text == end && --depth == 0) {
        return i;
      }
    }
    return tokens.length - 1;
  }

  final classes = <WidgetSourceClass>[];
  for (var i = 0; i + 1 < tokens.length; i++) {
    if (tokens[i].text != 'class') {
      continue;
    }
    final name = tokens[i + 1].text;
    var parent = '';
    String? stateWidget;
    var angle = 0;
    var j = i + 1;
    for (; ++j < tokens.length;) {
      final text = tokens[j].text;
      if (text == '<') {
        angle++;
      }
      if (text == '>') {
        angle--;
      }
      if (angle == 0 && (text == '{' || text == ';')) {
        break;
      }
      if (angle == 0 && (text == 'extends' || text == '=')) {
        var p = j + 1;
        if (p >= tokens.length) {
          break;
        }
        parent = tokens[p].text;
        if (p + 1 < tokens.length && tokens[p + 1].text == '.') {
          p += _escapeLength;
          if (p >= tokens.length) {
            break;
          }
          parent = tokens[p].text;
        }
        if (parent == 'State' &&
            p + _escapeLength < tokens.length &&
            tokens[p + 1].text == '<') {
          var s = p + _escapeLength;
          stateWidget = tokens[s].text;
          if (s + _escapeLength < tokens.length && tokens[s + 1].text == '.') {
            s += _escapeLength;
            stateWidget = tokens[s].text;
          }
        }
      }
    }
    SourceLines? body;
    SourceLines? build;
    if (j < tokens.length && tokens[j].text == '{') {
      final end = close(j, '{', '}');
      body = SourceLines(tokens[j].line, tokens[end].line);
      var depth = 0;
      for (var k = j + 1; k < end; k++) {
        final text = tokens[k].text;
        if (text == '{') {
          depth++;
        }
        if (text == '}') {
          depth--;
        }
        if (depth != 0 || text != 'build' || tokens[k + 1].text != '(') {
          continue;
        }
        var start = close(k + 1, '(', ')') + 1;
        if (start < end && tokens[start].text == 'async') {
          start++;
        }
        if (start >= end) {
          continue;
        }
        if (tokens[start].text == '{') {
          build = SourceLines(
            tokens[start].line,
            tokens[close(start, '{', '}')].line,
          );
          break;
        }
        if (tokens[start].text == '=>') {
          var finish = start + 1;
          var nesting = 0;
          for (; finish < end; finish++) {
            final t = tokens[finish].text;
            if (t == '(' || t == '[' || t == '{') {
              nesting++;
            }
            if (t == ')' || t == ']' || t == '}') {
              nesting--;
            }
            if (t == ';' && nesting == 0) {
              break;
            }
          }
          build = SourceLines(tokens[start].line, tokens[finish].line);
          break;
        }
      }
      i = end;
    }
    classes.add(WidgetSourceClass(name, parent, stateWidget, body, build));
  }
  return classes;
}
