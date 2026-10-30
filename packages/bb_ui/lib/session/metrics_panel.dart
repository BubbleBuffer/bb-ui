// A panel of live measurements: a title, a trend line and label/value rows.

import 'package:flutter/widgets.dart';

import '../tokens.dart';

/// One measurement: a [label] and its [value] in monospace.
class Metric {
  const Metric(this.label, this.value);
  final String label, value;
}

/// A trend line through [values], scaled to fit its box. A single value or
/// none draws nothing.
class Sparkline extends StatelessWidget {
  const Sparkline(this.values, {super.key, this.height = 24, this.color});
  final List<double> values;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(values, color ?? context.colors.accent),
      ),
    ),
  );
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter(this.values, this.color);
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    var lo = values.first, hi = values.first;
    for (final v in values) {
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    final span = hi - lo == 0 ? 1.0 : hi - lo;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - 2 - (size.height - 4) * (values[i] - lo) / span;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.color != color || old.values != values;
}

/// A corner panel of evidence: [title] with a [hint] at the end (a shortcut),
/// an optional trend ([trend] with its [trendCaption] and [trendValue]) and
/// the [metrics] as rows. It is meant to sit over live content, so it is
/// opaque.
class MetricsPanel extends StatelessWidget {
  const MetricsPanel({
    super.key,
    required this.title,
    required this.metrics,
    this.hint,
    this.trend = const [],
    this.trendCaption,
    this.trendValue,
    this.width = 270,
  });
  final String title;
  final String? hint;
  final List<Metric> metrics;
  final List<double> trend;
  final String? trendCaption, trendValue;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ty = context.type;
    final mono = ts(const TypeSpec(11, 15, 400), c.textSecondary, mono: true);
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.bgElevated,
        borderRadius: Radii.ctl,
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
                  style: ts(ty.uiSmall, c.textPrimary, weight: 700),
                ),
              ),
              if (hint != null)
                Text(hint!, style: mono.copyWith(color: c.textTertiary)),
            ],
          ),
          if (trend.length > 1) ...[
            const SizedBox(height: 8),
            Sparkline(trend),
            if (trendCaption != null || trendValue != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trendCaption ?? '',
                      style: mono.copyWith(color: c.textTertiary),
                    ),
                  ),
                  if (trendValue != null) Text(trendValue!, style: mono),
                ],
              ),
            ],
          ],
          const SizedBox(height: 8),
          for (final m in metrics)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      m.label,
                      style: mono.copyWith(color: c.textTertiary),
                    ),
                  ),
                  Text(m.value, style: mono.copyWith(color: c.textPrimary)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
