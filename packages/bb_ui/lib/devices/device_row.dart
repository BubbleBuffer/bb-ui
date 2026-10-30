// One row of a list of devices: leading icon tile, name with a status, an
// identifier and meta line, and a trailing action.

import 'package:flutter/widgets.dart';

import '../hover.dart';
import '../icons.dart';
import '../tokens.dart';

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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: selected ? c.textPrimary : c.bgHover,
        borderRadius: Radii.field,
      ),
      child: Center(
        child: Icon20(
          icon,
          size: 22,
          color: selected ? c.bgPrimary : c.iconSecondary,
        ),
      ),
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              title,
              style: tsDisplay(const TypeSpec(16, 20, 640), c.textPrimary),
            ),
            ?status,
          ],
        ),
        if (id != null) ...[
          const SizedBox(height: 2),
          Text(
            id!,
            style: ts(const TypeSpec(12, 16, 400), c.textSecondary, mono: true),
          ),
        ],
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 2),
          Wrap(
            spacing: 12,
            children: [
              for (final m in meta)
                Text(m, style: ts(ty.uiSmall, c.textTertiary, weight: 400)),
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
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(
            children: [
              tile,
              const SizedBox(width: 12),
              Expanded(child: body),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
        ),
        if (selected)
          Positioned(
            left: 0,
            top: 8,
            bottom: 8,
            child: IgnorePointer(
              child: Container(
                width: 3,
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
