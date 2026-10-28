// Baselines of the palette specimen, distinct from the primitives. Generate on
// the pinned Linux CI runner, review, then commit the PNGs.

@Tags(['golden'])
library;

import 'package:bb_ui_gallery/gallery.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (width, height) in [(1600, 1600), (390, 2000)]) {
    for (final brightness in Brightness.values) {
      final name = 'palette_${width}_${brightness.name}';
      testWidgets(name, (tester) async {
        tester.view.physicalSize = Size(width.toDouble(), height.toDouble());
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          GalleryApp(
            initialBrightness: brightness,
            scene: GalleryScene.palette,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(WidgetsApp),
          matchesGoldenFile('goldens/$name.png'),
        );
      });
    }
  }
}
