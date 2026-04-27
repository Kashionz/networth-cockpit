import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../widgets/settings_section.dart';

class RiskProfilePage extends StatefulWidget {
  const RiskProfilePage({super.key});

  @override
  State<RiskProfilePage> createState() => _RiskProfilePageState();
}

class _RiskProfilePageState extends State<RiskProfilePage> {
  double _riskLevel = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('風險屬性')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SettingsSection(
                title: '目前偏好',
                description: '可依照睡眠品質與投資期限調整，之後仍可再修改。',
                children: [
                  Text(
                    'L${_riskLevel.round()}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Slider(
                    value: _riskLevel,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: 'L${_riskLevel.round()}',
                    onChanged: (value) => setState(() => _riskLevel = value),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '目前建議：以分散配置為主，維持固定檢視頻率。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 160,
                      child: PrimaryButton(
                        label: '儲存偏好',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已更新風險屬性設定')),
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
