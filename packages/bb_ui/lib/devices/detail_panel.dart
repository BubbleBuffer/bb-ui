// The panel that describes one selected item: eyebrow, name, identifier and
// label/value rows.

import 'package:flutter/widgets.dart';

import '../settings_controls.dart';
import '../tokens.dart';
import '../layout.dart';

/// One label and value pair in a [DetailPanel] or on its own. The label has a
/// fixed column, so several rows line up. A [mono] value is for identifiers
/// and addresses.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow(
    this.label,
    this.value, {
    super.key,
    this.mono = false,
    this.labelWidth = Sizes.labelColumn,
  });
  final String label, value;
  final bool mono;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: ts(ty.ui, c.textTertiary, weight: Weight.regular),
            ),
          ),
          Expanded(
            child: mono
                ? Text(
                    value,
                    style: ts(context.type.code, c.textPrimary, mono: true),
                  )
                : Text(value, style: ts(ty.ui, c.textPrimary)),
          ),
        ],
      ),
    );
  }
}

/// Facts about the selected item, with no choices of its own.
///
/// [eyebrow] is a small label above the name ("Selected"), [title] the name in
/// the display face, and [id] an identifier with a copy button. [rows] are
/// usually `KeyValueRow`s; [actions] go at the bottom.
class DetailPanel extends StatelessWidget {
  const DetailPanel({
    super.key,
    required this.title,
    this.eyebrow,
    this.id,
    this.rows = const [],
    this.actions = const [],
  });
  final String title;
  final String? eyebrow;
  final String? id;
  final List<Widget> rows, actions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!,
            style: ts(
              context.type.uiSmall,
              c.textTertiary,
              weight: Weight.semibold,
            ),
          ),
          const Gap(Space.xs),
        ],
        Text(title, style: tsDisplay(context.type.display, c.textPrimary)),
        if (id != null) ...[
          const Gap(Space.xxs),
          Align(
            alignment: Alignment.centerLeft,
            child: CopyableText(id!, inline: true),
          ),
        ],
        if (rows.isNotEmpty) ...[const Gap(Space.lg), ...rows],
        if (actions.isNotEmpty) ...[
          const Gap(Space.xl),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const Gap(Space.sm),
            actions[i],
          ],
        ],
      ],
    );
  }
}
