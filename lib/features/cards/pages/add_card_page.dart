import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/forms/app_text_field.dart';
import '../controllers/cards_controller.dart';

class AddCardPage extends ConsumerStatefulWidget {
  const AddCardPage({super.key});

  @override
  ConsumerState<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends ConsumerState<AddCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastFourDigitsController = TextEditingController();
  final _amountController = TextEditingController();
  final _statementDayController = TextEditingController(text: '18');
  final _dueDayController = TextEditingController(text: '5');

  @override
  void dispose() {
    _nameController.dispose();
    _lastFourDigitsController.dispose();
    _amountController.dispose();
    _statementDayController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(cardsControllerProvider.notifier)
        .addCard(
          displayName: _nameController.text.trim(),
          statementAmount: num.parse(_amountController.text.trim()),
          statementDay: int.parse(_statementDayController.text.trim()),
          dueDay: int.parse(_dueDayController.text.trim()),
          lastFourDigits: _lastFourDigitsController.text.trim().isEmpty
              ? null
              : _lastFourDigitsController.text.trim(),
        );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已新增信用卡')));

    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go(RoutePaths.cards);
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
                '新增信用卡',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '建立卡片後即可快速進入帳單匯入流程。',
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
                      label: '卡片名稱',
                      controller: _nameController,
                      hintText: '例如：國泰 CUBE',
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '請輸入卡片名稱';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: '卡號末四碼（選填）',
                      controller: _lastFourDigitsController,
                      hintText: '例如：1024',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        final cleaned = value.trim();
                        if (cleaned.length != 4 ||
                            int.tryParse(cleaned) == null) {
                          return '請輸入 4 位數字';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: '本期帳單金額',
                      controller: _amountController,
                      hintText: '例如：12860',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        final amount = num.tryParse(value?.trim() ?? '');
                        if (amount == null || amount < 0) {
                          return '請輸入有效金額';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: '結帳日',
                            controller: _statementDayController,
                            keyboardType: TextInputType.number,
                            validator: _validateMonthDay,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppTextField(
                            label: '繳款日',
                            controller: _dueDayController,
                            keyboardType: TextInputType.number,
                            validator: _validateMonthDay,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () {
                          _submit();
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('建立卡片'),
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

String? _validateMonthDay(String? value) {
  final day = int.tryParse(value?.trim() ?? '');
  if (day == null || day < 1 || day > 31) {
    return '請輸入 1 到 31';
  }
  return null;
}
