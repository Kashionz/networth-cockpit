import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/risk_answer.dart';

typedef AllocationSliderChanged =
    void Function(AllocationBucket bucket, double value);

class AllocationSliderGroup extends StatelessWidget {
  const AllocationSliderGroup({
    required this.allocation,
    required this.onChanged,
    super.key,
  });

  final AssetAllocation allocation;
  final AllocationSliderChanged onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AllocationSliderRow(
          bucket: AllocationBucket.equity,
          value: allocation.equity,
          color: AppColors.assetEquity,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        _AllocationSliderRow(
          bucket: AllocationBucket.bond,
          value: allocation.bond,
          color: AppColors.assetBond,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        _AllocationSliderRow(
          bucket: AllocationBucket.cash,
          value: allocation.cash,
          color: AppColors.assetCash,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _AllocationSliderRow extends StatelessWidget {
  const _AllocationSliderRow({
    required this.bucket,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final AllocationBucket bucket;
  final int value;
  final Color color;
  final AllocationSliderChanged onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bucket.label,
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    '$value%',
                    textAlign: TextAlign.right,
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbColor: color,
                activeTrackColor: color,
                inactiveTrackColor: AppColors.surfaceSoft,
                overlayColor: color.withValues(alpha: 0.12),
              ),
              child: Slider(
                key: ValueKey('allocation-slider-${bucket.name}'),
                min: 0,
                max: 100,
                divisions: 100,
                value: value.toDouble(),
                onChanged: (next) => onChanged(bucket, next),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
