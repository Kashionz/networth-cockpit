import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/reminder_model.dart';
import '../../../core/notifications/reminder_settings_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../settings/widgets/settings_section.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reminderSettingsControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '提醒與推播',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Phase 1 使用不需第三方金鑰的提醒骨架。無法推播時會保留為應用內提醒。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SettingsSection(
                  title: '提醒項目',
                  children: [
                    for (final reminder in ReminderType.values) ...[
                      SwitchListTile(
                        value: state.enabledMap[reminder] ?? false,
                        onChanged: (enabled) {
                          ref
                              .read(reminderSettingsControllerProvider.notifier)
                              .setReminderEnabled(reminder, enabled);
                        },
                        title: Text(reminder.label),
                        subtitle: Text(reminder.description),
                      ),
                      if (reminder != ReminderType.values.last)
                        const Divider(height: 1),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SettingsSection(
                  title: '排程狀態',
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final result = await ref
                              .read(reminderSettingsControllerProvider.notifier)
                              .scheduleActiveReminders();

                          if (!context.mounted) {
                            return;
                          }

                          final status = result.usedFallback
                              ? '已排程提醒（目前為應用內 fallback）'
                              : '已排程推播提醒';
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(status)));
                        },
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: const Text('套用並排程提醒'),
                      ),
                    ),
                    if (state.lastScheduledAt != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '最近排程：${state.lastScheduledAt}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (state.lastMessages.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      for (final message in state.lastMessages)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.xxs,
                          ),
                          child: Text(
                            '• $message',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
