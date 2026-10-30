// A specimen of the session chrome over an empty stage: the edge tab and strip,
// the display picker, the metrics panel, toasts and keycaps. No stream.

import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/widgets.dart';

const _displays = [
  DisplayInfo(
    id: '1',
    label: 'Display 1 · main',
    width: 2560,
    height: 1440,
    detail: '2560 x 1440 · 144 Hz',
  ),
  DisplayInfo(
    id: '2',
    label: 'Display 2',
    width: 1920,
    height: 1080,
    x: 2560,
    detail: '1920 x 1080 · 60 Hz',
  ),
  DisplayInfo(
    id: '3',
    label: 'Display 3',
    width: 1080,
    height: 1920,
    x: -1080,
    detail: '1080 x 1920 · 60 Hz',
  ),
];

const _trend = [
  16.8, 16.7, 16.9, 16.6, 16.7, 17.4, 16.8, 16.7, 20.9, 16.9, 16.7, 16.6, //
  16.8, 16.7, 16.9, 16.7, 16.8, 16.6, 16.7, 16.8,
];

class SessionGallery extends StatefulWidget {
  const SessionGallery({super.key, required this.onThemeChanged});

  final VoidCallback onThemeChanged;

  @override
  State<SessionGallery> createState() => _SessionGalleryState();
}

class _SessionGalleryState extends State<SessionGallery> {
  String _display = '1';
  bool _stats = true;
  bool _open = false;
  int _toasts = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final compact = context.mobile;
    final strip = EdgeStrip(
      groups: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: c.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Studio PC',
                style: ts(context.type.uiSmall, c.textPrimary, weight: 700),
              ),
              const SizedBox(width: 8),
              Text(
                '12 ms',
                style: ts(
                  const TypeSpec(11, 14, 400),
                  c.textPrimary,
                  mono: true,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EdgeStripButton(
              icon: Ico.pointer,
              label: 'Captured',
              signal: true,
            ),
            const SizedBox(width: 6),
            const KeyChord(['Ctrl', 'Alt', 'Shift', 'Z']),
            const SizedBox(width: 6),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EdgeStripButton(
              icon: Ico.monitor,
              label: 'Display $_display',
              menu: true,
              selected: _open,
              onTap: () => setState(() => _open = !_open),
            ),
            const EdgeStripButton(icon: Ico.gamepad, label: 'Game', menu: true),
            const EdgeStripButton(icon: Ico.gauge, label: 'Auto', menu: true),
            const EdgeStripButton(icon: Ico.volume, semanticLabel: 'Audio'),
            EdgeStripButton(
              icon: Ico.activity,
              label: 'Stats',
              selected: _stats,
              onTap: () => setState(() => _stats = !_stats),
            ),
            const EdgeStripButton(
              icon: Ico.settings,
              semanticLabel: 'Settings',
            ),
          ],
        ),
        const EdgeStripButton(icon: Ico.logOut, label: 'Leave'),
      ],
    );
    return ColoredBox(
      color: c.bgPrimary,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Padding(
                padding: EdgeInsets.all(compact ? 20 : 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Session chrome',
                          style: tsDisplay(context.type.h1, c.textPrimary),
                        ),
                        TextBtn(
                          c.dark ? 'Use light theme' : 'Use dark theme',
                          key: const ValueKey('theme-toggle'),
                          onTap: widget.onThemeChanged,
                          height: 44,
                        ),
                      ],
                    ),
                    const _Section('Resting tab and open strip'),
                    _Stage(
                      height: 140,
                      child: Column(
                        children: [
                          EdgeTab(
                            label: 'Studio PC',
                            value: '12 ms',
                            mark: c.accent,
                          ),
                          const SizedBox(height: 28),
                          if (compact)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: strip,
                            )
                          else
                            FittedBox(fit: BoxFit.scaleDown, child: strip),
                        ],
                      ),
                    ),
                    const _Section('Display picker'),
                    Wrap(
                      spacing: 24,
                      runSpacing: 16,
                      children: [
                        DisplayPicker(
                          displays: _displays,
                          selectedId: _display,
                          subtitle: '3 on Studio PC',
                          width: compact ? 350 : 340,
                          onSelect: (d) => setState(() => _display = d.id),
                          footer: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Follow active window',
                                  style: ts(
                                    context.type.ui,
                                    c.textPrimary,
                                    weight: 700,
                                  ),
                                ),
                              ),
                              Text(
                                'Host supports it',
                                style: ts(
                                  context.type.uiSmall,
                                  c.textTertiary,
                                  weight: 400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Showing display $_display',
                          style: ts(context.type.ui, c.textSecondary),
                        ),
                      ],
                    ),
                    const _Section('Metrics panel'),
                    const MetricsPanel(
                      title: 'Stream',
                      hint: 'Ctrl+Alt+Shift+S',
                      trend: _trend,
                      trendCaption: 'frame time, last 4 s',
                      trendValue: '16.7 ms line',
                      metrics: [
                        Metric('round trip', '12 ms'),
                        Metric('decode', '2.1 ms'),
                        Metric('frames', '143.8 fps'),
                        Metric('dropped', '3 (0.1%)'),
                        Metric('bitrate', '38.2 Mb/s'),
                        Metric('packet loss', '0.0%'),
                        Metric('resolution', '2560 x 1440'),
                      ],
                    ),
                    const _Section('Toasts and keycaps'),
                    Wrap(
                      spacing: 24,
                      runSpacing: 16,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: [
                        ToastCard(
                          title: 'Mouse and keyboard now go to Studio PC',
                          icon: Ico.pointerClick,
                          content: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 4,
                            children: [
                              Text(
                                'Release with ',
                                style: ts(
                                  context.type.uiSmall,
                                  c.textSecondary,
                                ),
                              ),
                              const KeyChord(['Ctrl', 'Alt', 'Shift', 'Z']),
                            ],
                          ),
                          progress: .6,
                          width: 440,
                        ),
                        const ToastCard(
                          title: 'Input released',
                          message: 'One click on the stream captures again.',
                          icon: Ico.pointer,
                          width: 440,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SecondaryButton(
                          label: 'Show a toast',
                          height: 40,
                          onTap: () {
                            setState(() => _toasts++);
                            showToast(
                              context,
                              duration: const Duration(seconds: 4),
                              builder: (context, progress) => ToastCard(
                                title: 'Toast $_toasts',
                                message: 'Closes by itself after four seconds.',
                                icon: Ico.info,
                                progress: progress,
                                width: 360,
                              ),
                            );
                          },
                        ),
                        Text(
                          'Toasts shown: $_toasts',
                          style: ts(context.type.ui, c.textSecondary),
                        ),
                        const KeyChord(['Ctrl', 'Alt', 'Shift', 'Q']),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A calm area standing in for the content the chrome sits over.
class _Stage extends StatelessWidget {
  const _Stage({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.bgTertiary,
        borderRadius: Radii.field,
        border: Border.all(color: c.borderSubtle),
      ),
      child: Align(alignment: Alignment.topCenter, child: child),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 32, bottom: 16),
    child: SettingsHeading(label),
  );
}
