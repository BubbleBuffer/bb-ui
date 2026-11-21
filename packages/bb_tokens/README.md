# bb_tokens

BubbleBuffer design tokens for Flutter: colours, type scale, spacing, sizes,
strokes, opacities, layout, radii, motion, density and size classes. Version
0.9.0 is the only place in the kit that writes a design number; see the
[migration guide](../../docs/migration-0.8.md) for the scales.

Import `package:bb_tokens/bb_tokens.dart` or the compatibility `tokens.dart`
entry point. `AppTheme`, `AppColors`, `TypeScale`, `Space`, `ControlSize`, `IconSize`,
`Stroke`, `Alpha`, `Widths`, `Heights`, `Sizes`, `Radii`, `Motion`, `Density`,
`Metrics` and `SizeClass` are shared with `bb_ui`. `TypeSpec`s are made only
by the type scale: a new kind of text is a new role here, not a size at a call
site. Hosts supply the font assets;
the gallery includes a complete font registration example and OFL licences.

## Where the tokens come from

Every design value comes from `BubbleBuffer/BubbleBufferDesign`: its
`tokens.json` and product profiles generate both CSS and the Dart in this
package. `lib/src/bb_tokens.g.dart` is a committed copy of that Dart output;
its first line names the design repository commit it was generated from. Do not
edit it.

| Generated class | Holds |
| --- | --- |
| `ProfileColors` | The kit palette (agent-kit profile roles), `light` and `dark`, with shadows |
| `FamilyColors`, `SemanticColors`, `MuseColors` | The family palette of `tokens.json` |
| `Contract` | Radii, control heights, spacing, borders, weights, motion and elevation, named by token path |
| `ProductDialect` | Every product's dialect: colours, focus, radii, height |

`lib/tokens.dart` holds the public API and the kit-only values the contract
does not have (the `settle` curve, `Space.hair` and `Space.xs`, type sizes,
layout widths, density). `AppColors` and `KitInks` read the generated
palette. `kTransparent` and `kMaskOpaque` are the only hand-written colour
constants. The bb_lints `no_raw_colors` rule keeps raw colours out of every
other library.

Roles follow `tokens.json`: `accentText` is accent-coloured text and
`accentInk` is ink on an accent fill. Weights are the contract weights (UI
450 and 720, display 620 and 760). Atkinson Hyperlegible Next and Bricolage
Grotesque are variable fonts, so `Weight.axis` is applied exactly through the
`wght` axis; Fragment Mono is static and keeps 400.

## Change a token

Cross-repository sync is explicit; public CI cannot reach the design
repository.

1. Change `tokens.json` or `product-profiles.json` in the design repository,
   run `npm run design:generate` and merge the change.
2. From that checkout on the merged commit, write the Dart copy:

   ```sh
   node plugins/bubblebuffer-design/skills/bubblebuffer-design-system/scripts/generate-design-tokens.mjs \
     --dart <bb-ui-checkout>/packages/bb_tokens/lib/src/bb_tokens.g.dart
   ```

   `design:check` with the same `--dart` argument reports a stale copy.
3. Commit the generated file. CI checks that its header names a design
   commit. If screenshots change, follow the explicit
   [golden candidate review](../../docs/verification.md) workflow.

AGPL-3.0-or-later; see the repository [LICENSE](../../LICENSE).
