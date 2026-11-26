import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/widgets.dart';

import 'gallery.dart';

/// `flutter run --dart-define=SCENE=search` opens the search specimen,
/// `SCENE=palette` the command palette's, `SCENE=devices` the device and
/// pairing components, `SCENE=session` the session chrome and `SCENE=editor`
/// the editor controls. `--dart-define=PROFILE=pawth` draws any scene in the
/// `pawth` product profile.
const _scene = String.fromEnvironment('SCENE');
const _profile = String.fromEnvironment('PROFILE');

void main() => runApp(
  GalleryApp(
    profile: _profile == 'pawth' ? ThemeProfile.pawth : null,
    scene: switch (_scene) {
      'search' => GalleryScene.search,
      'palette' => GalleryScene.palette,
      'devices' => GalleryScene.devices,
      'session' => GalleryScene.session,
      'editor' => GalleryScene.editor,
      _ => GalleryScene.primitives,
    },
  ),
);
