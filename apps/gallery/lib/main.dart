import 'package:flutter/widgets.dart';

import 'gallery.dart';

/// `flutter run --dart-define=SCENE=search` opens the search specimen, and
/// `SCENE=palette` the command palette's.
const _scene = String.fromEnvironment('SCENE');

void main() => runApp(
  GalleryApp(
    scene: switch (_scene) {
      'search' => GalleryScene.search,
      'palette' => GalleryScene.palette,
      _ => GalleryScene.primitives,
    },
  ),
);
