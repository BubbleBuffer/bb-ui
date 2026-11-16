// One row of a list of devices: leading icon tile, name with a status, an
// identifier and meta line, and a trailing action.

import 'package:flutter/widgets.dart';

import '../hover.dart';
import '../icons.dart';
import '../tokens.dart';
import '../layout.dart';

/// A device or machine in a list.
///
/// [title] is the name, [status] sits after it (a `StatusPill`), [id] is an
/// identifier in monospace, [meta] are short facts on the line below, and
/// [trailing] is the row's action (a button or an overflow menu). The whole
/// row taps when [onTap] is set; the trailing widget takes its own taps.
/// A [selected] row has the accent seam on its left edge and a raised tile.
class DeviceRow extends StatelessWidget {
  const DeviceRow({
    super.key,
    required this.icon,
    required this.title,
    this.status,
    this.id,
    this.meta = const [],
    this.trailing,
    this.selected = false,
    this.onTap,
  });
  final Ico icon;
  final String title;
  final Widget? status;
  final String? id;
  final List<String> meta;
  final Widget? trailing;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    final tile = Container(
      width: Sizes.tile,
      height: Sizes.tile,
      decoration: BoxDecoration(
        color: selected ? c.textPrimary : c.bgHover,
        borderRadius: Radii.field,
      ),
      child: Center(
        child: Icon20(
          icon,
          size: IconSize.xl,
          color: selected ? c.bgPrimary : c.iconSecondary,
        ),
      ),
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.xxs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(title, style: tsDisplay(context.type.title, c.textPrimary)),
            ?status,
          ],
        ),
        if (id != null) ...[
          const Gap(Space.hair),
          Text(
            id!,
            style: ts(
              context.type.uiSmall,
              c.textSecondary,
              mono: true,
              weight: Weight.regular,
            ),
          ),
        ],
        if (meta.isNotEmpty) ...[
          const Gap(Space.hair),
          Wrap(
            spacing: Space.md,
            children: [
              for (final m in meta)
                Text(
                  m,
                  style: ts(ty.uiSmall, c.textTertiary, weight: Weight.regular),
                ),
            ],
          ),
        ],
      ],
    );
    return Stack(
      children: [
        Hover(
          onTap: onTap,
          selected: selected,
          selectedColor: c.bgHover,
          borderRadius: Radii.ctl,
          padding: const EdgeInsets.fromLTRB(
            Space.lg,
            Space.md,
            Space.md,
            Space.md,
          ),
          // A narrow row puts its action under the text, so the name and
          // status keep room at any text size.
          child: LayoutBuilder(
            builder: (context, box) {
              final stacked = trailing != null && box.maxWidth < Widths.dialog;
              return Row(
                crossAxisAlignment: stacked
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  tile,
                  const Gap(Space.md),
                  Expanded(
                    child: stacked
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [body, const Gap(Space.sm), trailing!],
                          )
                        : body,
                  ),
                  if (trailing != null && !stacked) ...[
                    const Gap(Space.md),
                    trailing!,
                  ],
                ],
              );
            },
          ),
        ),
        if (selected)
          Positioned(
            left: 0,
            top: Space.sm,
            bottom: Space.sm,
            child: IgnorePointer(
              child: Container(
                width: Stroke.seam,
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: Radii.pill,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
