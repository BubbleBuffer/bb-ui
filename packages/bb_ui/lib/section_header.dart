// Headings of a screen's sections.

import 'package:flutter/widgets.dart';

import 'icons.dart';
import 'tokens.dart';

/// A section's title in the display face with an optional [subtitle] and an
/// action ([trailing]) at the end. The action drops below the title when the
/// two do not fit side by side.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.trailing,
    this.large = true,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// The section's own title (true) or a sub-section's (false).
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: tsDisplay(large ? ty.h1 : ty.h3, c.textPrimary, weight: 700),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: ts(ty.ui, c.textSecondary, weight: 400)),
        ],
      ],
    );
    if (trailing == null) return text;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      runSpacing: 12,
      children: [text, trailing!],
    );
  }
}

/// A small label above a group of rows: "This PC", "Selected". An [icon]
/// goes before it.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.icon});
  final String text;
  final Ico? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon20(icon!, size: 16, color: c.iconSecondary),
          const SizedBox(width: 8),
        ],
        Text(text, style: ts(context.type.uiSmall, c.textSecondary)),
      ],
    );
  }
}
