// The token set keeps Scratch's values and the theme lookup works.

import 'package:bb_tokens/bb_tokens.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light and dark palettes differ and say which they are', () {
    expect(AppColors.light.dark, isFalse);
    expect(AppColors.darkTheme.dark, isTrue);
    expect(AppColors.light.bgPrimary, isNot(AppColors.darkTheme.bgPrimary));
  });

  test('the generated palette backs the Scratch names', () {
    expect(AppColors.light.palette, same(ProfileColors.light));
    expect(AppColors.darkTheme.palette, same(ProfileColors.dark));
    expect(AppColors.light.bgPrimary, ProfileColors.light.surface);
    expect(AppColors.light.bgTertiary, ProfileColors.light.desk);
    expect(AppColors.darkTheme.okBg, ProfileColors.dark.constructive);
    expect(AppColors.light.seam, same(ProfileColors.light.shadow));
    // Translucent values stay translucent.
    expect(AppColors.darkTheme.okBg.a, lessThan(1));
    expect(ProfileColors.dark.statusNeedsYouLine.a, lessThan(1));
    expect(ProfileColors.light.paper, kTransparent);
  });

  test('space colours come from the palette', () {
    expect(spaceColor('moss', Brightness.light), const Color(0xFF697A6B));
    expect(spaceColor('moss', Brightness.dark), const Color(0xFF5F7062));
    expect(spaceColor('duvet', Brightness.dark), const Color(0xFF999DA6));
    expect(spaceColor('nope', Brightness.dark), isNull);
  });

  test('the size class follows the width', () {
    expect(SizeClass.forWidth(SizeClass.mediumWidth - 1), SizeClass.compact);
    expect(SizeClass.forWidth(SizeClass.mediumWidth), SizeClass.medium);
    expect(SizeClass.forWidth(SizeClass.expandedWidth), SizeClass.expanded);
    expect(SizeClass.expanded.atLeast(SizeClass.medium), isTrue);
    expect(SizeClass.compact.atLeast(SizeClass.medium), isFalse);
  });

  test('scales only grow', () {
    void ascending(List<double> values) {
      for (var i = 1; i < values.length; i++) {
        expect(values[i], greaterThan(values[i - 1]));
      }
    }

    ascending(Space.steps);
    ascending([for (final s in ControlSize.values) s.height]);
    ascending([for (final s in IconSize.values) s.px]);
    ascending([for (final s in NumeralSize.values) s.spec.size]);
  });

  test('touch targets are large enough to tap', () {
    expect(
      Metrics.touch.target.height,
      greaterThanOrEqualTo(Layout.minTapTarget),
    );
    expect(Metrics.touch.row.height, greaterThanOrEqualTo(Layout.minTapTarget));
    expect(Density.forPlatform(TargetPlatform.iOS), Density.touch);
    expect(Density.forPlatform(TargetPlatform.linux), Density.pointer);
  });

  test('every metric spacing is a step of the scale', () {
    for (final m in [Metrics.pointer, Metrics.touch]) {
      for (final v in [m.iconGap, m.padX, m.insetX]) {
        expect(Space.steps, contains(v));
      }
    }
  });

  test('bundled font families keep Scratch names', () {
    expect(sansFamily, 'Atkinson Hyperlegible Next');
    expect(monoFamily, 'Fragment Mono');
    expect(displayFamily, 'Bricolage Grotesque');
  });

  test('kit tokens match the Scratch-skin theme.css', () {
    const layout = KitLayout.standard;
    expect(layout.fitComposer, 460);
    expect(layout.paneMinWidth, 200);
    expect(layout.paneMinHeight, 120);
    expect(layout.edgeTab, 28);
    expect(KitMotion.standard.breathe, const Duration(milliseconds: 2400));
    expect(KitInks.of(AppColors.light).danger, const Color(0xFFAD4B4B));
    expect(KitInks.of(AppColors.darkTheme).attention, const Color(0xFFF0D29C));
  });

  testWidgets('context reads the nearest AppTheme', (tester) async {
    late TypeScale type;
    late AppColors colors;
    late String picked;
    await tester.pumpWidget(
      AppTheme(
        colors: AppColors.darkTheme,
        density: Density.touch,
        child: SizeClassScope(
          sizeClass: SizeClass.medium,
          child: Builder(
            builder: (context) {
              type = context.type;
              colors = context.colors;
              picked = context.adaptive(compact: 'c', expanded: 'e');
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(colors, same(AppColors.darkTheme));
    expect(type, same(TypeScale.touch));
    expect(picked, 'c');
  });
}
