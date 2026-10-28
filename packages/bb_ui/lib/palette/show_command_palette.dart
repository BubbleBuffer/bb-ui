// Shows the command palette over the page: a panel near the top on a wide
// window, the full screen on a phone. The returned future completes with the
// command the user ran, or null when they closed it, only after the palette
// is gone and focus is back where it was, so a host that runs the command
// then is not overtaken by the restore.

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../tokens.dart';
import 'command_palette.dart';
import 'palette_command.dart';

/// Opens the palette on [context]'s navigator. Focus returns to what had it
/// before, unless that is gone or no longer wants focus.
Future<PaletteCommand?> showCommandPalette(
  BuildContext context, {
  required List<PaletteCommand> commands,
  String initialQuery = '',
  String placeholder = 'Search commands…',
  String emptyNote = 'No matching commands',
}) {
  final route = CommandPaletteRoute(
    commands: commands,
    initialQuery: initialQuery,
    placeholder: placeholder,
    emptyNote: emptyNote,
    barrier: context.colors.overlay,
    duration: Motion.of(context).fast,
    restoreFocus: FocusManager.instance.primaryFocus,
  );
  Navigator.of(context).push<PaletteCommand>(route);
  return route.done;
}

class CommandPaletteRoute extends PopupRoute<PaletteCommand> {
  CommandPaletteRoute({
    required this.commands,
    required this.initialQuery,
    required this.placeholder,
    required this.emptyNote,
    required this.barrier,
    required this.duration,
    this.restoreFocus,
  });
  final List<PaletteCommand> commands;
  final String initialQuery, placeholder, emptyNote;
  final Color barrier;
  final Duration duration;
  final FocusNode? restoreFocus;

  final _done = Completer<PaletteCommand?>();
  PaletteCommand? _ran;

  /// Completes when the route is gone and focus is restored.
  Future<PaletteCommand?> get done => _done.future;

  @override
  Color? get barrierColor => barrier;
  @override
  bool get barrierDismissible => true;
  @override
  String? get barrierLabel => 'Close';
  @override
  Duration get transitionDuration => duration;

  @override
  bool didPop(PaletteCommand? result) {
    _ran ??= result;
    return super.didPop(result);
  }

  @override
  void dispose() {
    super.dispose();
    final focus = restoreFocus;
    // After the next frame the palette's field is out of the tree.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (focus != null && focus.context != null && focus.canRequestFocus) {
        focus.requestFocus();
      }
      if (!_done.isCompleted) _done.complete(_ran);
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final size = MediaQuery.sizeOf(context);
    final palette = CommandPalette(
      commands: commands,
      initialQuery: initialQuery,
      placeholder: placeholder,
      emptyNote: emptyNote,
      onRun: (command) => Navigator.of(context).pop(command),
      onClose: () => Navigator.of(context).maybePop(),
    );
    if (context.mobile) return palette;
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, size.height * 0.14, 16, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: size.height * 0.6,
          ),
          child: palette,
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MediaQuery.disableAnimationsOf(context)
      ? child
      : FadeTransition(opacity: animation, child: child);
}
