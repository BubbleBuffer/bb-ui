# bb-ui

Shared BubbleBuffer Flutter primitives and design tokens, without Material or
an agent backend. `bb_ui` is version **0.11.4** (`bb_tokens` is **0.10.1**, `bb_lints`
**0.9.1**); moving from 0.7 is in
the [migration guide](docs/migration-0.8.md).

| Package | Purpose |
| --- | --- |
| `packages/bb_tokens` | Colours, typography, spacing, radii, motion and themes |
| `packages/bb_ui` | Buttons, fields, menus, sheets, tooltips, selection, stacks, device lists, pairing, session chrome, and editor controls |
| `packages/bb_lints` | Analyzer plugin that keeps UI code on the tokens, and the 0.8 migrate tool |
| `packages/bb_ui_testing` | Widget coverage checks and step-driven Flutter test journeys |
| `apps/gallery` | Interactive neutral specimens and Linux golden tests |

The packages retain their existing APIs and directory names after extraction
from `BubbleBuffer/agent-kit`. The agent-specific gallery remains in agent-kit.
The palette still records its original `agent-kit` design profile; extraction
does not silently change that profile or its generated values.

## Consume

Pin a reviewed commit or release tag. `bb_ui` resolves its sibling `bb_tokens`
through its relative package dependency; consumers do not need a local design
repository.

```yaml
dependencies:
  bb_ui:
    git:
      url: https://github.com/BubbleBuffer/bb-ui
      ref: v0.11.4
      path: packages/bb_ui
```

For a tokens-only consumer use the same Git dependency with
`path: packages/bb_tokens`. See [bb_ui](packages/bb_ui/README.md) for theme setup
and [bb_tokens](packages/bb_tokens/README.md) for the scales and colour
generation.

Add [bb_ui_testing](docs/testing.md) as a dev dependency to check widget
coverage and track the actions users take to complete a journey.

### Style rules

No widget writes a number for spacing, size, type, stroke, opacity, colour or
timing; it picks a token. Enable [bb_lints](packages/bb_lints/README.md) in
your `analysis_options.yaml` so the analyzer (IDE and CI) enforces the same
rules bb-ui follows:

```yaml
plugins:
  bb_lints:
    git:
      url: https://github.com/BubbleBuffer/bb-ui
      ref: v0.9.1
      path: packages/bb_lints
```

## Develop

Use Flutter 3.47.5 with Dart 3.13.4, matching CI. From the repository root:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos   # with the bb_lints rules; flutter analyze skips plugins
(cd packages/bb_lints && dart pub get && dart analyze && dart test)
(cd packages/bb_tokens && flutter test)
(cd packages/bb_ui && flutter test)
(cd packages/bb_ui_testing && flutter test)
(cd apps/gallery && flutter test --exclude-tags golden)
(cd apps/gallery && flutter test --tags golden)
bash scripts/check-private-strings.sh --patterns /path/to/private-rules
```

Run the [gallery](apps/gallery/README.md) with `flutter run -d chrome` from
`apps/gallery`. See the [docs index](docs/README.md) for testing, CI,
golden baselines and migration.

## Licence

AGPL-3.0-or-later, as inherited from agent-kit; see [LICENSE](LICENSE). Bundled fonts
retain their SIL Open Font License notices in
[`apps/gallery/assets/fonts/licenses`](apps/gallery/assets/fonts/licenses).
