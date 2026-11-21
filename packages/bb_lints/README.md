# bb_lints

An analyzer plugin that keeps Flutter UI code on the `bb_tokens` scales: no
hand-written spacing, sizes, radii, strokes, opacities, type, colours or
durations in widgets. It runs in the IDE and in `dart analyze`, so CI fails on
a violation like on any other warning.

Run `dart analyze`, not `flutter analyze`, in CI: with Flutter 3.47
`flutter analyze` does not report analyzer-plugin diagnostics at all. Run it
on the package or workspace root (or a whole package's directory), never on
folders inside one: `dart analyze lib test` silently skips every plugin. The
first run after enabling the plugin fetches and compiles it; in a fresh CI
workspace `dart analyze` waits for that.

It also ships `dart run bb_lints:migrate`, which moves a package to bb_ui 0.8
in bulk.

## Enable

In the package's (or workspace's) root `analysis_options.yaml`, next to the
existing `include:`:

```yaml
plugins:
  bb_lints:
    git:
      url: https://github.com/BubbleBuffer/bb-ui
      ref: v0.9.1
      path: packages/bb_lints
    diagnostics:
      # Opt-in rules; the others are on by default.
      no_magic_numbers: true
      no_window_size: true
```

Restart the analysis server (or the IDE) after changing the `plugins`
section. Plugins need
Dart 3.10 or later (bb-ui uses 3.13). Inside bb-ui the plugin is referenced by
`path:` and excluded from the workspace's own analysis (see the root
`analysis_options.yaml`).

## Rules

| Rule | Default | Flags |
| --- | --- | --- |
| `tokens_only` | on | A number, or a constant written outside a token library, where a style value goes: `EdgeInsets`, `SizedBox`, `Radius`, `BorderSide`, `BoxConstraints`, `TextStyle`, `BoxShadow`..., any widget's `width`, `height`, `size`, `padding`, `spacing`, `radius`, `duration`, `opacity`... arguments, `..strokeWidth =` style assignments, and widget constructor defaults such as `this.height = 42`. |
| `no_raw_colors` | on | `Color(...)`, `Colors.*`, `CupertinoColors.*`, and a literal alpha in `withValues` / `withOpacity` / `withAlpha`. |
| `no_raw_text_style` | on | `TextStyle` / `StrutStyle` that set size, weight, line height, family or tracking; `FontWeight.*`; `copyWith(fontSize: ...)` and friends. A style that only colours, highlights or italicises a span is fine. |
| `use_gap` | on | `SizedBox(width: x)` / `SizedBox(height: x)` used as a spacer in a `children:` list. Use `Gap(Space.x)` or the parent's `spacing:`. |
| `no_material` | on | Importing `material.dart` or `cupertino.dart`. |
| `no_magic_numbers` | opt-in | Any other number that is not a named constant. `0` and `1` are always allowed, `2` as an operand (`width / 2`). |
| `no_window_size` | opt-in | `MediaQuery.sizeOf` or `MediaQuery.of(...).size` in a component. Lay out by your own constraints: `context.sizeClass`, `AdaptiveLayout`, `LayoutBuilder`. |

What counts as a token: anything declared in `package:bb_tokens`, or in an
app's own `tokens.dart`, `*_tokens.dart` or `tokens/` folder. Raw values are
allowed there, so an app keeps its particular layout values (page widths,
illustration sizes) in one named place; see
[the gallery's](../../apps/gallery/lib/gallery_tokens.dart). A constant that
only aliases tokens (`static const _gap = Space.xxs`) counts as a token.
Generated files (`*.g.dart`, `*.freezed.dart`) and tests are not checked.

When a raw value is right (a route that sizes against the screen, glyph
metrics in an icon font's units), suppress it on the line with a reason:

```dart
// A dialog route sizes against the screen it covers.
// ignore: bb_lints/no_window_size
final size = MediaQuery.sizeOf(context);
```

## Quick fixes

In the IDE, `tokens_only` on a spacing, radius, stroke or alpha literal offers
the nearest step (`EdgeInsets.all(10)` → `EdgeInsets.all(Space.md)`), and
`use_gap` offers `Gap(...)`. Plugin fixes apply one at a time; use the migrate
tool for many.

## Migrate a package to bb_ui 0.8

From a checkout of bb-ui (after `dart pub get` in `packages/bb_lints`), with
the target package's dependencies fetched:

```sh
dart run bb_lints:migrate /path/to/app            # rewrite in place
dart run bb_lints:migrate /path/to/app --dry-run  # list the files only
```

It resolves every library under `lib/` and rewrites what is mechanical:

- spacing literals in `EdgeInsets`, `spacing:`, `padding:` and gaps to the
  nearest `Space` step (a tie goes to the larger step), radii to `Radii`,
  stroke widths to `Stroke`, literal alphas to `Alpha`;
- spacer `SizedBox`es to `Gap`;
- `Icon20(size:)`, `IconBtn(size:, glyph:)`, `CopyButton` and `Spinner` sizes
  to `IconSize` / `ControlSize`, and `PrimaryButton` / `SecondaryButton` /
  `TextBtn` `height:` to `size: ControlSize.x`, when within 4 px of a step;
- `tsRaw(...)` and literal `TypeSpec(...)` to the nearest role of
  `--type-scale` (default `TypeScale.pointer`; pass `context.type` where a
  `BuildContext` is in scope), keeping a different weight as `weight:`;
- integer weights to `Weight`, `fw(n)` to `Weight.x.fontWeight`;
- `context.mobile` to `context.touch`, `TypeScale.desktop` / `.mobile` to
  `.pointer` / `.touch`.

It adds `import 'package:bb_ui/bb_ui.dart';` where a rewritten library needs
it (`--import <uri>` or `--no-import` to change that), then formats the files
it changed (`--no-format` for a repository that is not dart-formatted).

Review its output where a number is not a design step: a spacer that must
match a sibling's width (a leading icon column) is snapped like any other
gap, and `tsRaw` calls whose size is an expression (`m ? 15 : 14`) are left
for you. Radii inside a `CustomPainter` are left as written. Run `dart analyze` afterwards: compile errors and the rules list
what needs a decision, such as a `context.touch` that was really about screen
width (use `context.sizeClass.isCompact`), widths and heights to name, and
colours to move into the palette. See
[the migration guide](../../docs/migration-0.8.md).

## Develop

```sh
dart pub get
dart analyze
dart test
```

Rule tests use `analyzer_testing` with its mock Flutter package. AGPL-3.0-or-later;
see the repository [LICENSE](../../LICENSE).
