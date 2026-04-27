import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/data_display/money_display.dart';
import '../models/holding.dart';

class HoldingsSection extends StatelessWidget {
  const HoldingsSection({required this.holdings, super.key});

  final List<Holding> holdings;

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
              'Top 5 持股',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '依市值占比排序',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final entry in holdings.indexed) ...[
              _HoldingRow(index: entry.$1 + 1, holding: entry.$2),
              if (entry.$1 != holdings.length - 1) const Divider(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow({required this.index, required this.holding});

  final int index;
  final Holding holding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$index. ${holding.name}',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '占比 ${holding.weightRatio.toStringAsFixed(1)}%',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Align(
            alignment: Alignment.topRight,
            child: MoneyDisplay(
              amount: holding.marketValue,
              size: 14,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
