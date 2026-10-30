// Baselines of the session specimen, distinct from the other pages. Generate
// on the pinned Linux CI runner, review, then commit the PNGs.

@Tags(['golden'])
library;

import 'package:bb_ui_gallery/gallery.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (width, height) in [(1000, 1700), (390, 2400)]) {
    for (final brightness in Brightness.values) {
      final name = 'session_${width}_${brightness.name}';
      testWidgets(name, (tester) async {
        tester.view.physicalSize = Size(width.toDouble(), height.toDouble());
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          GalleryApp(initialBrightness: brightness, scene: GalleryScene.session),
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
