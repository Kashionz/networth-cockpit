import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum ProgressTone { calm, near, review }

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    required this.value,
    required this.max,
    this.target,
    this.tone = ProgressTone.calm,
    this.height = 8,
    super.key,
  });

  final double value;
  final double max;
  final double? target;
  final ProgressTone tone;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ratio = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    final markerRatio = target == null || max <= 0
        ? null
        : (target! / max).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: height + 8,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: height,
                width: width * ratio,
                decoration: BoxDecoration(
                  color: _toneColor(tone),
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
              if (markerRatio != null)
                Positioned(
                  left: (width * markerRatio).clamp(0, width - 2),
                  child: Container(
                    width: 2,
                    height: height + 8,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _toneColor(ProgressTone tone) {
    return switch (tone) {
      ProgressTone.calm => AppColors.accent,
      ProgressTone.near => AppColors.near,
      ProgressTone.review => AppColors.review,
    };
  }
}
