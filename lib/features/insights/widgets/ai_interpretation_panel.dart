import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class AiInterpretationPanel extends StatelessWidget {
  const AiInterpretationPanel({
    required this.lines,
    this.sourceLabel,
    this.statusMessage,
    super.key,
  });

  final List<String> lines;
  final String? sourceLabel;
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI 解讀',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final line in lines) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(
                    child: Text(
                      line,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            if (sourceLabel != null) ...[
              const Divider(height: 20),
              Text(
                '資料來源：$sourceLabel',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                  letterSpacing: 0,
                ),
              ),
              if (statusMessage != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  statusMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ],
            const Divider(height: 20),
            Text(
              'AI 解讀不構成投資建議',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
