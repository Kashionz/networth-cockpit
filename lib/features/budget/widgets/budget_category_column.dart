import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/data_display/money_display.dart';
import '../../../shared/widgets/data_display/progress_bar.dart';
import '../models/budget_category.dart';

class BudgetCategoryColumn extends StatelessWidget {
  const BudgetCategoryColumn({required this.categories, super.key});

  final List<BudgetCategory> categories;

  @override
  Widget build(BuildContext context) {
    final ordered = [
      for (final type in BudgetCategoryType.values)
        ...categories.where((category) => category.type == type),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '三類預算進度',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var index = 0; index < ordered.length; index++) ...[
              _BudgetCategoryRow(category: ordered[index]),
              if (index != ordered.length - 1) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _BudgetCategoryRow extends StatelessWidget {
  const _BudgetCategoryRow({required this.category});

  final BudgetCategory category;

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(category);
    final usageColor = switch (tone) {
      ProgressTone.calm => AppColors.textSecondary,
      ProgressTone.near => AppColors.near,
      ProgressTone.review => AppColors.review,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _categoryColor(category.type),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              category.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const Spacer(),
            _RolloverTag(rollover: category.rollover),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ProgressBar(
          value: category.usedAmount.amount.toDouble(),
          max: category.budgetAmount.amount.toDouble(),
          tone: tone,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Text(
              '${category.usagePercent}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: usageColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _usageHint(category),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 560;
            final stats = [
              _AmountStat(label: '預算', amount: category.budgetAmount),
              _AmountStat(label: '已用', amount: category.usedAmount),
              _AmountStat(
                label: '剩餘',
                amount: category.remainingMoney,
                showSign: true,
              ),
            ];

            if (isCompact) {
              return Column(
                children: [
                  for (var index = 0; index < stats.length; index++) ...[
                    stats[index],
                    if (index != stats.length - 1)
                      const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              );
            }

            return Row(
              children: [
                for (var index = 0; index < stats.length; index++) ...[
                  Expanded(child: stats[index]),
                  if (index != stats.length - 1)
                    const SizedBox(width: AppSpacing.sm),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  ProgressTone _toneFor(BudgetCategory value) {
    if (value.needsReview) {
      return ProgressTone.review;
    }
    if (value.isNearLimit) {
      return ProgressTone.near;
    }
    return ProgressTone.calm;
  }

  Color _categoryColor(BudgetCategoryType type) {
    return switch (type) {
      BudgetCategoryType.fixed => AppColors.budgetFixed,
      BudgetCategoryType.living => AppColors.budgetLiving,
      BudgetCategoryType.flex => AppColors.budgetFlex,
    };
  }

  String _usageHint(BudgetCategory value) {
    if (value.needsReview) {
      return '接近規劃上限，先收斂到必要支出並預留下月彈性。';
    }
    if (value.isNearLimit) {
      return '進入檢視區間，可先確認剩餘天數與日均節奏。';
    }
    return '節奏穩定，可按計畫持續並整理下月想優化項目。';
  }
}

class _AmountStat extends StatelessWidget {
  const _AmountStat({
    required this.label,
    required this.amount,
    this.showSign = false,
  });

  final String label;
  final Object amount;
  final bool showSign;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: MoneyDisplay(
                  amount: amount,
                  size: 14,
                  showSign: showSign,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RolloverTag extends StatelessWidget {
  const _RolloverTag({required this.rollover});

  final bool rollover;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          rollover ? '可滾入下月' : '月底歸零',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
