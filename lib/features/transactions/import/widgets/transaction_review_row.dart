import 'package:flutter/material.dart';

import '../../../../../core/formatters/money_formatter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/forms/category_tag.dart';
import '../models/imported_transaction.dart';

class TransactionReviewRow extends StatelessWidget {
  const TransactionReviewRow({
    super.key,
    required this.transaction,
    required this.onCategoryTap,
    this.initiallyExpanded,
  });

  final ImportedTransaction transaction;
  final VoidCallback onCategoryTap;
  final bool? initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isInitiallyExpanded = initiallyExpanded ?? transaction.requiresReview;

    return Card(
      key: ValueKey('review-row-${transaction.id}'),
      child: ExpansionTile(
        initiallyExpanded: isInitiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        title: Text(
          transaction.merchantName,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CategoryTag(
                key: ValueKey('category-tag-${transaction.id}'),
                label: transaction.suggestedCategory,
                selected: true,
                onTap: onCategoryTap,
              ),
              Text(
                _confidenceLabel(transaction),
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        trailing: Text(
          MoneyFormatter.twd(transaction.amount),
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              transaction.reason,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _confidenceLabel(ImportedTransaction transaction) {
    if (transaction.newMerchant) {
      return '新商家';
    }

    return transaction.requiresReview ? '建議確認' : '高信心度';
  }
}
