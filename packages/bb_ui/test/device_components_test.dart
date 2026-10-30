// The device, notice, toast and session components: taps, callbacks, keys and
// timing. Pixels are covered by the gallery's golden tests.

import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool dark = true,
  Size size = const Size(900, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    AppTheme(
      colors: dark ? AppColors.darkTheme : AppColors.light,
      formFactor: FormFactor.forWidth(size.width),
      child: WidgetsApp(
        color: const Color(0xFF000000),
        builder: (context, _) => Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (_) => Align(alignment: Alignment.topLeft, child: child),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('DeviceRow taps as a row and its trailing action on its own', (
    tester,
  ) async {
    var row = 0, action = 0;
    await _pump(
      tester,
      SizedBox(
        width: 640,
        child: DeviceRow(
          icon: Ico.monitor,
          title: 'Studio PC',
          status: const StatusPill('Online', kind: StatusKind.online),
          id: 'H4PD-R8TN-B7QK-2M9X',
          meta: const ['Last mode Game'],
          selected: true,
          onTap: () => row++,
          trailing: PrimaryButton(
            label: 'Connect',
            height: 34,
            onTap: () => action++,
          ),
        ),
      ),
    );
    expect(find.text('Studio PC'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('H4PD-R8TN-B7QK-2M9X'), findsOneWidget);
    expect(find.text('Last mode Game'), findsOneWidget);
    await tester.tap(find.text('Connect'));
    await tester.pump();
    expect((row, action), (0, 1));
    await tester.tap(find.text('Studio PC'));
    await tester.pump();
    expect((row, action), (1, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('buttons: disabled primary and secondary do not fire', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      Column(
        children: [
          const PrimaryButton(label: 'Primary', onTap: null),
          const SecondaryButton(label: 'Secondary', icon: Ico.refresh),
          SecondaryButton(label: 'Remove', danger: true, onTap: () => taps++),
          TextBtn('Rename', icon: Ico.pencil, onTap: () => taps++),
        ],
      ),
    );
    await tester.tap(find.text('Primary'));
    await tester.tap(find.text('Secondary'));
    await tester.pump();
    expect(taps, 0);
    await tester.tap(find.text('Remove'));
    await tester.tap(find.text('Rename'));
    await tester.pump();
    expect(taps, 2);
  });

  testWidgets('NoticeBanner shows title, message and actions and dismisses', (
    tester,
  ) async {
    var dismissed = 0, retried = 0;
    await _pump(
      tester,
      SizedBox(
        width: 560,
        child: NoticeBanner(
          kind: NoticeKind.danger,
          title: 'The stream did not start',
          message: 'The PC accepted this device, but no video arrived.',
          actions: [
            SecondaryButton(label: 'Try again', onTap: () => retried++),
          ],
          onDismiss: () => dismissed++,
        ),
      ),
    );
    expect(find.text('The stream did not start'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.tap(find.byType(IconBtn));
    await tester.pump();
    expect((retried, dismissed), (1, 1));
  });

  testWidgets('ConfirmBox takes its own cancel label', (tester) async {
    bool? answer;
    await _pump(
      tester,
      SizedBox(
        width: 320,
        child: ConfirmBox(
          title: 'Forget Studio PC?',
          message: 'This device forgets the PC and its key.',
          confirmLabel: 'Forget',
          cancelLabel: 'Keep',
          danger: true,
          onDone: (v) => answer = v,
        ),
      ),
    );
    expect(find.text('Keep'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    await tester.tap(find.text('Keep'));
    expect(answer, isFalse);
    await tester.tap(find.text('Forget'));
    expect(answer, isTrue);
  });

  testWidgets('showToast shows a card, counts down and removes itself', (
    tester,
  ) async {
    late BuildContext inner;
    await _pump(
      tester,
      Builder(
        builder: (context) {
          inner = context;
          return const SizedBox.shrink();
        },
      ),
    );
    showToast(
      inner,
      duration: const Duration(seconds: 2),
      builder: (context, progress) => ToastCard(
        title: 'Mouse and keyboard now go to Studio PC',
        icon: Ico.pointerClick,
        content: const KeyChord(['Ctrl', 'Alt', 'Shift', 'Z']),
        progress: progress,
      ),
    );
    await tester.pump();
    expect(find.text('Mouse and keyboard now go to Studio PC'), findsOneWidget);
    expect(find.text('Shift'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Mouse and keyboard now go to Studio PC'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Mouse and keyboard now go to Studio PC'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('showToast can be dismissed early', (tester) async {
    late BuildContext inner;
    await _pump(
      tester,
      Builder(
        builder: (context) {
          inner = context;
          return const SizedBox.shrink();
        },
      ),
    );
    final handle = showToast(
      inner,
      builder: (context, progress) => const ToastCard(title: 'Released'),
    );
    await tester.pump();
    expect(find.text('Released'), findsOneWidget);
    handle.dismiss();
    handle.dismiss();
    await tester.pump();
    expect(find.text('Released'), findsNothing);
  });

  testWidgets('ComparisonNumber groups the digits', (tester) async {
    await _pump(
      tester,
      const SizedBox(
        width: 480,
        child: ComparisonNumber(
          '482913',
          label: 'Number on this device',
          caption: 'Studio PC',
        ),
      ),
    );
    expect(find.text('482  913'), findsOneWidget);
    expect(find.text('Number on this device'), findsOneWidget);
  });

  testWidgets('CopyableText inline copies its text', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(
      tester,
      const CopyableText('H4PD-R8TN-B7QK-2M9X', inline: true),
    );
    await tester.tap(find.byType(CopyButton));
    await tester.pump();
    expect(copied, 'H4PD-R8TN-B7QK-2M9X');
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('DisplayPicker selects by tap, row and number key', (
    tester,
  ) async {
    const displays = [
      DisplayInfo(
        id: 'a',
        label: 'Display 1 · main',
        width: 2560,
        height: 1440,
        detail: '2560 x 1440',
      ),
      DisplayInfo(
        id: 'b',
        label: 'Display 2',
        width: 1920,
        height: 1080,
        x: 2560,
      ),
      DisplayInfo(
        id: 'c',
        label: 'Display 3',
        width: 1080,
        height: 1920,
        x: -1080,
      ),
    ];
    final picked = <String>[];
    await _pump(
      tester,
      DisplayPicker(
        displays: displays,
        selectedId: 'a',
        subtitle: '3 on Studio PC',
        autofocus: true,
        onSelect: (d) => picked.add(d.id),
      ),
    );
    await tester.pump();
    expect(find.text('Showing'), findsOneWidget);
    await tester.tap(find.text('Display 2'));
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit9);
    await tester.pump();
    expect(picked, ['b', 'c']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('EdgeTab and EdgeStrip buttons report taps', (tester) async {
    var tab = 0, stats = 0;
    await _pump(
      tester,
      Column(
        children: [
          EdgeTab(label: 'Studio PC', value: '12 ms', onTap: () => tab++),
          EdgeStrip(
            groups: [
              EdgeStripButton(
                icon: Ico.activity,
                label: 'Stats',
                onTap: () => stats++,
              ),
              const EdgeStripButton(
                icon: Ico.settings,
                semanticLabel: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
    await tester.tap(find.text('Studio PC'));
    await tester.tap(find.text('Stats'));
    await tester.pump();
    expect((tab, stats), (1, 1));
    expect(find.byType(EdgeStripButton), findsNWidgets(2));
  });
}
