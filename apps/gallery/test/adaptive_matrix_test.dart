// Every specimen page at every width class and at large text sizes, with no
// overflow and no layout error. Fast: nothing is compared with PNGs.

import 'package:bb_ui_gallery/gallery.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widths from a small phone to a wide desktop window, across both size class
/// boundaries.
const widths = [320.0, 390.0, 600.0, 840.0, 1000.0, 1600.0];

/// System text sizes: default, a common larger setting, and the largest the
/// app follows.
const textScales = [1.0, 1.3, 2.0];

const _height = 2400.0;

void main() {
  for (final scene in GalleryScene.values) {
    for (final width in widths) {
      for (final scale in textScales) {
        testWidgets('${scene.name} at ${width.toInt()} px, text x$scale', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(0, _height) + Offset(width, 0);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          final errors = <String>[];
          final previous = FlutterError.onError;
          FlutterError.onError = (details) {
            final text = details.toString();
            final at = RegExp(r'(lib/[a-z_/]+\.dart:\d+)')
                .firstMatch(text)
                ?.group(1);
            errors.add(
              '${details.exceptionAsString().split('\n').first}'
              '${at == null ? '' : ' at $at'}',
            );
          };
          addTearDown(() => FlutterError.onError = previous);

          await tester.pumpWidget(GalleryApp(scene: scene));
          await tester.pumpAndSettle();
          FlutterError.onError = previous;
          expect(errors, isEmpty, reason: errors.toSet().join('\n'));
        });
      }
    }
  }
}
