// Compact zoom bar: zoom out, percentage label button, zoom in, optional fit.

import 'package:flutter/widgets.dart';

import 'hover.dart';
import 'icons.dart';
import 'lines.dart';
import 'tokens.dart';
import 'tooltip.dart';

const _defaultMinZoom = 0.1;
const _defaultMaxZoom = 16.0;
const _percentScale = 100;
const _zoomEpsilon = 1e-6;

/// A zoom control strip with zoom-out, percentage button, zoom-in, and an
/// optional zoom-to-fit button.
///
/// Zoom-out and zoom-in automatically disable at [min] and [max].
class ZoomControl extends StatelessWidget {
  const ZoomControl({
    super.key,
    required this.zoom,
    this.min = _defaultMinZoom,
    this.max = _defaultMaxZoom,
    this.onZoomOut,
    this.onZoomIn,
    this.onLabelPressed,
    this.onFit,
  }) : assert(min < max);

  /// Current zoom factor where `1.0` represents `100%`.
  final double zoom;

  /// Minimum allowed zoom factor.
  final double min;

  /// Maximum allowed zoom factor.
  final double max;

  /// Called when zoom-out is pressed; disabled automatically when `zoom <= min`.
  final VoidCallback? onZoomOut;

  /// Called when zoom-in is pressed; disabled automatically when `zoom >= max`.
  final VoidCallback? onZoomIn;

  /// Called when the percentage readout is pressed (e.g. to reset or open
  /// presets).
  final VoidCallback? onLabelPressed;

  /// Optional callback for a trailing "fit to view" icon button.
  final VoidCallback? onFit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final btnSize = context.touch ? ControlSize.xl : ControlSize.xs;
    final canZoomOut = onZoomOut != null && zoom > min + _zoomEpsilon;
    final canZoomIn = onZoomIn != null && zoom < max - _zoomEpsilon;
    final percentText = '${(zoom * _percentScale).round()}%';

    return Container(
      padding: const EdgeInsets.all(Space.hair),
      decoration: BoxDecoration(
        color: c.bgElevated,
        borderRadius: Radii.ctl,
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: Space.hair,
        children: [
          _ZoomIconBtn(
            icon: Ico.minus,
            label: 'Zoom out',
            size: btnSize,
            onTap: canZoomOut ? onZoomOut : null,
          ),
          AppTooltip(
            label: 'Zoom level',
            child: Semantics(
              button: true,
              enabled: onLabelPressed != null,
              label: 'Zoom $percentText',
              excludeSemantics: true,
              onTap: onLabelPressed,
              child: Hover(
                onTap: onLabelPressed,
                lift: 0,
                borderRadius: Radii.ctl,
                padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: btnSize.height,
                    minWidth: ControlSize.xxl.height,
                  ),
                  child: Center(
                    child: Text(
                      percentText,
                      style:
                          ts(
                            context.type.uiSmall,
                            c.textPrimary,
                            weight: Weight.strong,
                          ).copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _ZoomIconBtn(
            icon: Ico.plus,
            label: 'Zoom in',
            size: btnSize,
            onTap: canZoomIn ? onZoomIn : null,
          ),
          if (onFit != null) ...[
            const VLine(height: Space.lg),
            _ZoomIconBtn(
              icon: Ico.maximize,
              label: 'Zoom to fit',
              size: btnSize,
              onTap: onFit,
            ),
          ],
        ],
      ),
    );
  }
}

class _ZoomIconBtn extends StatelessWidget {
  const _ZoomIconBtn({
    required this.icon,
    required this.label,
    required this.size,
    required this.onTap,
  });

  final Ico icon;
  final String label;
  final ControlSize size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onTap != null;
    return AppTooltip(
      label: label,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: Hover(
          onTap: onTap,
          lift: 0,
          borderRadius: Radii.ctl,
          child: SizedBox(
            width: size.height,
            height: size.height,
            child: Center(
              child: Icon20(
                icon,
                size: IconSize.sm,
                color: enabled ? c.iconSecondary : c.textDisabled,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
