import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({this.text = '本資訊僅供參考,不構成投資建議', super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
