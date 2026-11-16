# Migrating to bb_ui 0.8

0.8 makes every design value a named token and splits "mobile" into two
questions. It breaks the API on purpose. Most of the change is mechanical and
`dart run bb_lints:migrate` does it; the rest the compiler and the
[bb_lints](../packages/bb_lints/README.md) rules point at.

## Order

1. Bump `bb_ui` (and `bb_tokens`, `agent_kit` if you use them) to the 0.8 tag.
2. Run the migrate tool on the package, then `dart analyze`.
3. Fix the compile errors (mostly the host's `AppTheme` and `context.mobile`
   uses that were about layout, below).
4. Enable the plugin in `analysis_options.yaml`, switch CI from
   `flutter analyze` to `dart analyze` (only the latter reports plugin
   diagnostics), and work through what it reports: name app-specific values in an `*_tokens.dart`, use scale steps
   for the rest.
5. Re-render screenshots or goldens and review them: spacing snapped to the
   scale moves things by a few pixels.

## Host setup

```dart
// 0.7
AppTheme(
  colors: AppColors.light,
  formFactor: FormFactor.forWidth(constraints.maxWidth),
  child: app,
)

// 0.8
SizeClassScope(
  sizeClass: SizeClass.forWidth(constraints.maxWidth),
  child: AppTheme(
    colors: AppColors.light,
    density: Density.forPlatform(defaultTargetPlatform),
    child: app,
  ),
)
```

`Density` (pointer or touch) sets control heights, icon sizes, row padding and
the type ramp. `SizeClass` (compact below 600, medium below 1000, expanded)
sets layout. A phone is compact and touch; a narrow desktop window is compact
and pointer; a tablet is medium or expanded and touch. `SizeClassScope` is
optional: without one, `context.sizeClass` falls back to the window width.
Wrap the app in `MediaQuery.withClampedTextScaling(maxScaleFactor: 2.0, ...)`
to follow the system text size up to double.

## Renames and replacements

| 0.7 | 0.8 |
| --- | --- |
| `FormFactor`, `AppTheme.formFactor` | `Density` + `SizeClass` |
| `context.mobile` for sizes, padding, type | `context.touch`, or better `context.metrics.*` |
| `context.mobile` for layout (sheet vs popover, full screen, columns) | `context.sizeClass.isCompact`, `context.adaptive(...)`, `AdaptiveLayout` |
| `TypeScale.desktop` / `.mobile` | `TypeScale.pointer` / `.touch` |
| `TypeSpec(16, 20, 640)` | a role: `context.type.title`; new roles `display`, `title`, `item`, `caption`, `micro`, `codeSmall` |
| `tsRaw(size, line, weight, color)` | `ts(context.type.<role>, color, weight: Weight.x)` |
| `ts(..., weight: 600)` | `ts(..., weight: Weight.semibold)` |
| `fw(600)` | `Weight.semibold.fontWeight` |
| `KitSpacing.standard.sm` (8) | `Space.sm` (8); `xs` (4) is now `Space.xxs` |
| `KitLayout.sizeMedium` / `sizeExpanded` | `SizeClass.mediumWidth` / `expandedWidth` |
| `const SizedBox(height: 8)` between children | `const Gap(Space.sm)` or the parent's `spacing:` |
| `Icon20(icon, size: 18)` | `Icon20(icon, size: IconSize.md)` |
| `IconBtn(icon, size: 28, glyph: 20)` | `IconBtn(icon, size: ControlSize.sm, glyph: IconSize.lg)` |
| `PrimaryButton(height: 42)` | `PrimaryButton(size: ControlSize.xl)` (default) |
| `TextBtn(label, height: 28)` | `TextBtn(label, size: ControlSize.sm)` (default) |
| `CopyableText(size: 13)` | `CopyableText(type: context.type.code)` (default) |
| `Spinner(size: 16)` | `Spinner(size: IconSize.sm)` |
| `CodeDisplaySize.px` | `CodeDisplaySize.numerals` (`NumeralSize`), styled by `tsNumeral` |
| `pageRoute(mobile: true)` | `pageRoute(slide: true)` |
| `showPickerSheet(mobileHeightFactor:)` | `showPickerSheet(sheetHeightFactor:)`; the sheet now shows on a compact screen |
| `SearchResultRow.extent(bool mobile)` | `SearchResultRow.extent(context.metrics)` |
| `SearchResultsList(mobile: ...)` | removed; it follows density, `showActive:` overrides |
| `PaletteMetrics.row(bool)` / `field(bool)` | `PaletteMetrics.row(Metrics)` / `PaletteMetrics.field` |
| `Layout.gutter` (18) | 16 (`Space.lg`) |

## The scales

All in `bb_tokens`, re-exported by `bb_ui`:

- `Space`: `hair` 2, `xxs` 4, `xs` 6, `sm` 8, `md` 12, `lg` 16, `xl` 24,
  `xxl` 32, `xxxl` 48. 10, 14 and 20 are gone: the tool rounds them up.
- `ControlSize` (heights): `xs` 24, `sm` 28, `md` 32, `lg` 36, `xl` 44, `xxl` 48.
- `IconSize`: `xs` 14, `sm` 16, `md` 18, `lg` 20, `xl` 24, `xxl` 28.
- `Stroke`: `hair` 1, `regular` 1.5, `bold` 2, `seam` 3.
- `Alpha`: `tint` .12, `wash` .35, `muted` .5, `strong` .9.
- `Radii`, `Motion` (now with `hoverDelay`, `linger`, `confirm`, `toast`,
  `warm`, `spin`), `Widths`, `Heights`, `Sizes` (component dimensions),
  `Layout` (app frame sizes and window shares).
- `context.metrics` (by density): `row`, `listRow`, `tallRow`, `field`,
  `control`, `target`, `icon`, `iconSmall`, `iconGap`, `padX`, `insetX`.

A value that is particular to one app (a page width, an illustration's size)
goes in that app's own `lib/*_tokens.dart` under a name; the rules accept raw
values there.

## Responsive habits

- Give text-bearing boxes a minimum height, not a fixed one:
  `ConstrainedBox(constraints: BoxConstraints(minHeight: ...))`. bb_ui's
  buttons, rows, pills and menu items now grow with the system text size.
- Lay a component out by its own width (`AdaptiveLayout`, `LayoutBuilder`,
  `context.sizeClass` under a pane's own `SizeClassScope`), not the window's.
- Prefer `Wrap`, `Flexible` with an ellipsis, and `Row`/`Column` `spacing:`
  over fixed widths.
- Test it: the gallery's
  [`adaptive_matrix_test.dart`](../apps/gallery/test/adaptive_matrix_test.dart)
  renders every scene at six widths and three text sizes and fails on any
  overflow. Copy it for your app's main screens.
