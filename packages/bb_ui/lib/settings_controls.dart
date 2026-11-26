// Building blocks of the settings screens:
// section titles with a divider, rows with a label, a description and a
// control on the right, a toggle, a select button, a segmented control, a
// bordered text field and a secondary button. Built from the UI kit's tokens
// and parts.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'bb_ui.dart';

/// A section title ("Sync") with a hairline below. A [primary] heading
/// names the whole section; on a compact screen the top bar shows that
/// instead.
class SettingsHeading extends StatelessWidget {
  const SettingsHeading(
    this.text, {
    super.key,
    this.top = 0,
    this.primary = false,
  });
  final String text;
  final double top;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (primary && context.windowSizeClass.isCompact) {
      return const SizedBox(height: Space.xxs);
    }
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            text,
            style: primary
                ? tsDisplay(context.type.h3, c.textPrimary)
                : ts(context.type.body, c.textPrimary, weight: Weight.strong),
          ),
          const Gap(Space.md),
          HLine(color: c.border),
          const Gap(Space.lg),
        ],
      ),
    );
  }
}

/// One setting: label and description on the left, [trailing] on the right.
/// On mobile the trailing control goes below when [stack] is set.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.description,
    this.trailing,
    this.stack = false,
  });
  final String label;
  final String? description;
  final Widget? trailing;
  final bool stack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: ts(ty.item, c.textPrimary, weight: Weight.regular)),
        if (description != null) ...[
          const Gap(Space.hair),
          Text(
            description!,
            style: ts(ty.uiSmall, c.textSecondary, weight: Weight.regular),
          ),
        ],
      ],
    );
    if (trailing == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: text,
      );
    }
    if (stack) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [text, const Gap(Space.md), trailing!],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      // The control keeps its own width at the right edge while the label
      // still fits beside it; on a narrow row or with large text it moves
      // under the label instead of squeezing it or overflowing.
      child: InlineOrStacked(
        main: text,
        trailing: trailing!,
        gap: Space.lg,
        runGap: Space.md,
      ),
    );
  }
}

