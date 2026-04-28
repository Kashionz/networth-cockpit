import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/data_display/money_display.dart';
import '../../../shared/widgets/data_display/net_worth_timeline_chart.dart';
import '../controllers/performance_controller.dart';

class PortfolioPerformancePage extends ConsumerWidget {
  const PortfolioPerformancePage({super.key});

  static final DateFormat _dateLabel = DateFormat('yyyy/MM/dd');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(portfolioPerformanceControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '配置表現',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '查看資產、負債與淨值的長期時間線，里程碑達成會一次性記錄。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (state.errorMessage != null)
                  _InfoBanner(
                    text: state.errorMessage!,
                    icon: Icons.error_outline,
                    toneColor: colorScheme.error,
                  ),
                if (state.usedFallback)
                  _InfoBanner(
                    text: '目前顯示本地估算資料，連線後會自動切換為雲端時間線。',
                    icon: Icons.info_outline,
                    toneColor: colorScheme.primary,
                  ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref
                          .read(portfolioPerformanceControllerProvider.notifier)
                          .reload();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('重新整理'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (state.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  _TimelineSection(state: state),
                  const SizedBox(height: AppSpacing.md),
                  _MilestoneSection(state: state),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.state});

  final PortfolioPerformanceState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeline = state.timeline;
    final latest = timeline.isEmpty ? null : timeline.last;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '淨值時間線',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            NetWorthTimelineChart(
              assetPoints: [for (final point in timeline) point.assets],
              liabilityPoints: [
                for (final point in timeline) point.liabilities,
              ],
              netWorthPoints: [for (final point in timeline) point.netWorth],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: const [
                _LegendDot(color: Color(0xFF0EA5E9), label: '資產'),
                _LegendDot(color: Color(0xFFF97316), label: '負債'),
                _LegendDot(color: Colors.indigo, label: '淨值'),
              ],
            ),
            if (latest != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                '最新（${PortfolioPerformancePage._dateLabel.format(latest.date)}）',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: '資產',
                      value: MoneyDisplay(
                        amount: latest.assets,
                        size: 16,
                        muted: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MetricTile(
                      label: '負債',
                      value: MoneyDisplay(
                        amount: latest.liabilities,
                        size: 16,
                        muted: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MetricTile(
                      label: '淨值',
                      value: MoneyDisplay(
                        amount: latest.netWorth,
                        size: 16,
                        muted: false,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (timeline.isEmpty)
              Text(
                '目前沒有可顯示的時間線資料。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneSection extends StatelessWidget {
  const _MilestoneSection({required this.state});

  final PortfolioPerformanceState state;

  @override
  Widget build(BuildContext context) {
    final milestones = state.milestones;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '里程碑紀錄',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (milestones.isEmpty)
              Text(
                '目前尚未達成新的里程碑，達標後會只記錄一次。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final milestone in milestones)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.emoji_events_outlined, size: 20),
                    title: Text(milestone.title),
                    subtitle: Text(
                      '${milestone.description}\n${PortfolioPerformancePage._dateLabel.format(milestone.achievedAt)}',
                    ),
                    isThreeLine: true,
                  ),
                ),
          ],
        ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(label),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          value,
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.text,
    required this.icon,
    required this.toneColor,
  });

  final String text;
  final IconData icon;
  final Color toneColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: toneColor),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
