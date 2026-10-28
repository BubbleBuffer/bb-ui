// A specimen of the command palette over sample commands, without a host: the
// panel with groups, shortcuts and a disabled command, the same list filtered
// (matches marked), and a query nothing matches. A button opens the palette
// over the page, as a host would.

import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/widgets.dart';

const _commands = [
  PaletteCommand(id: 'home', title: 'Go home', icon: Ico.home),
  PaletteCommand(
    id: 'page.new',
    title: 'New page',
    group: 'Pages',
    icon: Ico.compose,
    shortcutLabel: 'Ctrl+N',
  ),
  PaletteCommand(
    id: 'page.open',
    title: 'Open page',
    subtitle: 'by title',
    group: 'Pages',
    icon: Ico.page,
  ),
  PaletteCommand(
    id: 'page.copy',
    title: 'Copy link',
    group: 'Pages',
    icon: Ico.link,
    shortcutLabel: 'Ctrl+L',
  ),
  PaletteCommand(
    id: 'page.trash',
    title: 'Move to trash',
    group: 'Pages',
    icon: Ico.trash,
    enabled: false,
    disabledReason: 'No page open',
  ),
  PaletteCommand(
    id: 'view.sidebar',
    title: 'Toggle sidebar',
    group: 'View',
    icon: Ico.sidebar,
    shortcutLabel: r'Ctrl+\',
  ),
  PaletteCommand(
    id: 'view.terminal',
    title: 'Show terminal',
    group: 'View',
    icon: Ico.terminal,
  ),
  PaletteCommand(
    id: 'search',
    title: 'Search',
    group: 'View',
    icon: Ico.search,
    shortcutLabel: 'Ctrl+K',
  ),
];

/// The palette specimen. [onThemeChanged] flips light and dark.
class PaletteGallery extends StatefulWidget {
  const PaletteGallery({super.key, required this.onThemeChanged});

  final VoidCallback onThemeChanged;

  @override
  State<PaletteGallery> createState() => _PaletteGalleryState();
}

class _PaletteGalleryState extends State<PaletteGallery> {
  String _ran = 'Nothing run yet';

  void _run(PaletteCommand command) =>
      setState(() => _ran = 'Ran: ${command.title}');

  Future<void> _open() async {
    final command = await showCommandPalette(context, commands: _commands);
    if (command != null && mounted) _run(command);
  }

  Widget _frame(BuildContext context, Widget palette, {double height = 440}) {
    final c = context.colors;
    // On a phone the palette is flat; the specimen frames it.
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SizedBox(
          height: height,
          child: context.mobile
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: c.borderStrong),
                    borderRadius: Radii.panel,
                  ),
                  child: ClipRRect(borderRadius: Radii.panel, child: palette),
                )
              : Align(alignment: Alignment.topCenter, child: palette),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mobile = context.mobile;
    return ColoredBox(
      color: c.bgPrimary,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Padding(
                padding: EdgeInsets.all(mobile ? 20 : 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Command palette',
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
                    const SizedBox(height: 12),
                    Text(
                      'Type to filter the commands, move with the arrow keys '
                      'and press Enter to run one. Escape closes.',
                      style: ts(context.type.body, c.textSecondary),
                    ),
                    const _Heading('Panel'),
                    _frame(
                      context,
                      CommandPalette(
                        key: const ValueKey('sample-palette'),
                        fieldKey: const ValueKey('sample-field'),
                        commands: _commands,
                        onRun: _run,
                        onClose: () => setState(() => _ran = 'Closed'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _ran,
                      key: const ValueKey('sample-ran'),
                      style: ts(context.type.ui, c.textSecondary),
                    ),
                    const _Heading('Filtered'),
                    _frame(
                      context,
                      CommandPalette(
                        autofocus: false,
                        initialQuery: 'sid',
                        commands: _commands,
                        onRun: _run,
                        onClose: () {},
                      ),
                      height: 160,
                    ),
                    const _Heading('No match'),
                    _frame(
                      context,
                      CommandPalette(
                        autofocus: false,
                        initialQuery: 'zzz',
                        commands: _commands,
                        onRun: _run,
                        onClose: () {},
                      ),
                      height: 120,
                    ),
                    const _Heading('Over the page'),
                    Align(
                      alignment: Alignment.topLeft,
                      child: SecondaryButton(
                        label: 'Open the palette',
                        key: const ValueKey('palette-open'),
                        onTap: _open,
                      ),
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

class _Heading extends StatelessWidget {
  const _Heading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 32, bottom: 16),
    child: SettingsHeading(label),
  );
}
