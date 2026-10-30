// A short status label: a dot (or ring) and a word in a pill.

import 'package:flutter/widgets.dart';

import '../tokens.dart';

/// What a [StatusPill] reports. The word always says it; the mark and colour
/// only repeat it.
enum StatusKind {
  /// Reachable now: a filled dot.
  online,

  /// Not reachable: an empty ring.
  offline,

  /// Doing the host's job right now: a dot in the grounding colour.
  active,

  /// Needs the person's attention: the attention tint.
  attention,

  /// Failed or refused: the danger tint.
  danger,

  /// No mark of its own.
  neutral,
}

/// A status in a pill: "Online", "Offline", "Hosting", "1 request".
///
/// Pills are for statuses only; use a button for anything that acts.
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.kind = StatusKind.neutral});
  final String label;
  final StatusKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = c.palette;
    final (Color fill, Color ink, Color mark) = switch (kind) {
      StatusKind.online => (c.bgHover, c.textSecondary, p.statusDoneMark),
      StatusKind.offline => (c.bgHover, c.textTertiary, c.textTertiary),
      StatusKind.active => (c.bgHover, c.textSecondary, p.spaceMoss),
      StatusKind.attention => (
        p.statusNeedsYouBg,
        p.statusNeedsYouInk,
        p.statusNeedsYouMark,
      ),
      StatusKind.danger => (c.dangerBg, p.dangerInk, p.dangerInk),
      StatusKind.neutral => (c.bgHover, c.textSecondary, c.textTertiary),
    };
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: fill, borderRadius: Radii.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (kind != StatusKind.neutral) ...[
            _Mark(color: mark, ring: kind == StatusKind.offline),
            const SizedBox(width: 6),
          ],
          Text(label, style: ts(context.type.uiSmall, ink, weight: 600)),
        ],
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.color, required this.ring});
  final Color color;
  final bool ring;

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: ring ? null : color,
      border: ring ? Border.all(color: color, width: 1.5) : null,
    ),
  );
}
