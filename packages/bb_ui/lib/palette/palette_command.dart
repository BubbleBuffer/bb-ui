// The neutral view model of the command palette: one command as the list
// draws it. A host maps its own commands onto it; nothing here knows what a
// command does, who may run it or which keys trigger it.

import 'package:flutter/widgets.dart';

import '../icons.dart';

@immutable
class PaletteCommand {
  const PaletteCommand({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.group,
    this.shortcutLabel,
    this.enabled = true,
    this.disabledReason,
    this.icon,
    this.rowKey,
  });

  /// Unique among the commands shown; the palette reports the picked one.
  final String id;
  final String title;

  /// Muted text after the title (a path, a hint). Filtering reads it too.
  final String subtitle;

  /// The group label above the command's run of rows, or null for the
  /// ungrouped rows that come first.
  final String? group;

  /// The host's own text for the keys that run the command ("Ctrl+N"). The
  /// palette only shows it.
  final String? shortcutLabel;

  /// A disabled command is listed and can be selected, but never runs.
  final bool enabled;

  /// Why a disabled command cannot run; shown at the end of its row in place
  /// of the shortcut.
  final String? disabledReason;

  /// The row's icon, from bb_ui's own icon set.
  final Ico? icon;

  /// The key of the row, so a host's tests and tools can find it.
  final Key? rowKey;
}
