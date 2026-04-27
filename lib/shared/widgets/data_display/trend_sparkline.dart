import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
    if (points.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.line),
        ),
        child: Text(
          emptyLabel,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
        ),
      );
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _TrendSparklinePainter(points)),
    );
  }
}

class _TrendSparklinePainter extends CustomPainter {
  const _TrendSparklinePainter(this.points);

  final List<num> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || points.isEmpty) {
      return;
    }

    final values = points.map((point) => point.toDouble()).toList();
    final fillPaint = Paint()
      ..color = AppColors.accentMuted
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = AppColors.accent
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
    return oldDelegate.points != points;
  }
}
