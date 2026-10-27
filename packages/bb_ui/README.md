# bb_ui

Flutter primitives without Material, using `bb_tokens`. Version 0.4.0 preserves
the API extracted from agent-kit.

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
lines, marked lists, menus, modals, pickers, reference chips, routing, selection,
settings controls, sheets, foldable stacks and tooltips. See the
[gallery](../../apps/gallery/README.md) for a small executable specimen set;
it is not a complete state or accessibility audit of every export.

Widgets read theme roles; raw colour literals belong only in the token source.
Run `flutter test` in this package for the inherited tooltip interaction tests.
AGPL-3.0-or-later; see the repository [LICENSE](../../LICENSE).
