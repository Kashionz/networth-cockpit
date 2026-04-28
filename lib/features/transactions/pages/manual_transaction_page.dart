import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/forms/app_select_field.dart';
import '../../../shared/widgets/forms/app_text_field.dart';
import '../controllers/transactions_controller.dart';

class ManualTransactionPage extends ConsumerStatefulWidget {
  const ManualTransactionPage({super.key});

  @override
  ConsumerState<ManualTransactionPage> createState() =>
      _ManualTransactionPageState();
}

class _ManualTransactionPageState extends ConsumerState<ManualTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late DateTime _selectedDate;
  String? _selectedCategory;
  String? _selectedSourceAccount;

  @override
  void initState() {
    super.initState();
    final state = ref.read(transactionsControllerProvider);
    _selectedDate = DateTime.now();
    _selectedCategory = state.categoryOptions.first;
    _selectedSourceAccount = state.lastUsedSourceAccount;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = num.parse(_amountController.text.trim());
    await ref
        .read(transactionsControllerProvider.notifier)
        .addManualRecord(
          amount: amount,
          date: _selectedDate,
          category: _selectedCategory!,
          sourceAccount: _selectedSourceAccount!,
          note: _noteController.text,
        );

    if (!mounted) {
      return;
    }

    final updatedState = ref.read(transactionsControllerProvider);
    setState(() {
      _amountController.clear();
      _noteController.clear();
      _selectedSourceAccount = updatedState.lastUsedSourceAccount;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已加入手動交易紀錄')));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsControllerProvider);
    final sourceAccounts = state.sourceAccounts;
    if (_selectedSourceAccount == null ||
        !sourceAccounts.contains(_selectedSourceAccount)) {
      _selectedSourceAccount = state.lastUsedSourceAccount;
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                '手動記錄大額支出',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '30 秒內完成一筆：先填金額與來源，其餘欄位保留常用預設。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    '小額現金支出可以先略過，不需要強迫每筆都手動輸入。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      label: '金額',
                      controller: _amountController,
                      hintText: '例如：6800',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        final amount = num.tryParse(value?.trim() ?? '');
                        if (amount == null || amount <= 0) {
                          return '請輸入大於 0 的金額';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DateInputTile(date: _selectedDate, onTap: _pickDate),
                    const SizedBox(height: AppSpacing.md),
                    AppSelectField<String>(
                      label: '類別',
                      value: _selectedCategory,
                      items: [
                        for (final category in state.categoryOptions)
                          AppSelectFieldItem(value: category, label: category),
                      ],
                      onChanged: (category) {
                        if (category != null) {
                          setState(() => _selectedCategory = category);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppSelectField<String>(
                      label: '來源帳戶',
                      value: _selectedSourceAccount,
                      helperText: '預設沿用上次使用的帳戶',
                      items: [
                        for (final account in sourceAccounts)
                          AppSelectFieldItem(value: account, label: account),
                      ],
                      onChanged: (account) {
                        if (account != null) {
                          setState(() => _selectedSourceAccount = account);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: '備註',
                      controller: _noteController,
                      hintText: '可選填，例如用途或商家',
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () {
                          _submit();
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('30 秒快速記錄'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateInputTile extends StatelessWidget {
  const _DateInputTile({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '日期',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(_formatDate(date)),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
