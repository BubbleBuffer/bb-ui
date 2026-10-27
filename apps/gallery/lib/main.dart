import 'package:flutter/widgets.dart';

import 'gallery.dart';

/// `flutter run --dart-define=SCENE=search` opens the search specimen.
const _scene = String.fromEnvironment('SCENE');

void main() => runApp(
  GalleryApp(
    scene: _scene == 'search' ? GalleryScene.search : GalleryScene.primitives,
  ),
);
