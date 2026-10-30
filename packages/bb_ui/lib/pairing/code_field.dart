// Entry of codes and identifiers: upper-case letters and digits in fixed
// groups, with the separators put in as the person types.

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../fields.dart';
import '../tokens.dart';

/// The letters and digits of [text] in upper case, with everything else
/// (separators, spaces, punctuation) dropped and at most as many characters
/// as [groups] add up to.
String codeCharacters(String text, List<int> groups) {
  final max = groups.fold<int>(0, (a, b) => a + b);
  final kept = text.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
  return kept.length > max ? kept.substring(0, max) : kept;
}

/// [text] cut into [groups] joined by [separator]. A separator is written only
/// when a character follows it, so the text never ends in one and Backspace
/// always removes a character.
String formatCode(String text, List<int> groups, {String separator = '-'}) {
  final chars = codeCharacters(text, groups);
  final out = StringBuffer();
  var at = 0;
  for (var g = 0; g < groups.length && at < chars.length; g++) {
    if (g > 0) out.write(separator);
    final end = math.min(at + groups[g], chars.length);
    out.write(chars.substring(at, end));
    at = end;
  }
  return out.toString();
}

/// Formats each edit as [formatCode] does and keeps the caret after the same
/// character, so typing, pasting a code with or without separators, and
/// deleting all behave. Deleting a separator deletes the character before it.
class CodeFormatter extends TextInputFormatter {
  const CodeFormatter(this.groups, {this.separator = '-'});

  /// The size of each group, for example `[4, 4, 4, 4]`.
  final List<int> groups;
  final String separator;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var chars = codeCharacters(newValue.text, groups);
    final oldChars = codeCharacters(oldValue.text, groups);
    final caret = newValue.selection.isValid
        ? newValue.selection.extentOffset.clamp(0, newValue.text.length)
        : newValue.text.length;
    var before = codeCharacters(newValue.text.substring(0, caret), groups).length;
    if (chars == oldChars &&
        newValue.text.length < oldValue.text.length &&
        before > 0) {
      // Only a separator went: take the character in front of it instead.
      chars = chars.substring(0, before - 1) + chars.substring(before);
      before -= 1;
    }
    final text = formatCode(chars, groups, separator: separator);
    var offset = before;
    var used = 0;
    for (var g = 0; g < groups.length - 1; g++) {
      used += groups[g];
      if (before > used) offset += separator.length;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: math.min(offset, text.length)),
    );
  }
}

/// A single-line field for a code or identifier in monospace: upper-case
/// letters and digits only, [groups] of them with [separator]s inserted as
/// the person types or pastes. Read the characters with
/// `codeCharacters(controller.text, groups)`.
class CodeField extends StatefulWidget {
  const CodeField({
    super.key,
    required this.controller,
    required this.groups,
    this.separator = '-',
    this.placeholder = '',
    this.semanticLabel,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.fieldKey,
  });
  final TextEditingController controller;
  final List<int> groups;
  final String separator;

  /// Shown while empty; usually the pattern ("XXXX-XXXX").
  final String placeholder;
  final String? semanticLabel;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final Key? fieldKey;

  @override
  State<CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<CodeField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      textField: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _focus.requestFocus,
        child: FieldFrame(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: PlainField(
            key: widget.fieldKey,
            controller: widget.controller,
            focusNode: _focus,
            style: ts(const TypeSpec(15, 22, 400), c.textPrimary, mono: true),
            placeholder: widget.placeholder,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            autofocus: widget.autofocus,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            inputFormatters: [
              CodeFormatter(widget.groups, separator: widget.separator),
            ],
          ),
        ),
      ),
    );
  }
}
