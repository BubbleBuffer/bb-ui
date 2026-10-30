import 'package:flutter/widgets.dart';

import 'gallery.dart';

/// `flutter run --dart-define=SCENE=search` opens the search specimen,
/// `SCENE=palette` the command palette's, `SCENE=devices` the device and
/// pairing components and `SCENE=session` the session chrome.
const _scene = String.fromEnvironment('SCENE');

void main() => runApp(
  GalleryApp(
    scene: switch (_scene) {
      'search' => GalleryScene.search,
      'palette' => GalleryScene.palette,
      'devices' => GalleryScene.devices,
      'session' => GalleryScene.session,
      _ => GalleryScene.primitives,
    },
  ),
);
