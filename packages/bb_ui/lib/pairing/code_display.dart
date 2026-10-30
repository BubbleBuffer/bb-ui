// Showing a code: a one-time code with copy, the number two people compare,
// and the frame a QR code sits in.

import 'package:flutter/widgets.dart';

import '../settings_controls.dart';
import '../tokens.dart';
import 'code_field.dart';

/// Size of the characters in a [CodeDisplay].
enum CodeDisplaySize {
  /// A code to type: 22 px.
  medium(22),

  /// A number to compare at a glance: 44 px.
  large(44);

  const CodeDisplaySize(this.px);
  final double px;
}

/// A code or number in large monospace, cut into groups. Characters are
/// separated by [separator] (a dash for codes, a space for numbers).
class CodeDisplay extends StatelessWidget {
  const CodeDisplay(
    this.code, {
    super.key,
    required this.groups,
    this.separator = '-',
    this.size = CodeDisplaySize.medium,
    this.color,
  });
  final String code;
  final List<int> groups;
  final String separator;
  final CodeDisplaySize size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shown = formatCode(code, groups, separator: separator);
    return Semantics(
      label: codeCharacters(code, groups).split('').join(' '),
      excludeSemantics: true,
      child: Text(
        shown,
        maxLines: 1,
        style: ts(
          TypeSpec(size.px, size.px * 1.15, 400),
          color ?? c.textPrimary,
          mono: true,
        ).copyWith(letterSpacing: size.px * .04),
      ),
    );
  }
}

/// A one-time [code] to type on another device, with its [caption] ("Valid
/// for 5 minutes") and a copy button.
class OneTimeCode extends StatelessWidget {
  const OneTimeCode(
    this.code, {
    super.key,
    required this.groups,
    this.separator = '-',
    this.label,
    this.caption,
  });
  final String code;
  final List<int> groups;
  final String separator;
  final String? label, caption;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.bgSecondary,
        borderRadius: Radii.panel,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(label!, style: ts(ty.uiSmall, c.textSecondary, weight: 600)),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: CodeDisplay(
                    code,
                    groups: groups,
                    separator: separator,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CopyButton(formatCode(code, groups, separator: separator)),
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: 8),
            Text(caption!, style: ts(ty.uiSmall, c.textTertiary, weight: 400)),
          ],
        ],
      ),
    );
  }
}

/// The number both devices show, for the person to compare: [digits] in
/// groups of [group], a [label] above it and a [caption] below.
class ComparisonNumber extends StatelessWidget {
  const ComparisonNumber(
    this.digits, {
    super.key,
    this.group = 3,
    this.label,
    this.caption,
  });
  final String digits;
  final int group;
  final String? label, caption;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    final count = digits.length;
    final groups = [
      for (var at = 0; at < count; at += group)
        at + group <= count ? group : count - at,
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bgSecondary,
        borderRadius: Radii.panel,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(label!, style: ts(ty.uiSmall, c.textSecondary, weight: 600)),
            const SizedBox(height: 8),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CodeDisplay(
              digits,
              groups: groups,
              separator: '  ',
              size: CodeDisplaySize.large,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 8),
            Text(caption!, style: ts(ty.uiSmall, c.textTertiary, weight: 400)),
          ],
        ],
      ),
    );
  }
}

/// The light quiet-zone square a QR code needs, whatever the theme. Pass the
/// code as [child] and draw its modules in [QrFrame.ink]; [caption] goes under
/// the square.
class QrFrame extends StatelessWidget {
  const QrFrame({super.key, required this.child, this.size = 200, this.caption});
  final Widget child;
  final double size;
  final String? caption;

  /// The frame's colour in both themes.
  static Color get paper => ProfileColors.light.surface;

  /// The colour for the code's modules, readable on [paper].
  static Color get ink => ProfileColors.light.ink;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size / 12),
          decoration: BoxDecoration(
            color: paper,
            borderRadius: Radii.field,
            border: Border.all(color: c.borderStrong),
          ),
          child: child,
        ),
        if (caption != null) ...[
          const SizedBox(height: 8),
          Text(
            caption!,
            textAlign: TextAlign.center,
            style: ts(context.type.uiSmall, c.textSecondary, weight: 400),
          ),
        ],
      ],
    );
  }
}