/// Switch: a 30x18 pill, accent when on.
class Toggle extends StatelessWidget {
  const Toggle({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final off = c.palette.switchOff;
    return Semantics(
      toggled: value,
      button: true,
      child: MouseRegion(
        cursor: onChanged == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: AnimatedContainer(
            duration: Motion.of(context).fast,
            width: Sizes.switchWidth,
            height: Sizes.switchHeight,
            padding: const EdgeInsets.all(Space.hair),
            decoration: BoxDecoration(
              color: value ? c.accent : off,
              borderRadius: BorderRadius.circular(Radii.lg),
            ),
            child: AnimatedAlign(
              duration: Motion.of(context).fast,
              curve: Motion.easing,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: Sizes.switchThumb,
                height: Sizes.switchThumb,
                decoration: BoxDecoration(
                  color: c.palette.knob,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A value with a chevron that opens a menu of [options] (a popover, or a
/// sheet on a compact screen).
class SelectButton<T> extends StatelessWidget {
  const SelectButton({
    super.key,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.title,
  });
  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T>? onChanged;
  final String? title;

  Future<void> _open(BuildContext context) async {
    T? picked;
    // A sheet on a phone-sized window, even from inside a narrow pane or
    // dialog; a popover elsewhere.
    if (context.windowSizeClass.isCompact) {
      picked = await showSheet<T>(
        context,
        (ctx) => SheetSurface(
          children: [
            if (title != null) SheetHeader(title!),
            for (final o in options)
              SheetItem(
                key: ValueKey('option-${labelOf(o)}'),
                label: labelOf(o),
                selected: o == value,
                onTap: () => Navigator.of(ctx).pop(o),
              ),
          ],
        ),
      );
    } else {
      picked = await showPopover<T>(
        context,
        globalRectOf(context),
        (ctx) => MenuList(
          width: Widths.popover,
          children: [
            for (final o in options)
              MenuItem(
                key: ValueKey('option-${labelOf(o)}'),
                label: labelOf(o),
                onTap: () => Navigator.of(ctx).pop(o),
                trailing: o == value
                    ? Icon20(
                        Ico.check,
                        size: IconSize.sm,
                        color: ctx.colors.iconPrimary,
                      )
                    : null,
              ),
          ],
        ),
      );
    }
    if (picked != null && picked != value) onChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      enabled: onChanged != null,
      child: Builder(
        builder: (b) => Hover(
          onTap: onChanged == null ? null : () => _open(b),
          hoverColor: onChanged == null ? kTransparent : null,
          radius: Radii.md,
          padding: const EdgeInsets.fromLTRB(Space.sm, 0, Space.xxs, 0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: ControlSize.sm.height),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    labelOf(value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts(
                      context.type.ui,
                      onChanged == null ? c.textDisabled : c.textSecondary,
                      weight: Weight.regular,
                    ),
                  ),
                ),
                const Gap(Space.hair),
                Icon20(
                  Ico.chevronDown,
                  size: IconSize.xs,
                  color: onChanged == null ? c.textDisabled : c.iconTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One option in a [Segmented] control. At least one of [label] or [icon]
/// must be provided.
class SegmentOption<T> {
  const SegmentOption({
    required this.value,
    this.label,
    this.icon,
    this.tooltip,
    this.semanticLabel,
    this.key,
  }) : assert(label != null || icon != null);

  /// The value represented by this segment.
  final T value;

  /// Optional text label shown inside the segment.
  final String? label;

  /// Optional icon shown before [label], or alone for icon-only segments.
  final Ico? icon;

  /// Optional tooltip shown on hover, focus, or long-press.
  final String? tooltip;

  /// Accessible label for screen readers; defaults to [label], [tooltip], or
  /// the icon name.
  final String? semanticLabel;

  /// Optional key placed on the segment's interactive surface.
  final Key? key;
}

/// A row of mutually exclusive segments, lifted from Scratch's segmented
/// control and styled with `bb_tokens`.
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.expand = false,
  });

  /// Currently selected value.
  final T value;

  /// Ordered options rendered left to right.
  final List<SegmentOption<T>> options;

  /// Called when an unselected segment is activated; null disables all
  /// segments.
  final ValueChanged<T>? onChanged;

  /// When true, segments share the available width equally.
  final bool expand;

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (onChanged == null || options.length < 2) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.arrowLeft &&
        key != LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.ignored;
    }
    final index = options.indexWhere((o) => o.value == value);
    if (index < 0) return KeyEventResult.ignored;
    final next = key == LogicalKeyboardKey.arrowRight
        ? (index + 1) % options.length
        : (index - 1 + options.length) % options.length;
    onChanged!(options[next].value);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onChanged != null;
    final iconSize = context.touch ? IconSize.md : IconSize.sm;
    final padY = context.touch ? Space.sm : Space.xs;

    Widget buildOption(SegmentOption<T> option) {
      final selected = option.value == value;
      final fg = !enabled
          ? c.textDisabled
          : selected
          ? c.textPrimary
          : c.textSecondary;
      final tip = option.tooltip;
      final label =
          option.semanticLabel ?? option.label ?? tip ?? option.icon?.name;
      final textWidget = option.label == null
          ? null
          : Text(
              option.label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ts(
                context.type.uiSmall,
                fg,
                weight: selected ? Weight.strong : Weight.regular,
              ),
            );

      Widget segment = Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        label: label,
        excludeSemantics: true,
        onTap: enabled && !selected ? () => onChanged!(option.value) : null,
        child: Hover(
          key: option.key,
          onTap: enabled && !selected ? () => onChanged!(option.value) : null,
          borderRadius: context.shape.ctl,
          lift: 0,
          background: selected ? c.bgPrimary : null,
          border: selected
              ? Border(
                  bottom: BorderSide(
                    color: enabled ? c.accent : c.borderStrong,
                    width: Stroke.bold,
                  ),
                )
              : null,
          padding: EdgeInsets.symmetric(
            horizontal: option.label == null ? Space.sm : Space.md,
            vertical: padY,
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (option.icon != null)
                Icon20(option.icon!, size: iconSize, color: fg),
              if (option.icon != null && textWidget != null)
                const Gap(Space.xs),
              if (textWidget != null)
                expand ? Flexible(child: textWidget) : textWidget,
            ],
          ),
        ),
      );

      if (tip != null) {
        segment = AppTooltip(label: tip, child: segment);
      }
      return expand ? Expanded(child: segment) : segment;
    }

    return Focus(
      skipTraversal: true,
      onKeyEvent: _handleKey,
      child: Container(
        padding: const EdgeInsets.all(Space.hair),
        decoration: BoxDecoration(
          color: c.bgSecondary,
          borderRadius: context.shape.ctl,
          border: Border.all(color: enabled ? c.borderStrong : c.border),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: [for (final option in options) buildOption(option)],
        ),
      ),
    );
  }
}

/// A bordered single-line text field (light fill, 1 px
/// border, radius 6).
class SettingsField extends StatefulWidget {
  const SettingsField({
    super.key,
    required this.controller,
    this.placeholder = '',
    this.onSubmitted,
    this.onChanged,
    this.mono = false,
    this.fieldKey,
    this.autofocus = false,
  });
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool mono;
  final Key? fieldKey;
  final bool autofocus;

  @override
  State<SettingsField> createState() => _SettingsFieldState();
}

class _SettingsFieldState extends State<SettingsField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    final style = widget.mono
        ? ts(ty.code, c.textPrimary, mono: true)
        : ts(ty.item, c.textPrimary, weight: Weight.regular);
    return GestureDetector(
      onTap: _focus.requestFocus,
      child: FieldFrame(
        height: context.metrics.field.height,
        padding: const EdgeInsets.symmetric(horizontal: Space.md),
        child: PlainField(
          key: widget.fieldKey,
          controller: widget.controller,
          focusNode: _focus,
          style: style,
          placeholder: widget.placeholder,
          onSubmitted: widget.onSubmitted,
          onChanged: widget.onChanged,
          autofocus: widget.autofocus,
          textInputAction: TextInputAction.done,
        ),
      ),
    );
  }
}

/// A secondary button: 1 px border, text in the primary colour.
class OutlineButton extends StatelessWidget {
  const OutlineButton({
    super.key,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.icon,
  });
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = onTap == null
        ? c.textDisabled
        : (danger ? c.inlineCodeText : c.textPrimary);
    return Hover(
      onTap: onTap,
      radius: Radii.md,
      child: Container(
        height: ControlSize.md.height,
        padding: const EdgeInsets.symmetric(horizontal: Space.md),
        decoration: BoxDecoration(
          color: c.bgPrimary,
          borderRadius: context.shape.ctl,
          border: Border.all(
            color: danger
                ? c.inlineCodeText.withValues(alpha: Alpha.muted)
                : c.thread,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const Gap(Space.xs)],
            Text(label, style: ts(context.type.ui, color)),
          ],
        ),
      ),
    );
  }
}

/// Monospace text that can be copied, with a "Copy" button. An [inline] one
/// has no box: the text with a small copy icon after it, for identifiers
/// in running layouts. [type] is the text's role, `context.type.code` when
/// null.
class CopyableText extends StatefulWidget {
  const CopyableText(
    this.text, {
    super.key,
    this.textKey,
    this.inline = false,
    this.type,
    this.color,
  });
  final String text;
  final Key? textKey;
  final bool inline;
  final TypeSpec? type;
  final Color? color;

  @override
  State<CopyableText> createState() => _CopyableTextState();
}

class _CopyableTextState extends State<CopyableText> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(Motion.confirm);
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = ts(
      widget.type ?? context.type.code,
      widget.color ?? c.textPrimary,
      mono: true,
    );
    if (widget.inline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(widget.text, key: widget.textKey, style: style),
          ),
          const Gap(Space.xxs),
          CopyButton(widget.text),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.xs,
        Space.xxs,
        Space.xs,
      ),
      decoration: BoxDecoration(
        color: c.bgSecondary,
        borderRadius: context.shape.field,
        border: Border.all(color: c.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(widget.text, key: widget.textKey, style: style),
          ),
          const Gap(Space.sm),
          TextBtn(
            _copied ? 'Copied' : 'Copy',
            onTap: _copy,
            color: c.textSecondary,
          ),
        ],
      ),
    );
  }
}

/// A small icon button that copies [text] to the clipboard and shows a check
/// for two seconds.
class CopyButton extends StatefulWidget {
  const CopyButton(
    this.text, {
    super.key,
    this.size = ControlSize.xs,
    this.glyph = IconSize.sm,
  });
  final String text;
  final ControlSize size;
  final IconSize glyph;

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(Motion.confirm);
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) => IconBtn(
    _copied ? Ico.check : Ico.copy,
    size: widget.size,
    glyph: widget.glyph,
    semanticLabel: _copied ? 'Copied' : 'Copy',
    onTap: _copy,
  );
}
