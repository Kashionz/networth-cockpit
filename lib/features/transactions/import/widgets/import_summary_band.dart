import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/data_display/money_display.dart';
import '../controllers/transaction_import_controller.dart';

class ImportSummaryBand extends StatelessWidget {
  const ImportSummaryBand({
    super.key,
    required this.writeCount,
    required this.budgetImpacts,
  });

  final int writeCount;
  final List<BudgetImpact> budgetImpacts;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '將寫入 $writeCount 筆',
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '預算影響',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final impact in budgetImpacts) ...[
              _BudgetImpactRow(impact: impact),
              if (impact != budgetImpacts.last)
                const Divider(height: AppSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }
}

class _BudgetImpactRow extends StatelessWidget {
  const _BudgetImpactRow({required this.impact});

  final BudgetImpact impact;

  @override
  Widget build(BuildContext context) {
    final color = switch (impact.label) {
      '固定' => AppColors.budgetFixed,
      '生活' => AppColors.budgetLiving,
      '彈性' => AppColors.budgetFlex,
      _ => AppColors.accent,
    };

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            impact.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: MoneyDisplay(
                amount: impact.amount,
                size: 16,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
