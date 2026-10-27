// The filter chips of a search panel: a wrapped row of pills, the selected ones
// filled. What a chip means, and what its tap does, is the host's.

import 'package:flutter/widgets.dart';

import '../icons.dart';
import '../tokens.dart';
import 'search_result.dart';

/// A wrapped row of [chips]. Each is keyed `search-type-<id>`.
class SearchTypeChips extends StatelessWidget {
  const SearchTypeChips({super.key, required this.chips});
  final List<SearchTypeChip> chips;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final chip in chips)
        _TypeChip(
          key: ValueKey('search-type-${chip.id}'),
          label: chip.label,
          selected: chip.selected,
          removable: chip.removable,
          onTap: chip.onTap,
        ),
    ],
  );
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.removable,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Whether the chip ends with a close mark (its tap removes the value).
  final bool removable;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    final m = context.mobile;
    final ink = selected ? c.bgPrimary : c.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // No alignment here: an aligned Container fills the Wrap's width, and
        // each chip would then take its own row.
        child: Container(
          constraints: BoxConstraints(minHeight: m ? Layout.minTapTarget : 24),
          padding: EdgeInsets.symmetric(horizontal: m ? 12 : 10),
          decoration: BoxDecoration(
            color: selected ? c.textPrimary : null,
            border: Border.all(color: selected ? c.textPrimary : c.border),
            borderRadius: Radii.pill,
          ),
          // Centred at the content's own width, so the pill keeps its minimum
          // height without stretching across the Wrap.
          child: Center(
            widthFactor: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: ts(m ? ty.ui : ty.uiSmall, ink, weight: 500),
                ),
                if (removable) ...[
                  const SizedBox(width: 4),
                  Icon20(Ico.close, size: 12, color: ink),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
