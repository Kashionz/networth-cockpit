import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/data_display/allocation_bar.dart';
import '../models/asset_allocation.dart';

class AllocationComparePanel extends StatelessWidget {
  const AllocationComparePanel({required this.allocations, super.key});

  final List<AssetAllocation> allocations;

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
              '現況 vs 目標',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _AllocationBarRow(
              label: '現況配置',
              segments: [
                for (final allocation in allocations)
                  AllocationSegment(
                    label: allocation.category.label,
                    value: allocation.currentRatio,
                    color: allocation.category.color,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _AllocationBarRow(
              label: '目標配置',
              segments: [
                for (final allocation in allocations)
                  AllocationSegment(
                    label: allocation.category.label,
                    value: allocation.targetRatio,
                    color: allocation.category.color,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '類別',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                Text(
                  '現況 / 目標',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final allocation in allocations) ...[
              Row(
                children: [
                  _LegendDot(color: allocation.category.color),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      allocation.category.label,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${_formatPercent(allocation.currentRatio)} / ${_formatPercent(allocation.targetRatio)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (allocation != allocations.last)
                const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }

  String _formatPercent(double value) => '${value.toStringAsFixed(1)}%';
}

class _AllocationBarRow extends StatelessWidget {
  const _AllocationBarRow({required this.label, required this.segments});

  final String label;
  final List<AllocationSegment> segments;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.xs),
        AllocationBar(segments: segments, height: 14),
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
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
