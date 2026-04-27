import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/data_display/money_display.dart';
import '../models/credit_card_account.dart';

class CreditCardListItem extends StatelessWidget {
  const CreditCardListItem({
    super.key,
    required this.card,
    this.onTap,
    this.onDelete,
  });

  final CreditCardAccount card;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final statementDate = _formatShortDate(card.statementCycle.statementDate);
    final dueDate = _formatShortDate(card.statementCycle.dueDate);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.credit_card_outlined, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (card.maskedNumber != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        card.maskedNumber!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '結帳日 $statementDate · 繳款日 $dueDate',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MoneyDisplay(
                    amount: card.statementAmount,
                    size: 16,
                    weight: FontWeight.w700,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '本期帳單',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              if (onDelete != null) ...[
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  tooltip: '移除卡片',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatShortDate(DateTime date) => '${date.month}/${date.day}';
