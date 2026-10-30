// A chord of keys: several [Keycap]s joined by plus signs.

import 'package:flutter/widgets.dart';

import 'palette.dart' show Keycap;
import 'tokens.dart';

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
            Keycap(keys[i], raised: true),
          ],
        ],
      ),
    );
  }
}
