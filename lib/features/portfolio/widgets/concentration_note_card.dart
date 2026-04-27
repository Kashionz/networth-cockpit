import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class ConcentrationNoteCard extends StatelessWidget {
  const ConcentrationNoteCard({
    required this.topFiveConcentration,
    required this.largestHoldingConcentration,
    super.key,
  });

  final double topFiveConcentration;
  final double largestHoldingConcentration;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.pie_chart_outline,
              size: 20,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '集中度說明',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Top 5 持股合計 ${topFiveConcentration.toStringAsFixed(1)}%,單一持股最高 ${largestHoldingConcentration.toStringAsFixed(1)}%。',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _neutralNote(topFiveConcentration),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _neutralNote(double concentration) {
    if (concentration >= 60) {
      return '後續投入可逐步分散到其他類別,讓配置更貼近目標。';
    }
    if (concentration >= 45) {
      return '集中度落在常見區間,可搭配目標配置持續檢視。';
    }
    return '集中度相對分散,維持定期檢視即可。';
  }
}
