# UI primitives gallery

A small, standalone Flutter app for `bb_ui`: buttons (including a disabled
example), a live text field, checkbox selection, reference chips, a foldable
stack and semantic colour swatches. It has no agent, host process or network
dependency. Switch between light and dark at the top; the layout reflows at
compact widths and scrolls in short windows.

```sh
# From the repository root:
flutter pub get
cd apps/gallery
flutter run -d chrome
flutter test --exclude-tags golden
```

The checked-in web runner is ready for `flutter build web`. To add a local
desktop runner, run `flutter create --platforms=linux --project-name bb_ui_gallery .`
here (or choose the target OS), then `flutter run -d linux`.

Golden tests render four new `primitives_*.png` specimens at 1000 and 390 logical
pixels, light and dark, with bundled fonts and device pixel ratio 1. The tall
test windows capture the complete specimen sheet. These are new baselines;
the old agent-scene references belong to agent-kit. Missing baselines fail the
normal comparison job. Generate candidates on GitHub's pinned Linux runner
and review them using [the verification guide](../../docs/verification.md).
