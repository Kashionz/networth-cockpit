import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

enum HealthAlertTone { structural, review, educational, info }

class HealthAlertCard extends StatelessWidget {
  const HealthAlertCard({
    required this.tone,
    required this.title,
    required this.body,
    this.primaryActionLabel = '檢視',
    this.secondaryActionLabel = '稍後',
    this.onPrimaryAction,
    this.onSecondaryAction,
    super.key,
  });

  final HealthAlertTone tone;
  final String title;
  final String body;
  final String primaryActionLabel;
  final String? secondaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(tone);
    final hasPrimaryAction = onPrimaryAction != null;
    final hasSecondaryAction =
        onSecondaryAction != null && secondaryActionLabel != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: style.background,
        border: Border.all(color: style.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(style.icon, size: 20, color: style.foreground),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasPrimaryAction || hasSecondaryAction) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (hasPrimaryAction)
                  TextButton(
                    onPressed: onPrimaryAction,
                    style: TextButton.styleFrom(
                      foregroundColor: style.foreground,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(primaryActionLabel),
                  ),
                if (hasSecondaryAction)
                  TextButton(
                    onPressed: onSecondaryAction,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textTertiary,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(secondaryActionLabel!),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  _HealthAlertStyle _styleFor(HealthAlertTone tone) {
    return switch (tone) {
      HealthAlertTone.structural => const _HealthAlertStyle(
        background: AppColors.surfaceMuted,
        border: AppColors.line,
        foreground: AppColors.budgetFixed,
        icon: Icons.account_tree_outlined,
      ),
      HealthAlertTone.review => const _HealthAlertStyle(
        background: Color(0xFFF4F1F7),
        border: Color(0xFFD8D0E2),
        foreground: AppColors.review,
        icon: Icons.tune,
      ),
      HealthAlertTone.educational => const _HealthAlertStyle(
        background: Color(0xFFF7F3EA),
        border: Color(0xFFE3D4B8),
        foreground: AppColors.near,
        icon: Icons.school_outlined,
      ),
      HealthAlertTone.info => const _HealthAlertStyle(
        background: AppColors.accentMuted,
        border: AppColors.accentEdge,
        foreground: AppColors.accent,
        icon: Icons.info_outline,
      ),
    };
  }
}

class _HealthAlertStyle {
  const _HealthAlertStyle({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;
}
