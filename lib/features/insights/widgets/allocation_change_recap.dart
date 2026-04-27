import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/monthly_insight.dart';

class AllocationChangeRecap extends StatelessWidget {
  const AllocationChangeRecap({required this.items, super.key});

  final List<AllocationChangeItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '配置變化',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final item in items.indexed) ...[
              _AllocationRow(item: item.$2),
              if (item.$1 != items.length - 1) const Divider(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _AllocationRow extends StatelessWidget {
  const _AllocationRow({required this.item});

  final AllocationChangeItem item;

  @override
  Widget build(BuildContext context) {
    final changeColor = item.changeFromLastMonth.abs() < 0.0005
        ? AppColors.textTertiary
        : AppColors.accent;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '現況 ${item.currentWeightLabel} · 目標 ${item.targetWeightLabel}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              item.changeLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: changeColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              item.driftLabel,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ],
    );
  }
}
