import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/money.dart';
import '../controllers/cards_controller.dart';
import '../models/credit_card_account.dart';
import '../widgets/credit_card_list_item.dart';
import '../widgets/statement_summary_panel.dart';
import 'card_detail_page.dart';

class CardsPage extends ConsumerWidget {
  const CardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardsControllerProvider);
    final controller = ref.read(cardsControllerProvider.notifier);

    final sortedCards = [...cards]
      ..sort(
        (a, b) => a.statementCycle.dueDate.compareTo(b.statementCycle.dueDate),
      );
    final totalStatement = cards.fold<num>(
      0,
      (sum, card) => sum + card.statementAmount.amount,
    );
    final leadCard = sortedCards.isEmpty ? null : sortedCards.first;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '信用卡',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.go(RoutePaths.cardsAdd),
                    icon: const Icon(Icons.add),
                    label: const Text('新增信用卡'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '快速查看本期帳單金額、結帳日與繳款日。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (leadCard != null)
                StatementSummaryPanel(
                  title: '本期帳單總額',
                  amount: Money.twd(totalStatement),
                  statementDate: leadCard.statementCycle.statementDate,
                  dueDate: leadCard.statementCycle.dueDate,
                )
              else
                const _EmptyCardsState(),
              if (sortedCards.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '卡片列表',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final entry in sortedCards.indexed) ...[
                  CreditCardListItem(
                    card: entry.$2,
                    onTap: () => _openCardDetail(context, entry.$2),
                    onDelete: () => controller.deleteCard(entry.$2.id),
                  ),
                  if (entry.$1 != sortedCards.length - 1)
                    const SizedBox(height: AppSpacing.xs),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

void _openCardDetail(BuildContext context, CreditCardAccount card) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => CardDetailPage(card: card)));
}

class _EmptyCardsState extends StatelessWidget {
  const _EmptyCardsState();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          '目前尚未建立卡片，先新增一張常用信用卡。',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
