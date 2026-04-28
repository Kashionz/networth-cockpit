import 'package:flutter/material.dart';

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
    final style = _styleFor(context, tone);
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
                        color: style.foreground,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: style.foreground.withValues(alpha: 0.84),
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
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
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

  _HealthAlertStyle _styleFor(BuildContext context, HealthAlertTone tone) {
    final colorScheme = Theme.of(context).colorScheme;

    return switch (tone) {
      HealthAlertTone.structural => _HealthAlertStyle(
        background: colorScheme.surfaceContainerLow,
        border: colorScheme.outlineVariant,
        foreground: colorScheme.onSurfaceVariant,
        icon: Icons.account_tree_outlined,
      ),
      HealthAlertTone.review => _HealthAlertStyle(
        background: colorScheme.tertiaryContainer,
        border: colorScheme.tertiary.withValues(alpha: 0.45),
        foreground: colorScheme.onTertiaryContainer,
        icon: Icons.tune,
      ),
      HealthAlertTone.educational => _HealthAlertStyle(
        background: colorScheme.primaryContainer,
        border: colorScheme.primary.withValues(alpha: 0.45),
        foreground: colorScheme.onPrimaryContainer,
        icon: Icons.school_outlined,
      ),
      HealthAlertTone.info => _HealthAlertStyle(
        background: colorScheme.secondaryContainer,
        border: colorScheme.secondary.withValues(alpha: 0.45),
        foreground: colorScheme.onSecondaryContainer,
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
