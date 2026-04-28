import 'package:flutter/material.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
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
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
              Container(
                height: height,
                width: width * ratio,
                decoration: BoxDecoration(
                  color: _toneColor(tone, colorScheme),
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
                      color: colorScheme.onSurfaceVariant,
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

  Color _toneColor(ProgressTone tone, ColorScheme colorScheme) {
    return switch (tone) {
      ProgressTone.calm => colorScheme.primary,
      ProgressTone.near => colorScheme.tertiary,
      ProgressTone.review => colorScheme.secondary,
    };
  }
}
