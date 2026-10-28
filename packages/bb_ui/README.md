# bb_ui

Flutter primitives without Material, using `bb_tokens`. Version 0.6.0 keeps the
API extracted from agent-kit and adds the search widgets and the command palette.

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
stacks and tooltips. See the
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
