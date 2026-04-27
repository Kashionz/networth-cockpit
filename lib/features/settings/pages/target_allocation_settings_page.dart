import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../widgets/settings_section.dart';

class TargetAllocationSettingsPage extends StatefulWidget {
  const TargetAllocationSettingsPage({super.key});

  @override
  State<TargetAllocationSettingsPage> createState() =>
      _TargetAllocationSettingsPageState();
}

class _TargetAllocationSettingsPageState
    extends State<TargetAllocationSettingsPage> {
  double _equityWeight = 0.6;
  double _bondWeight = 0.25;

  double get _cashWeight => (1 - _equityWeight - _bondWeight).clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('目標配置')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SettingsSection(
                title: '配置比例',
                description: '調整後可作為每月檢視時的參考目標。',
                children: [
                  _WeightSlider(
                    label: '股票',
                    value: _equityWeight,
                    color: AppColors.assetEquity,
                    onChanged: (value) {
                      final maxAllowed = 1 - _bondWeight;
                      setState(
                        () => _equityWeight = value.clamp(0, maxAllowed),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _WeightSlider(
                    label: '債券',
                    value: _bondWeight,
                    color: AppColors.assetBond,
                    onChanged: (value) {
                      final maxAllowed = 1 - _equityWeight;
                      setState(() => _bondWeight = value.clamp(0, maxAllowed));
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _WeightReadOnly(
                    label: '現金',
                    value: _cashWeight,
                    color: AppColors.assetCash,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 160,
                      child: PrimaryButton(
                        label: '儲存配置',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已更新目標配置')),
                          );
                        },
                      ),
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

class _WeightSlider extends StatelessWidget {
  const _WeightSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 44, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 1,
            divisions: 20,
            activeColor: color,
            label: '${(value * 100).toStringAsFixed(0)}%',
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 54,
          child: Text(
            '${(value * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }
}

class _WeightReadOnly extends StatelessWidget {
  const _WeightReadOnly({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 44, child: Text(label)),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: color.withAlpha(64),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 42,
          child: Text(
            '${(value * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }
}
