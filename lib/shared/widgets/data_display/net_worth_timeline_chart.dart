import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class NetWorthTimelineChart extends StatelessWidget {
  const NetWorthTimelineChart({
    required this.assetPoints,
    required this.liabilityPoints,
    required this.netWorthPoints,
    this.height = 180,
    this.emptyLabel = '暫無時間線資料',
    super.key,
  });

  final List<num> assetPoints;
  final List<num> liabilityPoints;
  final List<num> netWorthPoints;
  final double height;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pointsLength = math.min(
      assetPoints.length,
      math.min(liabilityPoints.length, netWorthPoints.length),
    );

    if (pointsLength <= 1) {
      return Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
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

    final assets = assetPoints
        .take(pointsLength)
        .map((value) => value.toDouble())
        .toList(growable: false);
    final liabilities = liabilityPoints
        .take(pointsLength)
        .map((value) => value.toDouble())
        .toList(growable: false);
    final netWorth = netWorthPoints
        .take(pointsLength)
        .map((value) => value.toDouble())
        .toList(growable: false);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _NetWorthTimelinePainter(
            assets: assets,
            liabilities: liabilities,
            netWorth: netWorth,
            axisColor: colorScheme.outlineVariant,
            assetColor: const Color(0xFF0EA5E9),
            liabilityColor: const Color(0xFFF97316),
            netWorthColor: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _NetWorthTimelinePainter extends CustomPainter {
  const _NetWorthTimelinePainter({
    required this.assets,
    required this.liabilities,
    required this.netWorth,
    required this.axisColor,
    required this.assetColor,
    required this.liabilityColor,
    required this.netWorthColor,
  });

  final List<double> assets;
  final List<double> liabilities;
  final List<double> netWorth;
  final Color axisColor;
  final Color assetColor;
  final Color liabilityColor;
  final Color netWorthColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty ||
        assets.isEmpty ||
        liabilities.isEmpty ||
        netWorth.isEmpty) {
      return;
    }

    final allValues = [...assets, ...liabilities, ...netWorth];
    final minValue = allValues.reduce(math.min);
    final maxValue = allValues.reduce(math.max);
    final range = maxValue - minValue;

    const leftInset = 4.0;
    const rightInset = 4.0;
    const topInset = AppSpacing.xs;
    const bottomInset = AppSpacing.xs;
    final drawableWidth = math.max(1.0, size.width - leftInset - rightInset);
    final drawableHeight = math.max(1.0, size.height - topInset - bottomInset);

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    final gridY1 = topInset + drawableHeight * 0.33;
    final gridY2 = topInset + drawableHeight * 0.66;
    canvas.drawLine(
      Offset(leftInset, gridY1),
      Offset(size.width - rightInset, gridY1),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftInset, gridY2),
      Offset(size.width - rightInset, gridY2),
      axisPaint,
    );

    final assetPath = _buildPath(
      values: assets,
      leftInset: leftInset,
      topInset: topInset,
      drawableWidth: drawableWidth,
      drawableHeight: drawableHeight,
      minValue: minValue,
      range: range,
    );
    final liabilityPath = _buildPath(
      values: liabilities,
      leftInset: leftInset,
      topInset: topInset,
      drawableWidth: drawableWidth,
      drawableHeight: drawableHeight,
      minValue: minValue,
      range: range,
    );
    final netWorthPath = _buildPath(
      values: netWorth,
      leftInset: leftInset,
      topInset: topInset,
      drawableWidth: drawableWidth,
      drawableHeight: drawableHeight,
      minValue: minValue,
      range: range,
    );

    canvas.drawPath(
      assetPath,
      Paint()
        ..color = assetColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      liabilityPath,
      Paint()
        ..color = liabilityColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      netWorthPath,
      Paint()
        ..color = netWorthColor
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  Path _buildPath({
    required List<double> values,
    required double leftInset,
    required double topInset,
    required double drawableWidth,
    required double drawableHeight,
    required double minValue,
    required double range,
  }) {
    final path = Path();
    final denominator = math.max(1, values.length - 1);

    for (var index = 0; index < values.length; index += 1) {
      final x = leftInset + (drawableWidth / denominator) * index;
      final normalized = range == 0 ? 0.5 : (values[index] - minValue) / range;
      final y = topInset + (1 - normalized) * drawableHeight;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _NetWorthTimelinePainter oldDelegate) {
    return !listEquals(oldDelegate.assets, assets) ||
        !listEquals(oldDelegate.liabilities, liabilities) ||
        !listEquals(oldDelegate.netWorth, netWorth) ||
        oldDelegate.axisColor != axisColor ||
        oldDelegate.assetColor != assetColor ||
        oldDelegate.liabilityColor != liabilityColor ||
        oldDelegate.netWorthColor != netWorthColor;
  }
}
