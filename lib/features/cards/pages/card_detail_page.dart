import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/credit_card_account.dart';
import '../widgets/statement_summary_panel.dart';

class CardDetailPage extends StatelessWidget {
  const CardDetailPage({super.key, required this.card});

  final CreditCardAccount card;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('卡片詳情')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              card.displayName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (card.maskedNumber != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                card.maskedNumber!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            StatementSummaryPanel(
              title: '本期帳單摘要',
              amount: card.statementAmount,
              statementDate: card.statementCycle.statementDate,
              dueDate: card.statementCycle.dueDate,
            ),
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.line),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  '當帳單已就緒時，可以從這裡直接進入匯入流程。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.go(RoutePaths.transactionsImport),
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('匯入本期帳單'),
            ),
          ],
        ),
      ),
    );
  }
}
