# bb_ui

Flutter primitives without Material, using `bb_tokens`. Version 0.7.1 keeps the
API extracted from agent-kit, with the search widgets and the command palette,
and adds the device, pairing and session components.

Import `package:bb_ui/bb_ui.dart` for the primitives and re-exported tokens.
`package:bb_ui/tokens.dart` remains a compatibility entry point. A host provides
an `AppTheme` under its `WidgetsApp`, with a form factor derived from the current
available width:

```dart
LayoutBuilder(
  builder: (context, constraints) => AppTheme(
    colors: AppColors.light,
    formFactor: FormFactor.forWidth(constraints.maxWidth),
    child: PrimaryButton(label: 'Save', onTap: save),
  ),
)
```

The host registers the fonts named by the tokens. The
[gallery pubspec](../../apps/gallery/pubspec.yaml) shows the bundled font setup
and includes the corresponding licences. Use `AppColors.darkTheme` for dark
presentation. Context accessors include `context.colors`, `context.type` and
`context.mobile`.

The public library exports buttons, fields, hover/focus surfaces, icons, ruled
lines, marked lists, menus, modals, pickers, reference chips, routing, search,
selection, settings controls, search, the command palette, sheets, foldable
stacks, tooltips, device lists, pairing and code entry, notices and toasts,
and session chrome. See the
[gallery](../../apps/gallery/README.md) for a small executable specimen set;
it is not a complete state or accessibility audit of every export.

Widgets read theme roles; raw colour literals belong only in the token source.
Run `flutter test` in this package for the inherited tooltip interaction tests.
AGPL-3.0-or-later; see the repository [LICENSE](../../LICENSE).

## Search

`package:bb_ui/search.dart` (also exported by `bb_ui.dart`) draws search results
over neutral view models; the host maps its own hits onto them and keeps its
data, ranking and navigation.

- `SearchResult` is one row: `id`, a title with highlight ranges and a tone
  (normal, muted, or a stand-in in tertiary italics), an optional secondary
  line and snippet (also with ranges), an icon or a `leading` widget, and a
  `typeLabel`. `termHighlights(text, terms)` finds the ranges of literal terms,
  ignoring case. Optional keys (`rowKey`, `secondaryKey`, `snippetKey`) let a
  host find its rows.
- `SearchResultRow`, `HighlightedText`, `SearchGroupHeader` and
  `SearchResultsList` draw rows, marked text, group headers and the grouped
  list over `SearchResultSection`s. They report a tap with the `SearchResult`.
- `SearchTypeChips` draws `SearchTypeChip`s; what a chip means is the host's.
- `SearchPanel` holds the field, a `filters` slot, the grouped results and the
  explanation lines. Up and Down move the selection through the flattened
  results (wrapping), Enter picks it, and the field takes focus on open.
  `selectionResetKey` returns the selection to the first row when it changes.

Nothing here is specific to one product: group labels, notes and chip meanings
are strings and callbacks the host passes in.

## Command palette

`package:bb_ui/palette.dart` (also exported by `bb_ui.dart`) draws a command
palette over a host-supplied list. The host keeps what a command does, its
`BuildContext`, its shortcut bindings and its enabled checks; it maps each
command onto a neutral model and runs the one the user picks.

- `PaletteCommand` is one row: `id`, `title`, an optional `subtitle` (muted,
  also searched), an optional `group` (the label above its run of rows;
  ungrouped commands come first), a `shortcutLabel` (the host's own text for
  its keys), `enabled` with a `disabledReason`, an `icon` from `Ico`, and a
  `rowKey`.
- `showCommandPalette(context, commands: ...)` opens the palette on the
  navigator: a 560-wide panel 14% from the top on a wide window, the full
  screen with a Cancel button on a phone. The future completes with the command
  the user ran, or null when they closed it, once the palette is gone and
  focus is back on what had it before. The host then runs the command, so a
  command that opens something or moves focus is not overtaken by the restore.
  The host binds its own open shortcut.
- `CommandPalette` is the panel itself, for hosts that place it. Typing
  filters; Up and Down move the selection and stop at the ends; Enter runs it;
  Escape closes (`onClose`); Tab stays in the field. A disabled command is
  listed with its reason and can be selected, but Enter and a tap do not run it.
- `fuzzyMatch(query, text)` is the matching: case-insensitive, spaces in the
  query ignored, the characters in order. A contiguous match beats a spread-out
  one, a word start beats mid-word and an earlier match beats a later one.
  Matches are marked in the title; a subtitle-only match ranks below any title
  match. Within a group the better match comes first; equal matches keep the
  host's order.
- `Keycap` draws a shortcut label or key name in a small box.

The look follows the workbench design mock (SPEC 7.13), in the BubbleBuffer
skin: group labels are the mono uppercase labels search uses rather than the
mock's sentence-case ones, the panel is `bgElevated` with a `borderStrong`
edge, and the selected row has the `bgHover` fill with a 2px `threadStrong` bar.

## Devices, pairing and session chrome

Neutral components for an app that lists devices, pairs them with a code and
shows a full-screen session. They take plain strings, icons and callbacks; the
host keeps its data and behaviour. They read the same light and dark theme as
everything else, so the dark theme is the whole of a dark-first product.

- `StatusPill` (`StatusKind`: online, offline, active, attention, danger,
  neutral). The word always says the status; the dot or ring only repeats it.
- `DeviceRow`: an icon tile, a name with a status, a monospace identifier, meta
  facts and a trailing action. A `selected` row has the accent seam.
  `DetailPanel` and `KeyValueRow` describe the selected item.
  `SectionHeader` and `SectionLabel` head a section.
- Buttons: `PrimaryButton`, `SecondaryButton` (also `danger`) and `TextBtn`
  take an `icon` from `Ico`; a null `onTap` draws the first two disabled and
  `PrimaryButton(expand: true)` fills the width. `CopyableText(inline: true)` and `CopyButton` copy
  an identifier. `Keycap` and `KeyChord` draw shortcuts.
- Code entry: `CodeField` takes upper-case letters and digits in `groups`
  (`[4, 4, 4, 4]`) and inserts the separators as the person types or pastes.
  `CodeFormatter`, `formatCode` and `codeCharacters` are the same rules without
  the widget. `OneTimeCode` shows a code with copy, `ComparisonNumber` the
  number two people compare, and `QrFrame` the light square a QR code needs
  (the host draws the code in `QrFrame.ink`).
- Messages: `NoticeBanner` (`NoticeKind`: info, success, attention, danger,
  with a title, actions and dismiss), `EmptyState`, `ConfirmBox` and
  `showConfirm` (now with `cancelLabel`) and `ToastCard` with `showToast`,
  which places a card on the root overlay, counts down with a line along its
  edge (none with reduced motion) and removes itself.
- Session chrome: `EdgeTab` (the resting tab) and `EdgeStrip` with
  `EdgeStripButton`s hang from the top edge; `MetricsPanel` with `Sparkline`
  shows live numbers; `DisplayPicker` draws the screens of a machine to scale
  as a map and a list, and the number keys 1 to 9 pick one.

Icons come from `Ico`, which maps to Lucide. This version adds `monitor`,
`monitorPlay`, `laptop`, `server`, `copy`, `pencil`, `refresh`, `info`,
`circleCheck`, `circleAlert`, `triangleAlert`, `pointer`, `pointerClick`,
`activity`, `gauge`, `volume`, `logOut`, `gamepad`, `qrCode`, `globe`,
`radio`, `arrowRight`, `lock`, `userCheck`, `keyboard` and `chevronUp`.
