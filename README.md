# bb-ui

Shared BubbleBuffer Flutter primitives and design tokens, without Material or
an agent backend. Both packages are version **0.7.0**.

| Package | Purpose |
| --- | --- |
| `packages/bb_tokens` | Colours, typography, spacing, radii, motion and themes |
| `packages/bb_ui` | Buttons, fields, menus, sheets, tooltips, selection, stacks, device lists, pairing and session chrome |
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
      ref: v0.7.0
      path: packages/bb_ui
```

For a tokens-only consumer use the same Git dependency with
`path: packages/bb_tokens`. See [bb_ui](packages/bb_ui/README.md) for theme setup
and [bb_tokens](packages/bb_tokens/README.md) for colour generation.

## Develop

Use Flutter 3.47.5 with Dart 3.13.4, matching CI. From the repository root:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
(cd packages/bb_tokens && flutter test)
(cd packages/bb_ui && flutter test)
(cd apps/gallery && flutter test --exclude-tags golden)
(cd apps/gallery && flutter test --tags golden)
bash scripts/check-raw-colours.sh
bash scripts/check-private-strings.sh --patterns /path/to/private-rules
```

Run the [gallery](apps/gallery/README.md) with `flutter run -d chrome` from
`apps/gallery`. See [verification](docs/verification.md) for CI, initial golden
baseline generation, candidate review and private-string configuration.

## Licence

AGPL-3.0-or-later, as inherited from agent-kit; see [LICENSE](LICENSE). Bundled fonts
retain their SIL Open Font License notices in
[`apps/gallery/assets/fonts/licenses`](apps/gallery/assets/fonts/licenses).
