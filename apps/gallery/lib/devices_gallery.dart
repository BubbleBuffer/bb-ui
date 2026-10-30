// A specimen of the device components over sample data: status pills, device
// rows, the detail panel, code entry and display, notices, the empty state and
// the confirm dialog. No host, relay or network.

import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/widgets.dart';

class DevicesGallery extends StatefulWidget {
  const DevicesGallery({super.key, required this.onThemeChanged});

  final VoidCallback onThemeChanged;

  @override
  State<DevicesGallery> createState() => _DevicesGalleryState();
}

class _DevicesGalleryState extends State<DevicesGallery> {
  static const _idGroups = [4, 4, 4, 4];
  static const _codeGroups = [4, 4];

  final _id = TextEditingController();
  final _code = TextEditingController();
  String _selected = 'studio';
  String _answer = 'No answer yet';
  bool _dismissed = false;

  @override
  void dispose() {
    _id.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final yes = await showConfirm(
      context,
      title: 'Forget Studio PC?',
      message: 'This device forgets the PC and its key.',
      confirmLabel: 'Forget',
      cancelLabel: 'Keep',
      danger: true,
    );
    if (mounted) setState(() => _answer = yes ? 'Forgotten' : 'Kept');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final compact = context.mobile;
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('This PC', icon: Ico.radio),
        const SizedBox(height: 8),
        DeviceRow(
          icon: Ico.server,
          title: 'DESKTOP-K9TR',
          status: const StatusPill('Hosting', kind: StatusKind.active),
          meta: const ['Pixel 8 connected', 'Admin mode off'],
          trailing: TextBtn('Manage', icon: Ico.settings, onTap: () {}),
        ),
        const SizedBox(height: 20),
        SectionHeader(
          'Your PCs',
          subtitle: 'Other PCs paired with this device.',
          trailing: SecondaryButton(
            label: 'Pair a new PC',
            icon: Ico.plus,
            height: 40,
            onTap: () {},
          ),
        ),
        const SizedBox(height: 12),
        DeviceRow(
          key: const ValueKey('row-studio'),
          icon: Ico.monitor,
          title: 'Studio PC',
          status: const StatusPill('Online', kind: StatusKind.online),
          id: 'H4PD-R8TN-B7QK-2M9X',
          meta: const ['Last mode Game'],
          selected: _selected == 'studio',
          onTap: () => setState(() => _selected = 'studio'),
          trailing: PrimaryButton(
            label: 'Connect',
            icon: Ico.monitorPlay,
            height: 36,
            onTap: () {},
          ),
        ),
        DeviceRow(
          key: const ValueKey('row-living'),
          icon: Ico.laptop,
          title: 'Living room',
          status: const StatusPill('Online', kind: StatusKind.online),
          id: 'Q2WF-7KXM-JD3R-5PNA',
          meta: const ['Last mode Work'],
          selected: _selected == 'living',
          onTap: () => setState(() => _selected = 'living'),
          trailing: SecondaryButton(label: 'Connect', height: 36, onTap: () {}),
        ),
        DeviceRow(
          key: const ValueKey('row-office'),
          icon: Ico.monitor,
          title: 'Office tower',
          status: const StatusPill('Offline', kind: StatusKind.offline),
          id: 'Z8TC-1VEH-QBWD-4LSK',
          meta: const ['Last seen 2 Oct'],
          selected: _selected == 'office',
          onTap: () => setState(() => _selected = 'office'),
          trailing: const SecondaryButton(label: 'Connect', height: 36),
        ),
      ],
    );
    final detail = DetailPanel(
      eyebrow: 'Selected',
      title: switch (_selected) {
        'living' => 'Living room',
        'office' => 'Office tower',
        _ => 'Studio PC',
      },
      id: switch (_selected) {
        'living' => 'Q2WF-7KXM-JD3R-5PNA',
        'office' => 'Z8TC-1VEH-QBWD-4LSK',
        _ => 'H4PD-R8TN-B7QK-2M9X',
      },
      rows: const [
        KeyValueRow('Relay', 'play.example.net', mono: true),
        KeyValueRow('Allowed', 'View and input'),
        KeyValueRow('Last session', 'Today 09:12, Game mode'),
      ],
      actions: [
        PrimaryButton(
          label: 'Connect to Studio PC',
          icon: Ico.monitorPlay,
          height: 46,
          expand: true,
          onTap: () {},
        ),
        Row(
          children: [
            TextBtn('Rename', icon: Ico.pencil, height: 36, onTap: () {}),
            const Spacer(),
            TextBtn(
              'Forget',
              icon: Ico.trash,
              height: 36,
              color: c.inlineCodeText,
              onTap: _confirm,
            ),
          ],
        ),
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
                          'Devices and pairing',
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
                    const _Section('Device list and detail'),
                    if (compact)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [list, const SizedBox(height: 24), detail],
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: list),
                          const SizedBox(width: 32),
                          Expanded(flex: 2, child: detail),
                        ],
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'Confirm answer: $_answer',
                      style: ts(context.type.uiSmall, c.textSecondary),
                    ),
                    const _Section('Status'),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusPill('Online', kind: StatusKind.online),
                        StatusPill('Offline', kind: StatusKind.offline),
                        StatusPill('Hosting', kind: StatusKind.active),
                        StatusPill('1 request', kind: StatusKind.attention),
                        StatusPill('Refused', kind: StatusKind.danger),
                        StatusPill('Draft'),
                      ],
                    ),
                    const _Section('Buttons'),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PrimaryButton(
                          label: 'Connect',
                          icon: Ico.monitorPlay,
                          onTap: () {},
                        ),
                        const PrimaryButton(label: 'Connect', onTap: null),
                        SecondaryButton(
                          label: 'Try again',
                          icon: Ico.refresh,
                          onTap: () {},
                        ),
                        SecondaryButton(
                          label: 'Remove',
                          icon: Ico.trash,
                          danger: true,
                          onTap: () {},
                        ),
                        const SecondaryButton(label: 'Unavailable'),
                        TextBtn('Back to your PCs', onTap: () {}),
                      ],
                    ),
                    const _Section('Code entry and display'),
                    Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: [
                        SizedBox(
                          width: compact ? double.infinity : 400,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'PC ID',
                                style: ts(context.type.ui, c.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              CodeField(
                                fieldKey: const ValueKey('id-field'),
                                controller: _id,
                                groups: _idGroups,
                                placeholder: 'XXXX-XXXX-XXXX-XXXX',
                                semanticLabel: 'PC ID',
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'One-time code',
                                style: ts(context.type.ui, c.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              CodeField(
                                fieldKey: const ValueKey('code-field'),
                                controller: _code,
                                groups: _codeGroups,
                                placeholder: 'XXXX-XXXX',
                                semanticLabel: 'One-time code',
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Typed: ${codeCharacters(_id.text, _idGroups).length} '
                                'of 16 and '
                                '${codeCharacters(_code.text, _codeGroups).length} of 8',
                                style: ts(
                                  context.type.uiSmall,
                                  c.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: compact ? double.infinity : 400,
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OneTimeCode(
                                '7KQ2M9XP',
                                groups: [4, 4],
                                label: 'One-time code',
                                caption: 'Works once and expires in 5 minutes.',
                              ),
                              SizedBox(height: 16),
                              ComparisonNumber(
                                '482913',
                                label: 'Number on this device',
                                caption: 'Studio PC',
                              ),
                            ],
                          ),
                        ),
                        QrFrame(
                          size: 168,
                          caption: 'Scan with the phone camera',
                          child: Center(
                            child: Icon20(
                              Ico.qrCode,
                              size: 120,
                              stroke: 2,
                              color: QrFrame.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const _Section('Notices'),
                    const NoticeBanner(
                      message:
                          'If the PC is asleep or its display is off, it may '
                          'not send video. Wake it, then try again.',
                    ),
                    const SizedBox(height: 12),
                    const NoticeBanner(
                      kind: NoticeKind.success,
                      title: 'Paired',
                      message: 'Studio PC is in your list.',
                    ),
                    const SizedBox(height: 12),
                    const NoticeBanner(
                      kind: NoticeKind.attention,
                      title: 'Input to the elevated window is blocked',
                      message:
                          'Video keeps playing. Run the host as administrator '
                          'to send input there.',
                    ),
                    const SizedBox(height: 12),
                    if (!_dismissed)
                      NoticeBanner(
                        kind: NoticeKind.danger,
                        title: "The stream didn't start",
                        message:
                            'Studio PC accepted this device, but no video '
                            'arrived within 8 seconds.',
                        actions: [
                          PrimaryButton(
                            label: 'Try again',
                            icon: Ico.refresh,
                            height: 36,
                            onTap: () {},
                          ),
                          SecondaryButton(
                            label: 'Back to your PCs',
                            height: 36,
                            onTap: () {},
                          ),
                        ],
                        onDismiss: () => setState(() => _dismissed = true),
                      ),
                    const _Section('Empty state and confirm'),
                    Wrap(
                      spacing: 32,
                      runSpacing: 24,
                      children: [
                        SizedBox(
                          width: compact ? double.infinity : 420,
                          child: EmptyState(
                            icon: Ico.monitor,
                            title: 'No PCs yet',
                            message:
                                'Open the pairing screen on the PC, then '
                                'enter its ID and code here.',
                            action: PrimaryButton(
                              label: 'Pair a PC',
                              icon: Ico.plus,
                              onTap: () {},
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 320,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: c.bgElevated,
                              borderRadius: Radii.panel,
                              border: Border.all(color: c.border),
                            ),
                            child: ConfirmBox(
                              title: 'Remove this PC?',
                              message:
                                  'This device forgets Office PC and its key. '
                                  'To use it again, pair at the PC.',
                              confirmLabel: 'Remove',
                              danger: true,
                              onDone: (_) {},
                            ),
                          ),
                        ),
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

class _Section extends StatelessWidget {
  const _Section(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 32, bottom: 16),
    child: SettingsHeading(label),
  );
}
