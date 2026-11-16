// DpadFocus and DpadScope: arrows move focus, the ring follows primary focus
// only, Enter activates, Escape calls onBack and autofocus picks the start.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bb_ui/bb_ui.dart';

Widget _button(String key, List<String> log, {bool autofocus = false}) =>
    DpadFocus(
      key: ValueKey(key),
      autofocus: autofocus,
      onActivate: () => log.add(key),
      child: const SizedBox(width: 60, height: 40),
    );

Future<void> _pump(WidgetTester tester, List<String> log, Axis axis) async {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: AppTheme(
        colors: AppColors.light,
        formFactor: FormFactor.desktop,
        child: DpadScope(
          onBack: () => log.add('back'),
          child: Center(
            child: Flex(
              direction: axis,
              mainAxisSize: MainAxisSize.min,
              children: [
                _button('a', log),
                const SizedBox(width: 24, height: 24),
                _button('b', log, autofocus: true),
                const SizedBox(width: 24, height: 24),
                _button('c', log),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Whether the button's own paint layer carries the focus ring.
bool _ringed(String key) => find
    .descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byWidgetPredicate(
        (w) => w is CustomPaint && w.foregroundPainter != null,
      ),
    )
    .evaluate()
    .isNotEmpty;

void main() {
  for (final axis in Axis.values) {
    testWidgets('arrows, OK and Back drive a ${axis.name} of buttons', (
      tester,
    ) async {
      final log = <String>[];
      await _pump(tester, log, axis);
      final next = axis == Axis.horizontal
          ? LogicalKeyboardKey.arrowRight
          : LogicalKeyboardKey.arrowDown;
      final prev = axis == Axis.horizontal
          ? LogicalKeyboardKey.arrowLeft
          : LogicalKeyboardKey.arrowUp;

      // Autofocus decides the start; the ring is on that button only.
      expect(_ringed('b'), isTrue);
      expect(_ringed('a'), isFalse);
      expect(_ringed('c'), isFalse);

      await tester.sendKeyEvent(next);
      await tester.pump();
      expect(_ringed('c'), isTrue);
      expect(_ringed('b'), isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(prev);
      await tester.sendKeyEvent(prev);
      await tester.pump();
      expect(_ringed('a'), isTrue);
      expect(_ringed('c'), isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(log, ['c', 'a', 'back']);
    });
  }
}
