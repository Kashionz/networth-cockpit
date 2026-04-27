import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({this.text = '本資訊僅供參考,不構成投資建議', super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentMuted,
        border: Border.all(color: AppColors.accentEdge),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
