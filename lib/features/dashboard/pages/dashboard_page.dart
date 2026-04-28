import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_paths.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/dashboard_controller.dart';
import '../models/dashboard_snapshot.dart';
import '../../../shared/widgets/data_display/allocation_bar.dart';
import '../../../shared/widgets/data_display/money_display.dart';
import '../../../shared/widgets/data_display/progress_bar.dart';
import '../../../shared/widgets/data_display/trend_sparkline.dart';
import '../../../shared/widgets/feedback/disclaimer_banner.dart';
import '../../../shared/widgets/feedback/health_alert_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(dashboardControllerProvider);

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
                      _PageHeader(monthLabel: snapshot.monthLabel),
                      const SizedBox(height: AppSpacing.lg),
                      _ResponsiveDashboardGrid(snapshot: snapshot),
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

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.monthLabel});

  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '總覽 Dashboard',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          monthLabel,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ResponsiveDashboardGrid extends StatelessWidget {
  const _ResponsiveDashboardGrid({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 860;
        if (!isWide) {
          return Column(
            children:
                [
                  _SavingsPanel(snapshot: snapshot),
                  _NetWorthPanel(snapshot: snapshot),
                  _BudgetPanel(snapshot: snapshot),
                  _AllocationPanel(snapshot: snapshot),
                  _AttentionPanel(snapshot: snapshot),
                  _StatementPanel(snapshot: snapshot),
                ].map((child) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: child,
                  );
                }).toList(),
          );
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: _SavingsPanel(snapshot: snapshot)),
                const SizedBox(width: AppSpacing.md),
                Expanded(flex: 4, child: _NetWorthPanel(snapshot: snapshot)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _BudgetPanel(snapshot: snapshot)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _AllocationPanel(snapshot: snapshot)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _AttentionPanel(snapshot: snapshot)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _StatementPanel(snapshot: snapshot)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SavingsPanel extends StatelessWidget {
  const _SavingsPanel({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelLabel('本月儲蓄率'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${snapshot.savingsRate.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '目標 ${snapshot.savingsTarget.toStringAsFixed(0)}%,本月節奏穩定',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          ProgressBar(
            value: snapshot.savingsRate,
            max: 40,
            target: snapshot.savingsTarget,
            tone: ProgressTone.calm,
          ),
        ],
      ),
    );
  }
}

class _NetWorthPanel extends StatelessWidget {
  const _NetWorthPanel({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelLabel('淨資產'),
          const SizedBox(height: AppSpacing.sm),
          MoneyDisplay(amount: snapshot.netWorth, size: 30),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(Icons.trending_up, size: 16, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
              MoneyDisplay(
                amount: snapshot.netWorthDelta,
                size: 14,
                showSign: true,
                muted: true,
              ),
              Text(
                ' 較上月',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TrendSparkline(points: snapshot.netWorthTrend),
        ],
      ),
    );
  }
}

class _BudgetPanel extends StatelessWidget {
  const _BudgetPanel({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelLabel('本月預算進度'),
          const SizedBox(height: AppSpacing.md),
          for (final item in snapshot.budgetSummary) ...[
            Row(
              children: [
                SizedBox(width: 42, child: Text(item.label)),
                Expanded(
                  child: ProgressBar(
                    value: item.used.toDouble(),
                    max: item.limit.toDouble(),
                    tone: item.tone,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${(item.used / item.limit * 100).round()}%',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _AllocationPanel extends StatelessWidget {
  const _AllocationPanel({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelLabel('投資配置'),
          const SizedBox(height: AppSpacing.md),
          AllocationBar(segments: snapshot.allocationSummary),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final segment in snapshot.allocationSummary)
                _LegendDot(
                  color: segment.color,
                  label: '${segment.label} ${segment.value.round()}%',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttentionPanel extends StatelessWidget {
  const _AttentionPanel({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelLabel('值得檢視'),
          const SizedBox(height: AppSpacing.md),
          for (final entry in snapshot.attentionItems.indexed) ...[
            HealthAlertCard(
              tone: entry.$1.isEven
                  ? HealthAlertTone.review
                  : HealthAlertTone.info,
              title: entry.$2.title,
              body: entry.$2.body,
            ),
            if (entry.$1 != snapshot.attentionItems.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _StatementPanel extends StatelessWidget {
  const _StatementPanel({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelLabel('本期信用卡帳單'),
          const SizedBox(height: AppSpacing.sm),
          MoneyDisplay(amount: snapshot.statementSummary, size: 28),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '結帳日後可匯入帳單,系統會先套用已記住的分類規則。',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => context.go(RoutePaths.transactionsImport),
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('匯入本期帳單'),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              alignment: Alignment.centerLeft,
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}

class _PanelLabel extends StatelessWidget {
  const _PanelLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
