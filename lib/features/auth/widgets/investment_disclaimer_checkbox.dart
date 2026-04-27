import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class InvestmentDisclaimerCheckbox extends StatelessWidget {
  const InvestmentDisclaimerCheckbox({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(value: value, onChanged: (next) => onChanged(next ?? false)),
        const SizedBox(width: AppSpacing.xs),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              '我了解本服務不提供投資建議',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
