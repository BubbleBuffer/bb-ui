# bb_tokens

BubbleBuffer design tokens for Flutter: colours, type scale, spacing, layout,
radii and motion. Version 0.6.0 keeps the API extracted from agent-kit.

Import `package:bb_tokens/bb_tokens.dart` or the compatibility `tokens.dart`
entry point. `AppTheme`, `AppColors`, `TypeScale`, `Radii`, `Motion` and the
layout/spacing helpers are shared with `bb_ui`. Hosts supply the font assets;
the gallery includes a complete font registration example and OFL licences.

## Colour provenance

Colours come from the original `agent-kit` profile of
`BubbleBuffer/BubbleBufferDesign`. The profile name records provenance and
remains unchanged in this extraction.

| File | Role | Edit policy |
| --- | --- | --- |
| `tokens/agent-kit.json` | Resolved light and dark palette, with source repository, commit and command | Re-vendor from the design repository |
| `tool/generate_colors.dart` | SDK-only generator | Edit as needed |
| `lib/src/colors.g.dart` | Generated `ProfileColors` values and shadows | Regenerate |

`lib/tokens.dart` contains the non-colour tokens and public API. `AppColors`
and `KitInks` read the generated palette. `kTransparent` and `kMaskOpaque` are
the only hand-written colour constants. `AppColors.palette` exposes the full
resolved profile. CI checks raw colours in `packages/bb_ui` and `apps`.

## Change a colour

Cross-repository sync is explicit; public CI uses only the vendored JSON.

1. Change the profile in the design repository's
   `plugins/bubblebuffer-design/assets/design-system/product-profiles.json`,
   run `npm run design:generate`, and merge the source change.
2. From that checkout, re-vendor the resolved palette:

   ```sh
   node plugins/bubblebuffer-design/skills/bubblebuffer-design-system/scripts/generate-design-css.mjs \
     --profile agent-kit --json <bb-ui-checkout>/packages/bb_tokens/tokens/agent-kit.json
   ```

3. In `packages/bb_tokens`, run `dart tool/generate_colors.dart`.
4. Review and commit the JSON and generated Dart together. CI regenerates the
   Dart and fails on drift. If screenshots change, follow the explicit
   [golden candidate review](../../docs/verification.md) workflow.

The generator locates files relative to its own script, so it also runs as
`dart packages/bb_tokens/tool/generate_colors.dart` from the root.

AGPL-3.0-or-later; see the repository [LICENSE](../../LICENSE).
