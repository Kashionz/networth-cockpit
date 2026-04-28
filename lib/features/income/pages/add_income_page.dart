import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/forms/app_select_field.dart';
import '../../../shared/widgets/forms/app_text_field.dart';
import '../controllers/income_controller.dart';
import '../models/income_stream.dart';

class AddIncomePage extends ConsumerStatefulWidget {
  const AddIncomePage({super.key, this.initialStream});

  final IncomeStream? initialStream;

  @override
  ConsumerState<AddIncomePage> createState() => _AddIncomePageState();
}

class _AddIncomePageState extends ConsumerState<AddIncomePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  late IncomeFrequency _selectedFrequency;
  late DateTime _selectedDate;
  bool _isSaving = false;

  bool get _isEditing => widget.initialStream != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialStream;
    _nameController.text = initial?.name ?? '';
    _amountController.text = initial?.amount.toString() ?? '';
    _selectedFrequency = initial?.frequency ?? IncomeFrequency.monthly;
    _selectedDate = initial?.nextDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
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
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    final now = DateTime.now().toUtc();
    final amount = num.parse(_amountController.text.replaceAll(',', '').trim());
    final initial = widget.initialStream;
    final stream =
        (initial ??
                IncomeStream(
                  id: _generatePseudoUuid(),
                  userId: '',
                  name: '',
                  amount: 0,
                  frequency: IncomeFrequency.monthly,
                  nextDate: now,
                  active: true,
                  createdAt: now,
                  updatedAt: now,
                ))
            .copyWith(
              name: _nameController.text.trim(),
              amount: amount,
              frequency: _selectedFrequency,
              nextDate: DateTime.utc(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
              ),
              updatedAt: now,
            );

    await ref.read(incomeControllerProvider.notifier).upsert(stream);
    if (!mounted) {
      return;
    }

    final latest = ref.read(incomeControllerProvider);
    if (latest.hasError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('儲存失敗，請稍後再試')));
      setState(() => _isSaving = false);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_isEditing ? '已更新收入來源' : '已新增收入來源')));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                _isEditing ? '編輯收入來源' : '新增收入來源',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '輸入名稱、金額與頻率，後續可再調整。金額預設以新台幣估算。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      label: '收入名稱',
                      controller: _nameController,
                      hintText: '例如：薪資、租金收入',
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '請輸入收入名稱';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: '金額',
                      controller: _amountController,
                      hintText: '例如：50000',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        final amount = num.tryParse(
                          value?.replaceAll(',', '').trim() ?? '',
                        );
                        if (amount == null || amount <= 0) {
                          return '請輸入大於 0 的金額';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppSelectField<IncomeFrequency>(
                      label: '頻率',
                      value: _selectedFrequency,
                      items: const [
                        AppSelectFieldItem(
                          value: IncomeFrequency.monthly,
                          label: '每月',
                        ),
                        AppSelectFieldItem(
                          value: IncomeFrequency.yearly,
                          label: '每年',
                        ),
                        AppSelectFieldItem(
                          value: IncomeFrequency.oneTime,
                          label: '一次性',
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedFrequency = value);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DateInputTile(date: _selectedDate, onTap: _pickDate),
                    const SizedBox(height: AppSpacing.lg),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () {
                                _submit();
                              },
                        icon: _isSaving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(_isEditing ? '更新收入' : '建立收入'),
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
          '下次生效日',
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

String _generatePseudoUuid() {
  final seed = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  final normalized = (seed * 3).padRight(32, '0').substring(0, 32);
  return '${normalized.substring(0, 8)}-'
      '${normalized.substring(8, 12)}-'
      '4${normalized.substring(13, 16)}-'
      'a${normalized.substring(17, 20)}-'
      '${normalized.substring(20, 32)}';
}

String _formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year/$month/$day';
}
