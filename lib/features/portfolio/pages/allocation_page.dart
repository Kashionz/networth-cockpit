import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/portfolio_repository.dart';
import '../controllers/portfolio_controller.dart';
import '../widgets/allocation_compare_panel.dart';
import '../widgets/allocation_drift_list.dart';
import '../widgets/concentration_note_card.dart';
import '../widgets/contribution_direction_panel.dart';
import '../widgets/correlation_matrix_card.dart';
import '../widgets/holdings_section.dart';
import '../../../shared/widgets/feedback/disclaimer_banner.dart';

class AllocationPage extends ConsumerWidget {
  const AllocationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(portfolioControllerProvider);
    final repository = ref.watch(portfolioRepositoryProvider);
    final correlationMatrix = repository.getCorrelationMatrix();
    final highCorrelationRisks = repository.getHighCorrelationRisks();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '投資配置',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '對照目前持倉與目標比例,用新投入資金逐步調整。',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textTertiary,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AllocationComparePanel(allocations: snapshot.allocations),
                      const SizedBox(height: AppSpacing.md),
                      AllocationDriftList(
                        allocations: snapshot.allocationsByDrift,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      HoldingsSection(holdings: snapshot.topHoldings),
                      const SizedBox(height: AppSpacing.md),
                      CorrelationMatrixCard(
                        matrix: correlationMatrix,
                        highCorrelationRisks: highCorrelationRisks,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ContributionDirectionPanel(
                        directions: snapshot.contributionDirections,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ConcentrationNoteCard(
                        topFiveConcentration: snapshot.topFiveConcentration,
                        largestHoldingConcentration:
                            snapshot.largestHoldingConcentration,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const DisclaimerBanner(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
