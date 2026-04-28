import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class TrendSparkline extends StatelessWidget {
  const TrendSparkline({
    required this.points,
    this.height = 56,
    this.emptyLabel = '暫無趨勢資料',
    super.key,
  });

  final List<num> points;
  final double height;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (points.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Text(
          emptyLabel,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _TrendSparklinePainter(
            points: points,
            fillColor: colorScheme.primaryContainer,
            lineColor: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _TrendSparklinePainter extends CustomPainter {
  const _TrendSparklinePainter({
    required this.points,
    required this.fillColor,
    required this.lineColor,
  });

  final List<num> points;
  final Color fillColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || points.isEmpty) {
      return;
    }

    final values = points.map((point) => point.toDouble()).toList();
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (values.length == 1) {
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 3, linePaint);
      return;
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = maxValue - minValue;
    final horizontalStep = size.width / (values.length - 1);
    const verticalInset = AppSpacing.xs;
    final drawableHeight = math.max(0.0, size.height - verticalInset * 2);

    final fillPath = Path();
    final linePath = Path();

    for (var index = 0; index < values.length; index += 1) {
      final x = values.length <= 1 ? size.width / 2 : horizontalStep * index;
      final normalized = range == 0 ? 0.5 : (values[index] - minValue) / range;
      final y = verticalInset + (1 - normalized) * drawableHeight;

      if (index == 0) {
        linePath.moveTo(x, y);
        fillPath
          ..moveTo(x, size.height)
          ..lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    canvas
      ..drawPath(fillPath, fillPaint)
      ..drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TrendSparklinePainter oldDelegate) {
    return !listEquals(oldDelegate.points, points) ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.lineColor != lineColor;
  }
}
