import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/data_display/money_display.dart';
import '../controllers/income_controller.dart';
import '../models/income_stream.dart';
import 'add_income_page.dart';

class IncomePage extends ConsumerWidget {
  const IncomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(incomeControllerProvider);
    final controller = ref.read(incomeControllerProvider.notifier);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        104,
                      ),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '收入管理',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            IconButton(
                              tooltip: '重新整理',
                              onPressed: () {
                                controller.reload();
                              },
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '管理固定收入來源，讓每月收支估算更接近真實狀況。',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        state.when(
                          data: (streams) => _IncomeDataSection(
                            streams: streams,
                            onToggleActive: (stream, active) async {
                              await controller.upsert(
                                stream.copyWith(
                                  active: active,
                                  updatedAt: DateTime.now().toUtc(),
                                ),
                              );
                            },
                            onDelete: (stream) async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('刪除收入來源？'),
                                    content: Text('確定刪除「${stream.name}」嗎？'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(false);
                                        },
                                        child: const Text('取消'),
                                      ),
                                      FilledButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(true);
                                        },
                                        child: const Text('刪除'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (confirmed == true) {
                                await controller.delete(stream.id);
                              }
                            },
                            onEdit: (stream) async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => Scaffold(
                                    body: AddIncomePage(
                                      initialStream: stream,
                                    ),
                                  ),
                                ),
                              );
                              if (!context.mounted) {
                                return;
                              }
                              await controller.reload();
                            },
                          ),
                          loading: () => const Padding(
                            padding: EdgeInsets.only(top: AppSpacing.lg),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (error, _) => _IncomeErrorState(
                            message: error.toString(),
                            onRetry: () {
                              controller.reload();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                    child: FloatingActionButton.extended(
                      heroTag: 'income-add-fab',
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const Scaffold(body: AddIncomePage()),
                          ),
                        );
                        if (!context.mounted) {
                          return;
                        }
                        await controller.reload();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('新增收入'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _IncomeDataSection extends StatelessWidget {
  const _IncomeDataSection({
    required this.streams,
    required this.onToggleActive,
    required this.onDelete,
    required this.onEdit,
  });

  final List<IncomeStream> streams;
  final Future<void> Function(IncomeStream stream, bool active) onToggleActive;
  final Future<void> Function(IncomeStream stream) onDelete;
  final Future<void> Function(IncomeStream stream) onEdit;

  @override
  Widget build(BuildContext context) {
    if (streams.isEmpty) {
      return const _EmptyIncomeState();
    }

    final monthlyTotal = streams
        .where((stream) => stream.active)
        .fold<num>(0, (sum, stream) => sum + _monthlyContribution(stream));
    final activeCount = streams.where((stream) => stream.active).length;

    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '估算每月總收入',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      MoneyDisplay(
                        amount: monthlyTotal,
                        size: 22,
                        weight: FontWeight.w700,
                      ),
                    ],
                  ),
                ),
                Text(
                  '啟用中 $activeCount 筆',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final entry in streams.indexed) ...[
          _IncomeStreamCard(
            stream: entry.$2,
            onToggleActive: (active) async {
              await onToggleActive(entry.$2, active);
            },
            onDelete: () async {
              await onDelete(entry.$2);
            },
            onEdit: () async {
              await onEdit(entry.$2);
            },
          ),
          if (entry.$1 != streams.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _IncomeStreamCard extends StatelessWidget {
  const _IncomeStreamCard({
    required this.stream,
    required this.onToggleActive,
    required this.onDelete,
    required this.onEdit,
  });

  final IncomeStream stream;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stream.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${stream.frequency.label} · 下次生效 ${_formatDate(stream.nextDate)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                MoneyDisplay(
                  amount: stream.amount,
                  size: 18,
                  weight: FontWeight.w700,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Switch.adaptive(
                  value: stream.active,
                  onChanged: onToggleActive,
                ),
                Text(
                  stream.active ? '啟用中' : '已停用',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: '編輯',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: '刪除',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyIncomeState extends StatelessWidget {
  const _EmptyIncomeState();

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
          '目前還沒有收入來源，點右下角先新增一筆。',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _IncomeErrorState extends StatelessWidget {
  const _IncomeErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '收入資料讀取失敗',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重新整理'),
            ),
          ],
        ),
      ),
    );
  }
}

num _monthlyContribution(IncomeStream stream) {
  final now = DateTime.now().toUtc();
  return switch (stream.frequency) {
    IncomeFrequency.monthly => stream.amount,
    IncomeFrequency.yearly => stream.amount / 12,
    IncomeFrequency.oneTime =>
      stream.nextDate.year == now.year && stream.nextDate.month == now.month
          ? stream.amount
          : 0,
  };
}

String _formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year/$month/$day';
}
