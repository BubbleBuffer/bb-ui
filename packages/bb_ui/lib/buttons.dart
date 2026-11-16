// Buttons: square icon buttons, the accent button and plain text buttons.

import 'package:flutter/widgets.dart';

import 'hover.dart';
import 'icons.dart';
import 'tokens.dart';
import 'tooltip.dart';
import 'layout.dart';

/// A square icon button: a [size] hit area with a [glyph]-sized icon.
class IconBtn extends StatelessWidget {
  const IconBtn(
    this.icon, {
    super.key,
    this.onTap,
    this.size = ControlSize.sm,
    this.glyph = IconSize.lg,
    this.color,
    this.radius = Radii.md,
    this.selected = false,
    this.width,
    this.semanticLabel,
    this.tooltip,
    this.command,
  });
  final Ico icon;
  final VoidCallback? onTap;
  final ControlSize size;
  final IconSize glyph;
  final double radius;

  /// A wider hit area than [size], for a button with a label beside it.
  final double? width;
  final Color? color;
  final bool selected;
  final String? semanticLabel;

  /// Tooltip text; defaults to [semanticLabel]. Buttons without either
  /// get no tooltip.
  final String? tooltip;

  /// The registered command this button runs; the tooltip shows its shortcut.
  final String? command;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tip = tooltip ?? semanticLabel;
    final button = Semantics(
      button: true,
      label: semanticLabel ?? tooltip ?? icon.name,
      child: Hover(
        onTap: onTap,
        radius: radius,
        selected: selected,
        selectedColor: c.bgPressed,
        child: SizedBox(
          width: width ?? size.height,
          height: size.height,
          child: Center(
            child: Icon20(icon, size: glyph, color: color ?? c.iconSecondary),
          ),
        ),
      ),
    );
    return tip == null
        ? button
        : AppTooltip(label: tip, command: command, child: button);
  }
}

/// The accent-coloured button (for example "New page" on desktop home). A
/// null [onTap] draws it disabled. [expand] fills the available width.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.size = ControlSize.xl,
    this.icon,
    this.expand = false,
  });
  final String label;
  final VoidCallback? onTap;
  final ControlSize size;
  final Ico? icon;
  final bool expand;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onTap != null;
    final ink = enabled ? c.onAccent : c.textDisabled;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Hover(
        onTap: onTap,
        borderRadius: Radii.ctl,
        background: enabled ? c.accent : c.bgTertiary,
        hoverBackground: c.accentHover,
        pressedBackground: c.accentHover,
        padding: const EdgeInsets.symmetric(horizontal: Space.md),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size.height),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon20(icon!, size: IconSize.md, color: ink),
                const Gap(Space.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(context.type.ui, ink, weight: Weight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A sheet-coloured, thread-bordered secondary action. A null [onTap] draws
/// it disabled; [danger] colours the label and border for a destructive step.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.size = ControlSize.xl,
    this.icon,
    this.danger = false,
  });
  final String label;
  final VoidCallback? onTap;
  final ControlSize size;
  final Ico? icon;
  final bool danger;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onTap != null;
    final ink = !enabled
        ? c.textDisabled
        : danger
        ? c.inlineCodeText
        : c.textPrimary;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Hover(
        onTap: onTap,
        background: c.bgPrimary,
        border: Border.all(
          color: danger && enabled
              ? c.inlineCodeText.withValues(alpha: Alpha.muted)
              : c.thread,
        ),
        borderRadius: Radii.ctl,
        padding: const EdgeInsets.symmetric(horizontal: Space.md),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size.height),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon20(icon!, size: IconSize.md, color: ink),
                  const Gap(Space.xs),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts(context.type.ui, ink, weight: Weight.semibold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The shared task box used by Today, the editor and database cells.
class StacksCheckbox extends StatelessWidget {
  const StacksCheckbox({
    super.key,
    required this.checked,
    this.size = Sizes.checkbox,
    this.onChanged,
    this.fill,
    this.ink,
  });
  final bool checked;
  final double size;
  final ValueChanged<bool>? onChanged;
  final Color? fill, ink;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      checked: checked,
      child: Hover(
        onTap: onChanged == null ? null : () => onChanged!(!checked),
        borderRadius: Radii.ctl,
        child: AnimatedContainer(
          duration: Motion.of(context).fast,
          curve: Motion.settle,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: checked ? (fill ?? c.accent) : null,
            borderRadius: Radii.ctl,
            border: Border.all(
              color: checked ? (fill ?? c.accent) : c.threadStrong,
              width: Stroke.regular,
            ),
          ),
          child: checked
              ? Icon20(Ico.check, size: IconSize.sm, color: ink ?? c.onAccent)
              : null,
        ),
      ),
    );
  }
}

/// A text-only button on a hover surface (for example "Share").
class TextBtn extends StatelessWidget {
  const TextBtn(
    this.label, {
    super.key,
    this.onTap,
    this.size = ControlSize.sm,
    this.color,
    this.icon,
  });
  final String label;
  final VoidCallback? onTap;
  final ControlSize size;
  final Color? color;

  /// A leading icon, drawn in the label's colour.
  final Ico? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = color == c.accent ? c.accentText : (color ?? c.textPrimary);
    return Hover(
      radius: Radii.md,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: Space.sm),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: size.height),
        child: Center(
          child: icon == null
              ? Text(label, style: ts(context.type.ui, ink))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon20(icon!, size: IconSize.md, color: ink),
                    const Gap(Space.xs),
                    Text(label, style: ts(context.type.ui, ink)),
                  ],
                ),
        ),
      ),
    );
  }
}
