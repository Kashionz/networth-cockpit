import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/asset_allocation.dart';

class AllocationDriftList extends StatelessWidget {
  const AllocationDriftList({required this.allocations, super.key});

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
              '偏離度',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '正值代表高於目標,負值代表低於目標。',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final allocation in allocations) ...[
              _DriftRow(allocation: allocation),
              if (allocation != allocations.last)
                const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _DriftRow extends StatelessWidget {
  const _DriftRow({required this.allocation});

  final AssetAllocation allocation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final drift = allocation.driftRatio;
    final driftMagnitude = (drift.abs() / 20).clamp(0.0, 1.0);
    final toneColor = drift.abs() >= 8 ? AppColors.near : AppColors.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                allocation.category.label,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              _formatDrift(drift),
              style: textTheme.bodyMedium?.copyWith(
                color: toneColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: driftMagnitude,
            color: toneColor,
            backgroundColor: AppColors.surfaceSoft,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '現況 ${allocation.currentRatio.toStringAsFixed(1)}% / 目標 ${allocation.targetRatio.toStringAsFixed(1)}%',
          style: textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }

  String _formatDrift(double value) {
    if (value >= 0) {
      return '+${value.toStringAsFixed(1)}%';
    }
    return '${value.toStringAsFixed(1)}%';
  }
}
