// Messages to the person: an inline notice, an empty state and a toast.

import 'package:flutter/widgets.dart';

import 'buttons.dart';
import 'icons.dart';
import 'tokens.dart';

/// What a [NoticeBanner] says. The icon and the title repeat it, so colour is
/// never the only signal.
enum NoticeKind { info, success, attention, danger }

/// An inline message that stays where the thing it explains is: what
/// happened, what is still true, and the narrowest next step ([actions]).
/// [title] is optional; the message alone is a calm hint.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.message,
    this.title,
    this.kind = NoticeKind.info,
    this.actions = const [],
    this.onDismiss,
  });
  final String message;
  final String? title;
  final NoticeKind kind;
  final List<Widget> actions;

  /// When set, a close button is drawn at the end.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = c.palette;
    final ty = context.type;
    final (Ico icon, Color fill, Color ink, Color line) = switch (kind) {
      NoticeKind.info => (Ico.info, c.bgSecondary, c.iconSecondary, c.border),
      NoticeKind.success => (
        Ico.circleCheck,
        c.okBg,
        p.constructiveInk,
        p.constructiveInk.withValues(alpha: .35),
      ),
      NoticeKind.attention => (
        Ico.triangleAlert,
        c.attnBg,
        p.attentionInk,
        p.attentionInk.withValues(alpha: .35),
      ),
      NoticeKind.danger => (
        Ico.circleAlert,
        c.dangerBg,
        p.dangerInk,
        p.dangerInk.withValues(alpha: .35),
      ),
    };
    return Semantics(
      liveRegion: kind == NoticeKind.danger || kind == NoticeKind.attention,
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: Radii.field,
          border: Border.all(color: line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon20(icon, size: 20, color: ink),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: ts(ty.ui, c.textPrimary, weight: 700),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      message,
                      style: ts(ty.ui, c.textPrimary, weight: 400),
                    ),
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: actions),
                  ],
                ],
              ),
            ),
            if (onDismiss != null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: IconBtn(
                  Ico.close,
                  size: 28,
                  glyph: 16,
                  semanticLabel: 'Dismiss',
                  onTap: onDismiss,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// What a list or screen shows when it has nothing yet: an [icon], a [title]
/// that names the situation, a [message] that says what to do, and at most
/// one [action].
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });
  final Ico icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: c.bgHover,
                  borderRadius: Radii.panel,
                ),
                child: Center(
                  child: Icon20(icon, size: 28, color: c.iconSecondary),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: tsDisplay(ty.h3, c.textPrimary, weight: 700),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: ts(ty.ui, c.textSecondary, weight: 400),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
  }
}

/// A transient card: an optional [icon] tile, a [title], an optional
/// [message] or [content] under it (for example a `KeyChord`) and, while it
/// counts down, a line along the bottom edge that shrinks as [progress] goes
/// from 1 to 0. [showToast] places one on the overlay.
class ToastCard extends StatelessWidget {
  const ToastCard({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.icon,
    this.progress,
    this.width = 420,
  });
  final String title;
  final String? message;
  final Widget? content;
  final Ico? icon;

  /// The time left, 1 down to 0; null draws no line.
  final double? progress;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: c.bgElevated,
          borderRadius: Radii.ctl,
          border: Border.all(color: c.border),
          boxShadow: c.seamHover,
        ),
        child: ClipRRect(
          borderRadius: Radii.ctl,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 16, 14),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c.pawBg,
                          borderRadius: Radii.field,
                        ),
                        child: Center(
                          child: Icon20(icon!, size: 20, color: c.accentText),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: ts(ty.ui, c.textPrimary, weight: 700),
                          ),
                          if (message != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              message!,
                              style: ts(ty.uiSmall, c.textSecondary),
                            ),
                          ],
                          if (content != null) ...[
                            const SizedBox(height: 6),
                            content!,
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (progress != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress!.clamp(0.0, 1.0),
                      child: ColoredBox(
                        color: c.accent,
                        child: const SizedBox(height: 2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hands back a shown toast so the caller can close it early.
class ToastHandle {
  ToastHandle._(this._dismiss);
  final VoidCallback _dismiss;

  /// Removes the toast now. Safe to call after it has gone.
  void dismiss() => _dismiss();
}

/// Shows [builder]'s card on the root overlay for [duration], at the top
/// centre unless [alignment] says otherwise, with a [ToastCard.progress] line
/// when [showProgress] is true and animations are on. One toast at a time per
/// call; the caller decides whether a new one replaces the old.
ToastHandle showToast(
  BuildContext context, {
  required Widget Function(BuildContext context, double? progress) builder,
  Duration duration = const Duration(seconds: 4),
  Alignment alignment = Alignment.topCenter,
  EdgeInsets margin = const EdgeInsets.only(top: 56),
  bool showProgress = true,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final theme = AppTheme.of(context);
  final animate = !MediaQuery.disableAnimationsOf(context);
  late final OverlayEntry entry;
  var gone = false;
  void remove() {
    if (gone) return;
    gone = true;
    entry.remove();
    entry.dispose();
  }

  entry = OverlayEntry(
    builder: (context) => AppTheme(
      colors: theme.colors,
      formFactor: theme.formFactor,
      child: _ToastHost(
        duration: duration,
        alignment: alignment,
        margin: margin,
        showProgress: showProgress && animate,
        onDone: remove,
        builder: builder,
      ),
    ),
  );
  overlay.insert(entry);
  return ToastHandle._(remove);
}

class _ToastHost extends StatefulWidget {
  const _ToastHost({
    required this.duration,
    required this.alignment,
    required this.margin,
    required this.showProgress,
    required this.onDone,
    required this.builder,
  });
  final Duration duration;
  final Alignment alignment;
  final EdgeInsets margin;
  final bool showProgress;
  final VoidCallback onDone;
  final Widget Function(BuildContext context, double? progress) builder;

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: widget.alignment,
    child: Padding(
      padding: widget.margin,
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (context, _) =>
            widget.builder(context, widget.showProgress ? 1 - _ctl.value : null),
      ),
    ),
  );
}
