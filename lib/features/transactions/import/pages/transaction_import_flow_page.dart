import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../controllers/transaction_import_controller.dart';
import '../models/import_step.dart';
import '../models/imported_transaction.dart';
import '../widgets/category_picker_sheet.dart';
import '../widgets/import_summary_band.dart';
import '../widgets/transaction_review_row.dart';
import '../widgets/upload_drop_zone.dart';

class TransactionImportFlowPage extends ConsumerWidget {
  const TransactionImportFlowPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionImportControllerProvider);
    final controller = ref.read(transactionImportControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('信用卡帳單匯入')),
      body: SafeArea(
        child: switch (state.currentStep) {
          ImportStep.selectingCard => _CardSelectionStep(
            options: state.cardOptions,
            onSelect: controller.selectCard,
          ),
          ImportStep.uploading => _StepScaffold(
            title: '上傳帳單',
            description:
                '${state.selectedCard ?? '信用卡'} 已選好，請上傳檔案路徑或貼上 CSV 內容。',
            children: [
              UploadDropZone(
                onLoadFromPath: controller.submitCsvPath,
                onSubmitCsvContent: controller.submitCsvContent,
                onSelectSampleFile: controller.useSampleFile,
                statusLabel: state.uploadStatusLabel,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: controller.restart,
                    icon: const Icon(Icons.arrow_back_outlined),
                    label: const Text('重新選擇卡片'),
                  ),
                  TextButton(
                    onPressed: controller.markFileUnableToParse,
                    child: const Text('這份檔案暫時無法解析'),
                  ),
                ],
              ),
            ],
          ),
          ImportStep.parsing => _StepScaffold(
            title: '解析帳單',
            description: '已讀取檔案，接著整理商家名稱、金額與分類建議。',
            children: [
              const LinearProgressIndicator(value: 0.64),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: controller.startParsing,
                child: const Text('開始解析'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: controller.backToUpload,
                child: const Text('返回上一步'),
              ),
            ],
          ),
          ImportStep.reviewing => _ReviewStep(
            state: state,
            onAcceptAll: controller.applyAllSuggestions,
            onConfirm: controller.confirmCategories,
            onChangeCategory: (row) async {
              final category = await showCategoryPickerSheet(
                context: context,
                categories: state.categoryOptions,
                selectedCategory: row.suggestedCategory,
              );

              if (category != null) {
                controller.updateReviewCategory(row.id, category);
              }
            },
          ),
          ImportStep.confirming => _StepScaffold(
            title: '寫入前確認',
            description: '分類建議已整理完成，確認後會寫入 transactions 與 card_statements。',
            children: [
              if (state.periodStart != null && state.periodEnd != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    '帳單區間：${_formatDate(state.periodStart!)} ~ ${_formatDate(state.periodEnd!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (state.skippedRowCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    '已略過 ${state.skippedRowCount} 列無效資料',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ImportSummaryBand(
                writeCount: state.writeCount,
                budgetImpacts: state.budgetImpacts,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: state.isWriting
                    ? null
                    : () {
                        controller.writeImportedRows();
                      },
                child: Text(state.isWriting ? '寫入中...' : '完成寫入'),
              ),
            ],
          ),
          ImportStep.completed => _StepScaffold(
            title: '完成匯入',
            description: state.completionMessage ?? '本月帳單已匯入，下一次相同商家會更快分類。',
            children: [
              _InfoPanel(
                icon: state.usedSupabaseFallback
                    ? Icons.info_outline
                    : Icons.check_circle_outline,
                title: state.usedSupabaseFallback ? '已完成流程（Fallback）' : '已整理完成',
                description: state.usedSupabaseFallback
                    ? '目前已完成審核流程，但尚未成功寫入雲端。'
                    : '可以回到交易列表查看匯入結果。',
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: controller.restart,
                child: const Text('匯入另一份帳單'),
              ),
            ],
          ),
          ImportStep.failed => _StepScaffold(
            title:
                state.failureTitle ?? TransactionImportState.unableToParseTitle,
            description:
                state.failureMessage ??
                TransactionImportState.unableToParseMessage,
            children: [
              const _InfoPanel(
                icon: Icons.description_outlined,
                title: '檔案格式需要再確認',
                description: '目前支援一般信用卡 CSV 欄位（日期/商家/金額）。',
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: controller.restart,
                child: const Text('重新選擇卡片'),
              ),
            ],
          ),
        },
      ),
    );
  }
}

class _CardSelectionStep extends StatelessWidget {
  const _CardSelectionStep({required this.options, required this.onSelect});

  final List<ImportCardOption> options;
  final void Function(ImportCardOption card) onSelect;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: '選擇信用卡',
      description: '先選擇這份帳單所屬的信用卡，後續會依卡片整理匯入紀錄。',
      children: [
        for (final option in options) ...[
          _InfoPanel(
            icon: Icons.credit_card_outlined,
            title: option.name,
            description: option.helperText,
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: () => onSelect(option),
              child: const Text('選擇卡片'),
            ),
          ),
          if (option != options.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          title,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          description,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...children,
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.state,
    required this.onAcceptAll,
    required this.onConfirm,
    required this.onChangeCategory,
  });

  final TransactionImportState state;
  final VoidCallback onAcceptAll;
  final VoidCallback onConfirm;
  final Future<void> Function(ImportedTransaction row) onChangeCategory;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          '確認分類建議',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '系統已先整理帳單內容，確認後即可加入本月現金流。',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: '已自動分類 ${state.autoClassifiedCount} 筆',
                helperText: '可直接套用',
                color: AppColors.accentMuted,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SummaryTile(
                label: '待確認 ${state.reviewRows.length} 筆',
                helperText: '查看建議分類',
                color: AppColors.surfaceMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const _MemoryRuleBanner(),
        const SizedBox(height: AppSpacing.lg),
        if (state.suggestionsApplied) ...[
          const _AppliedNotice(),
          const SizedBox(height: AppSpacing.md),
        ],
        FilledButton(
          onPressed: state.reviewRows.isEmpty ? null : onAcceptAll,
          child: const Text('接受全部建議'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(onPressed: onConfirm, child: const Text('確認分類')),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '待確認商家',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.reviewRows.isEmpty)
          const _EmptyReviewState()
        else
          for (final row in state.reviewRows) ...[
            TransactionReviewRow(
              transaction: row,
              onCategoryTap: () => onChangeCategory(row),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.helperText,
    required this.color,
  });

  final String label;
  final String helperText;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              helperText,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.accent),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryRuleBanner extends StatelessWidget {
  const _MemoryRuleBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accentEdge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome_outlined, color: AppColors.accent),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '越用越快',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '確認過的商家會成為下次分類規則，月底整理會更省時。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppliedNotice extends StatelessWidget {
  const _AppliedNotice();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accentMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accentEdge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          '分類建議已套用',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyReviewState extends StatelessWidget {
  const _EmptyReviewState();

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
          '本次匯入的待確認項目已整理完成。',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}/$month/$day';
}
