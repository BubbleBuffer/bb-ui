// Page routes and scrolling behaviour.

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// A [slide] page (a full-screen page on a phone) slides in from the right.
/// Desktop sheet routes stay transparent and animate their sheet inside the
/// frame so the rail remains fixed. Other pages appear at once.
Route<T> pageRoute<T>(
  WidgetBuilder builder, {
  required bool slide,
  required MotionDurations motion,
  RouteSettings? settings,
  bool desktopSheet = false,
}) => PageRouteBuilder<T>(
  settings: settings,
  opaque: !desktopSheet,
  maintainState: true,
  transitionDuration: slide || desktopSheet ? motion.sheet : Duration.zero,
  reverseTransitionDuration: slide
      ? motion.standard
      : desktopSheet
      ? motion.sheet
      : Duration.zero,
  pageBuilder: (c, a, b) => builder(c),
  transitionsBuilder: (c, a, b, child) {
    if ((!slide && !desktopSheet) || MediaQuery.disableAnimationsOf(c)) {
      return child;
    }
    if (!slide) return child; // The desktop frame moves only the sheet, leaving the rail fixed.
    final t = CurvedAnimation(parent: a, curve: Motion.easing);
    return SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(t),
      child: slide
          ? DecoratedBox(
              decoration: BoxDecoration(boxShadow: c.colors.stack),
              child: child,
            )
          : child,
    );
  },
);

/// No glow or stretch overscroll; a thin scrollbar on desktop.
class AppScrollBehavior extends ScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
  };

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (context.touch ||
        details.direction == AxisDirection.left ||
        details.direction == AxisDirection.right) {
      return child;
    }
    final c = context.colors;
    return RawScrollbar(
      controller: details.controller,
      thumbColor: c.palette.thumb,
      thickness: Stroke.seam,
      radius: const Radius.circular(Radii.sm),
      crossAxisMargin: Space.hair,
      child: child,
    );
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}
