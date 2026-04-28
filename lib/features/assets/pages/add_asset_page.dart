import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/money.dart';
import '../../../shared/widgets/forms/app_select_field.dart';
import '../../../shared/widgets/forms/app_text_field.dart';
import '../controllers/assets_controller.dart';
import '../models/asset_type.dart';

class AddAssetPage extends ConsumerStatefulWidget {
  const AddAssetPage({super.key});

  @override
  ConsumerState<AddAssetPage> createState() => _AddAssetPageState();
}

class _AddAssetPageState extends ConsumerState<AddAssetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  AssetType _selectedType = AssetType.cash;

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = num.parse(_valueController.text.replaceAll(',', '').trim());
    await ref
        .read(assetsControllerProvider.notifier)
        .addAsset(
          name: _nameController.text.trim(),
          type: _selectedType,
          value: Money.twd(amount),
        );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已新增資產')));
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go(RoutePaths.assets);
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
                '新增資產',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '先填寫名稱、類型與估值，之後仍可調整。',
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
                      label: '資產名稱',
                      controller: _nameController,
                      hintText: '例如：0050 ETF、台幣活存',
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '請輸入資產名稱';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppSelectField<AssetType>(
                      label: '資產類別',
                      value: _selectedType,
                      items: [
                        for (final type in AssetType.values)
                          AppSelectFieldItem(value: type, label: type.label),
                      ],
                      onChanged: (type) {
                        if (type != null) {
                          setState(() => _selectedType = type);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: '目前估值',
                      controller: _valueController,
                      hintText: '例如：250000',
                      helperText: '單位為新台幣（NT\$）',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                    const SizedBox(height: AppSpacing.lg),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () {
                          _submit();
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('建立資產'),
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
