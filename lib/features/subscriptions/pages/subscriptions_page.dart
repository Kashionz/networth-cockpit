import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/money.dart';
import '../../../shared/widgets/data_display/money_display.dart';
import '../../../shared/widgets/forms/app_select_field.dart';
import '../../../shared/widgets/forms/app_text_field.dart';
import '../controllers/subscriptions_controller.dart';
import '../models/subscription_item.dart';

class SubscriptionsPage extends ConsumerWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionsControllerProvider);
    final controller = ref.read(subscriptionsControllerProvider.notifier);
    final subscriptions = state.subscriptions;

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
                      '訂閱管理',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () async {
                      final draft = await _showSubscriptionDialog(context);
                      if (draft == null) {
                        return;
                      }
                      await controller.createSubscription(
                        name: draft.name,
                        category: draft.category,
                        amount: draft.amount,
                        currencyCode: draft.currencyCode,
                        billingCycle: draft.billingCycle,
                        nextBillingDate: draft.nextBillingDate,
                        isActive: draft.isActive,
                        accountId: draft.accountId,
                        creditCardId: draft.creditCardId,
                        reminderDaysBefore: draft.reminderDaysBefore,
                        startedOn: draft.startedOn,
                        endedOn: draft.endedOn,
                        metadata: draft.metadata,
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('新增訂閱'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '集中管理固定扣款，並可手動觸發到期扣款入帳。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton.icon(
                    onPressed: state.isProcessingDue
                        ? null
                        : () async {
                            final result = await controller
                                .processDueSubscriptions(manual: true);
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '到期扣款完成：${result.processedCount} 筆交易',
                                ),
                              ),
                            );
                          },
                    icon: state.isProcessingDue
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bolt_outlined),
                    label: Text(state.isProcessingDue ? '處理中...' : '手動處理到期扣款'),
                  ),
                ],
              ),
              if (state.lastDueRunMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                DecoratedBox(
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
                          state.lastDueRunMessage!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (state.lastDueRunAt != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '最後執行時間：${_formatDateTime(state.lastDueRunAt!)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (subscriptions.isEmpty)
                const _EmptySubscriptionsState()
              else
                for (final entry in subscriptions.indexed) ...[
                  _SubscriptionCard(
                    item: entry.$2,
                    onToggleActive: (isActive) {
                      controller.toggleActive(entry.$2.id, isActive);
                    },
                    onEdit: () async {
                      final draft = await _showSubscriptionDialog(
                        context,
                        initial: entry.$2,
                      );
                      if (draft == null) {
                        return;
                      }
                      await controller.updateSubscription(
                        entry.$2.copyWith(
                          name: draft.name,
                          category: draft.category,
                          amount: Money(
                            draft.amount,
                            currencyCode: draft.currencyCode,
                          ),
                          billingCycle: draft.billingCycle,
                          nextBillingDate: draft.nextBillingDate,
                          isActive: draft.isActive,
                          accountId: draft.accountId,
                          clearAccountId: draft.accountId == null,
                          creditCardId: draft.creditCardId,
                          clearCreditCardId: draft.creditCardId == null,
                          reminderDaysBefore: draft.reminderDaysBefore,
                          startedOn: draft.startedOn,
                          clearStartedOn: draft.startedOn == null,
                          endedOn: draft.endedOn,
                          clearEndedOn: draft.endedOn == null,
                          metadata: draft.metadata,
                        ),
                      );
                    },
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('刪除訂閱？'),
                            content: Text('確定刪除「${entry.$2.name}」嗎？'),
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
                      if (confirmed != true) {
                        return;
                      }
                      await controller.deleteSubscription(entry.$2.id);
                    },
                  ),
                  if (entry.$1 != subscriptions.length - 1)
                    const SizedBox(height: AppSpacing.sm),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.item,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  final SubscriptionItem item;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${item.category} · ${item.billingCycle.label}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                MoneyDisplay(
                  amount: item.amount,
                  size: 18,
                  weight: FontWeight.w700,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                Text(
                  '下次扣款：${_formatDate(item.nextBillingDate)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '提醒：提前 ${item.reminderDaysBefore} 天',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (item.accountId != null)
                  Text(
                    'Account: ${item.accountId}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (item.creditCardId != null)
                  Text(
                    'Card: ${item.creditCardId}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Switch(value: item.isActive, onChanged: onToggleActive),
                Text(item.isActive ? '啟用中' : '已停用'),
                const Spacer(),
                IconButton(
                  tooltip: '編輯訂閱',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: '刪除訂閱',
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

class _EmptySubscriptionsState extends StatelessWidget {
  const _EmptySubscriptionsState();

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
          '目前尚未建立訂閱，先新增常用固定扣款服務。',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

Future<_SubscriptionDraft?> _showSubscriptionDialog(
  BuildContext context, {
  SubscriptionItem? initial,
}) {
  return showDialog<_SubscriptionDraft>(
    context: context,
    builder: (context) {
      return _SubscriptionFormDialog(initial: initial);
    },
  );
}

class _SubscriptionFormDialog extends StatefulWidget {
  const _SubscriptionFormDialog({this.initial});

  final SubscriptionItem? initial;

  @override
  State<_SubscriptionFormDialog> createState() =>
      _SubscriptionFormDialogState();
}

class _SubscriptionFormDialogState extends State<_SubscriptionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _amountController;
  late final TextEditingController _currencyController;
  late final TextEditingController _accountIdController;
  late final TextEditingController _creditCardIdController;
  late final TextEditingController _reminderDaysController;

  late SubscriptionBillingCycle _billingCycle;
  late DateTime _nextBillingDate;
  bool _isActive = true;
  DateTime? _startedOn;
  DateTime? _endedOn;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _categoryController = TextEditingController(
      text: initial?.category ?? '固定',
    );
    _amountController = TextEditingController(
      text: initial?.amount.amount.toString() ?? '',
    );
    _currencyController = TextEditingController(
      text: initial?.amount.currencyCode ?? 'TWD',
    );
    _accountIdController = TextEditingController(
      text: initial?.accountId ?? '',
    );
    _creditCardIdController = TextEditingController(
      text: initial?.creditCardId ?? '',
    );
    _reminderDaysController = TextEditingController(
      text: (initial?.reminderDaysBefore ?? 3).toString(),
    );

    _billingCycle = initial?.billingCycle ?? SubscriptionBillingCycle.monthly;
    _nextBillingDate = initial?.nextBillingDate ?? DateTime.now();
    _isActive = initial?.isActive ?? true;
    _startedOn = initial?.startedOn;
    _endedOn = initial?.endedOn;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    _accountIdController.dispose();
    _creditCardIdController.dispose();
    _reminderDaysController.dispose();
    super.dispose();
  }

  Future<void> _pickNextBillingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextBillingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _nextBillingDate = picked;
    });
  }

  Future<void> _pickStartedOn() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startedOn ?? _nextBillingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _startedOn = picked;
    });
  }

  Future<void> _pickEndedOn() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endedOn ?? _nextBillingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _endedOn = picked;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = num.tryParse(_amountController.text.trim()) ?? 0;
    final reminder = int.tryParse(_reminderDaysController.text.trim()) ?? 0;

    Navigator.of(context).pop(
      _SubscriptionDraft(
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        amount: amount,
        currencyCode: _currencyController.text.trim().toUpperCase(),
        billingCycle: _billingCycle,
        nextBillingDate: _nextBillingDate,
        isActive: _isActive,
        accountId: _nullIfEmpty(_accountIdController.text),
        creditCardId: _nullIfEmpty(_creditCardIdController.text),
        reminderDaysBefore: reminder,
        startedOn: _startedOn,
        endedOn: _endedOn,
        metadata: widget.initial?.metadata ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initial;

    return AlertDialog(
      title: Text(initial == null ? '新增訂閱' : '編輯訂閱'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: '名稱',
                  controller: _nameController,
                  hintText: '例如：YouTube Premium',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '請輸入訂閱名稱';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: '分類',
                  controller: _categoryController,
                  hintText: '例如：影音、雲端服務',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '請輸入分類';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: '金額',
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        hintText: '例如：390',
                        validator: (value) {
                          final parsed = num.tryParse(value?.trim() ?? '');
                          if (parsed == null || parsed <= 0) {
                            return '請輸入大於 0 的金額';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppTextField(
                        label: '幣別',
                        controller: _currencyController,
                        hintText: 'TWD',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '請輸入幣別';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppSelectField<SubscriptionBillingCycle>(
                  label: '扣款週期',
                  value: _billingCycle,
                  items: [
                    for (final cycle in SubscriptionBillingCycle.values)
                      AppSelectFieldItem(value: cycle, label: cycle.label),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _billingCycle = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _DateInputTile(
                  label: '下次扣款日',
                  date: _nextBillingDate,
                  onTap: _pickNextBillingDate,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: '提醒提前天數',
                        controller: _reminderDaysController,
                        keyboardType: TextInputType.number,
                        hintText: '3',
                        validator: (value) {
                          final parsed = int.tryParse(value?.trim() ?? '');
                          if (parsed == null || parsed < 0) {
                            return '請輸入 0 以上整數';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _isActive,
                        title: const Text('啟用'),
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: '帳戶 ID（選填）',
                  controller: _accountIdController,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: '信用卡 ID（選填）',
                  controller: _creditCardIdController,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _DateInputTile(
                        label: '開始日（選填）',
                        date: _startedOn,
                        onTap: _pickStartedOn,
                        onClear: _startedOn == null
                            ? null
                            : () {
                                setState(() {
                                  _startedOn = null;
                                });
                              },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _DateInputTile(
                        label: '結束日（選填）',
                        date: _endedOn,
                        onTap: _pickEndedOn,
                        onClear: _endedOn == null
                            ? null
                            : () {
                                setState(() {
                                  _endedOn = null;
                                });
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(initial == null ? '新增' : '儲存'),
        ),
      ],
    );
  }
}

class _DateInputTile extends StatelessWidget {
  const _DateInputTile({
    required this.label,
    required this.date,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(date == null ? '尚未設定' : _formatDate(date!)),
            ),
            if (onClear != null) ...[
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close),
                tooltip: '清除日期',
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SubscriptionDraft {
  const _SubscriptionDraft({
    required this.name,
    required this.category,
    required this.amount,
    required this.currencyCode,
    required this.billingCycle,
    required this.nextBillingDate,
    required this.isActive,
    required this.accountId,
    required this.creditCardId,
    required this.reminderDaysBefore,
    required this.startedOn,
    required this.endedOn,
    required this.metadata,
  });

  final String name;
  final String category;
  final num amount;
  final String currencyCode;
  final SubscriptionBillingCycle billingCycle;
  final DateTime nextBillingDate;
  final bool isActive;
  final String? accountId;
  final String? creditCardId;
  final int reminderDaysBefore;
  final DateTime? startedOn;
  final DateTime? endedOn;
  final Map<String, dynamic> metadata;
}

String _formatDate(DateTime value) {
  final local = DateTime(value.year, value.month, value.day);
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}/$month/$day';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}/$month/$day $hour:$minute';
}

String? _nullIfEmpty(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
