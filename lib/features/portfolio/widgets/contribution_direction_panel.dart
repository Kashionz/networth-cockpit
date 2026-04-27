import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/data_display/allocation_bar.dart';
import '../models/asset_allocation.dart';
import '../models/contribution_direction.dart';

class ContributionDirectionPanel extends StatelessWidget {
  const ContributionDirectionPanel({required this.directions, super.key});

  final List<ContributionDirection> directions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '補倉方向',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '以下比例可作為新投入資金的類別分配參考。',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AllocationBar(
              height: 14,
              segments: [
                for (final direction in directions)
                  AllocationSegment(
                    label: direction.category.label,
                    value: direction.ratio,
                    color: direction.category.color,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final direction in directions) ...[
              _DirectionRow(direction: direction),
              if (direction != directions.last)
                const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              '僅提供類別比例參考,不涉及個別標的或下單建議。',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionRow extends StatelessWidget {
  const _DirectionRow({required this.direction});

  final ContributionDirection direction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LegendDot(color: direction.category.color),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                direction.category.label,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (direction.note != null)
                Text(
                  direction.note!,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 0,
                  ),
                ),
            ],
          ),
        ),
        Text(
          '${direction.ratio.toStringAsFixed(1)}%',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
