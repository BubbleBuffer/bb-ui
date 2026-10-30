// Keycaps: one key as a small monospace chip, and a chord of keys.

import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// One key of a shortcut ("Ctrl", "Shift", "Z") in monospace on a chip with a
/// heavier bottom edge. Not interactive.
class Keycap extends StatelessWidget {
  const Keycap(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.bgTertiary,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.sm)),
        border: Border.all(color: c.thread),
        boxShadow: [BoxShadow(color: c.threadStrong, offset: const Offset(0, 1.5))],
      ),
      child: Text(
        label,
        style: ts(
          const TypeSpec(11, 14, 400),
          c.textPrimary,
          mono: true,
        ),
      ),
    );
  }
}

/// A shortcut as [Keycap]s joined by "+". It reads as one phrase to screen
/// readers: "Ctrl plus Alt plus Z".
class KeyChord extends StatelessWidget {
  const KeyChord(this.keys, {super.key});
  final List<String> keys;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: keys.join(' plus '),
      excludeSemantics: true,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            if (i > 0)
              Text('+', style: ts(context.type.uiSmall, c.textTertiary)),
            Keycap(keys[i]),
          ],
        ],
      ),
    );
  }
}
