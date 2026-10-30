// Choosing one of several screens: a to-scale map of how they sit, and a list.

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../hover.dart';
import '../icons.dart';
import '../keycap.dart';
import '../tokens.dart';

/// One screen of a machine, in its own pixel coordinates: where its top-left
/// corner sits ([x], [y]) and how big it is ([width], [height]).
class DisplayInfo {
  const DisplayInfo({
    required this.id,
    required this.label,
    required this.width,
    required this.height,
    this.x = 0,
    this.y = 0,
    this.detail,
  });
  final String id;

  /// The name in the list ("Display 1 · main").
  final String label;
  final int width, height, x, y;

  /// What the list shows at the end of the row ("2560 x 1440 · 144 Hz").
  final String? detail;
}

const _digitKeys = [
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
  LogicalKeyboardKey.digit7,
  LogicalKeyboardKey.digit8,
  LogicalKeyboardKey.digit9,
];

/// A map and a list of [displays], with [selectedId] marked as the one being
/// shown. The map is drawn to scale from the displays' positions; tiles and
/// rows are numbered from 1 in list order, and the number keys 1 to 9 pick the
/// display with that number while the picker has focus.
class DisplayPicker extends StatelessWidget {
  const DisplayPicker({
    super.key,
    required this.displays,
    required this.selectedId,
    required this.onSelect,
    this.title = 'Show display',
    this.subtitle,
    this.shownLabel = 'Showing',
    this.footer,
    this.width = 340,
    this.autofocus = false,
  });
  final List<DisplayInfo> displays;
  final String selectedId;
  final ValueChanged<DisplayInfo> onSelect;
  final String title;

  /// The summary at the end of the title ("3 on Studio PC").
  final String? subtitle;

  /// The word on the selected tile, so the choice never rests on colour alone.
  final String shownLabel;

  /// A row under the list, for example a toggle.
  final Widget? footer;
  final double width;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    return Focus(
      autofocus: autofocus,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final at = _digitKeys.indexOf(event.logicalKey);
        if (at < 0 || at >= displays.length) return KeyEventResult.ignored;
        onSelect(displays[at]);
        return KeyEventResult.handled;
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.bgElevated,
          borderRadius: Radii.panel,
          border: Border.all(color: c.border),
          boxShadow: c.seamHover,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: ts(ty.uiSmall, c.textSecondary, weight: 600),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: ts(
                      const TypeSpec(11, 15, 400),
                      c.textTertiary,
                      mono: true,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _Map(
              displays: displays,
              selectedId: selectedId,
              shownLabel: shownLabel,
              onSelect: onSelect,
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < displays.length; i++)
              _Row(
                number: i + 1,
                display: displays[i],
                selected: displays[i].id == selectedId,
                onTap: () => onSelect(displays[i]),
              ),
            if (footer != null) ...[
              const SizedBox(height: 6),
              Container(height: 1, color: c.border),
              const SizedBox(height: 6),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class _Map extends StatelessWidget {
  const _Map({
    required this.displays,
    required this.selectedId,
    required this.shownLabel,
    required this.onSelect,
  });
  final List<DisplayInfo> displays;
  final String selectedId;
  final String shownLabel;
  final ValueChanged<DisplayInfo> onSelect;

  static const _height = 124.0;
  static const _pad = 10.0;
  static const _gap = 4.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: _height,
      decoration: BoxDecoration(
        color: c.bgPrimary,
        borderRadius: Radii.field,
        border: Border.all(color: c.borderSubtle),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          if (displays.isEmpty) return const SizedBox.shrink();
          var left = displays.first.x, top = displays.first.y;
          var right = left + displays.first.width;
          var bottom = top + displays.first.height;
          for (final d in displays) {
            left = math.min(left, d.x);
            top = math.min(top, d.y);
            right = math.max(right, d.x + d.width);
            bottom = math.max(bottom, d.y + d.height);
          }
          final availW = box.maxWidth - 2 * _pad;
          final availH = box.maxHeight - 2 * _pad;
          final scale = math.min(
            availW / (right - left),
            availH / (bottom - top),
          );
          final dx = _pad + (availW - (right - left) * scale) / 2;
          final dy = _pad + (availH - (bottom - top) * scale) / 2;
          return Stack(
            children: [
              for (var i = 0; i < displays.length; i++)
                Positioned(
                  left: dx + (displays[i].x - left) * scale + _gap / 2,
                  top: dy + (displays[i].y - top) * scale + _gap / 2,
                  width: displays[i].width * scale - _gap,
                  height: displays[i].height * scale - _gap,
                  child: _Tile(
                    number: i + 1,
                    selected: displays[i].id == selectedId,
                    shownLabel: shownLabel,
                    label: displays[i].label,
                    onTap: () => onSelect(displays[i]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.number,
    required this.selected,
    required this.shownLabel,
    required this.label,
    required this.onTap,
  });
  final int number;
  final bool selected;
  final String shownLabel, label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Hover(
        onTap: onTap,
        borderRadius: Radii.field,
        lift: 0,
        background: selected ? c.bgSelectedBlock : c.bgSecondary,
        border: Border.all(
          color: selected ? c.accent : c.thread,
          width: selected ? 1.5 : 1,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$number',
                style: tsDisplay(
                  const TypeSpec(18, 20, 700),
                  selected ? c.textPrimary : c.textSecondary,
                ),
              ),
              if (selected)
                Text(
                  shownLabel,
                  maxLines: 1,
                  style: ts(
                    const TypeSpec(10, 12, 600),
                    c.accentText,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.number,
    required this.display,
    required this.selected,
    required this.onTap,
  });
  final int number;
  final DisplayInfo display;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: '${display.label}${display.detail == null ? '' : ', ${display.detail}'}',
      child: Hover(
        onTap: onTap,
        selected: selected,
        selectedColor: c.bgHover,
        borderRadius: Radii.field,
        lift: 0,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          height: 38,
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: selected
                    ? Icon20(Ico.check, size: 18, color: c.accentText)
                    : Keycap('$number'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  display.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(context.type.ui, c.textPrimary, weight: 600),
                ),
              ),
              if (display.detail != null) ...[
                const SizedBox(width: 8),
                Text(
                  display.detail!,
                  style: ts(
                    const TypeSpec(11, 15, 400),
                    c.textTertiary,
                    mono: true,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
