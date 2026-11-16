// A specimen of the device components over sample data: status pills, device
// rows, the detail panel, code entry and display, notices, the empty state and
// the confirm dialog. No host, relay or network.

import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/widgets.dart';

import 'gallery_tokens.dart';

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
    final compact = context.sizeClass.isCompact;
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('This PC', icon: Ico.radio),
        const Gap(Space.sm),
        DeviceRow(
          icon: Ico.server,
          title: 'DESKTOP-K9TR',
          status: const StatusPill('Hosting', kind: StatusKind.active),
          meta: const ['Pixel 8 connected', 'Admin mode off'],
          trailing: TextBtn('Manage', icon: Ico.settings, onTap: () {}),
        ),
        const Gap(Space.xl),
        SectionHeader(
          'Your PCs',
          subtitle: 'Other PCs paired with this device.',
          trailing: SecondaryButton(
            label: 'Pair a new PC',
            icon: Ico.plus,
            size: ControlSize.xl,
            onTap: () {},
          ),
        ),
        const Gap(Space.md),
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
            size: ControlSize.lg,
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
          trailing: SecondaryButton(
            label: 'Connect',
            size: ControlSize.lg,
            onTap: () {},
          ),
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
          trailing: const SecondaryButton(
            label: 'Connect',
            size: ControlSize.lg,
          ),
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
          size: ControlSize.xxl,
          expand: true,
          onTap: () {},
        ),
        // Both ends of the row when they fit, stacked when the text is large.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          children: [
            TextBtn(
              'Rename',
              icon: Ico.pencil,
              size: ControlSize.lg,
              onTap: () {},
            ),
            TextBtn(
              'Forget',
              icon: Ico.trash,
              size: ControlSize.lg,
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
              constraints: const BoxConstraints(maxWidth: PageWidths.wide),
              child: Padding(
                padding: EdgeInsets.all(compact ? Space.xl : Space.xxxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: Space.xl,
                      runSpacing: Space.md,
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
                          size: ControlSize.xl,
                        ),
                      ],
                    ),
                    const _Section('Device list and detail'),
                    if (compact)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [list, const Gap(Space.xl), detail],
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: Specimen.listFlex, child: list),
                          const Gap(Space.xxl),
                          Expanded(flex: Specimen.detailFlex, child: detail),
                        ],
                      ),
                    const Gap(Space.md),
                    Text(
                      'Confirm answer: $_answer',
                      style: ts(context.type.uiSmall, c.textSecondary),
                    ),
                    const _Section('Status'),
                    const Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.sm,
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
                      spacing: Space.md,
                      runSpacing: Space.md,
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
                      spacing: Space.xl,
                      runSpacing: Space.xl,
                      children: [
                        SizedBox(
                          width: compact ? double.infinity : Specimen.column,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'PC ID',
                                style: ts(context.type.ui, c.textPrimary),
                              ),
                              const Gap(Space.sm),
                              CodeField(
                                fieldKey: const ValueKey('id-field'),
                                controller: _id,
                                groups: _idGroups,
                                placeholder: 'XXXX-XXXX-XXXX-XXXX',
                                semanticLabel: 'PC ID',
                                onChanged: (_) => setState(() {}),
                              ),
                              const Gap(Space.lg),
                              Text(
                                'One-time code',
                                style: ts(context.type.ui, c.textPrimary),
                              ),
                              const Gap(Space.sm),
                              CodeField(
                                fieldKey: const ValueKey('code-field'),
                                controller: _code,
                                groups: _codeGroups,
                                placeholder: 'XXXX-XXXX',
                                semanticLabel: 'One-time code',
                                onChanged: (_) => setState(() {}),
                              ),
                              const Gap(Space.sm),
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
                          width: compact ? double.infinity : Specimen.column,
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OneTimeCode(
                                '7KQ2M9XP',
                                groups: Specimen.codeGroups,
                                label: 'One-time code',
                                caption: 'Works once and expires in 5 minutes.',
                              ),
                              Gap(Space.lg),
                              ComparisonNumber(
                                '482913',
                                label: 'Number on this device',
                                caption: 'Studio PC',
                              ),
                            ],
                          ),
                        ),
                        QrFrame(
                          size: Specimen.qr,
                          caption: 'Scan with the phone camera',
                          // A stand-in for a real code: the glyph scaled up to
                          // fill the frame, with its light stroke.
                          child: FittedBox(
                            child: Icon20(
                              Ico.qrCode,
                              size: IconSize.xxl,
                              stroke: Stroke.hair,
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
                    const Gap(Space.md),
                    const NoticeBanner(
                      kind: NoticeKind.success,
                      title: 'Paired',
                      message: 'Studio PC is in your list.',
                    ),
                    const Gap(Space.md),
                    const NoticeBanner(
                      kind: NoticeKind.attention,
                      title: 'Input to the elevated window is blocked',
                      message:
                          'Video keeps playing. Run the host as administrator '
                          'to send input there.',
                    ),
                    const Gap(Space.md),
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
                            size: ControlSize.lg,
                            onTap: () {},
                          ),
                          SecondaryButton(
                            label: 'Back to your PCs',
                            size: ControlSize.lg,
                            onTap: () {},
                          ),
                        ],
                        onDismiss: () => setState(() => _dismissed = true),
                      ),
                    const _Section('Empty state and confirm'),
                    Wrap(
                      spacing: Space.xxl,
                      runSpacing: Space.xl,
                      children: [
                        SizedBox(
                          width: compact ? double.infinity : Widths.form,
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
                          width: Widths.dialog,
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
    padding: const EdgeInsets.only(top: Space.xxl, bottom: Space.lg),
    child: SettingsHeading(label),
  );
}
