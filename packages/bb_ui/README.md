# bb_ui

Flutter primitives without Material, using `bb_tokens`. Version 0.5.0 keeps the
API extracted from agent-kit and adds the search widgets.

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
selection, settings controls, sheets, foldable stacks and tooltips. See the
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
