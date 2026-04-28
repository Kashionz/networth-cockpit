import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/notifications/push_notification_client.dart';
import '../../../core/notifications/reminder_model.dart';
import '../../../core/notifications/reminder_settings_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/rules/health_rule_projection.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../settings/widgets/settings_section.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  static final DateFormat _scheduleTimeFormat = DateFormat('yyyy/MM/dd HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reminderSettingsControllerProvider);
    final dashboardSnapshot = ref.watch(dashboardControllerProvider);
    final l1Conclusion = HealthRuleProjection.evaluateDashboardSnapshot(
      dashboardSnapshot,
    );
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
                  '已啟用平台推播（支援時），若權限未開啟或裝置不支援，會自動保留為應用內提醒。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SettingsSection(
                  title: '目前 L1 提示',
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.health_and_safety_outlined),
                      title: Text(l1Conclusion.title),
                      subtitle: Text(l1Conclusion.reason),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SettingsSection(
                  title: '提醒項目',
                  description: state.isHydrated ? null : '正在讀取你上次保存的提醒偏好...',
                  children: [
                    for (final reminder in ReminderType.values) ...[
                      SwitchListTile(
                        value: state.enabledMap[reminder] ?? false,
                        onChanged: state.isHydrated
                            ? (enabled) {
                                ref
                                    .read(
                                      reminderSettingsControllerProvider
                                          .notifier,
                                    )
                                    .setReminderEnabled(reminder, enabled);
                              }
                            : null,
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
                  description: '推播權限：${state.pushPermissionStatus.label}',
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: state.isHydrated
                            ? () async {
                                final result = await ref
                                    .read(
                                      reminderSettingsControllerProvider
                                          .notifier,
                                    )
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
                              }
                            : null,
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: const Text('套用並排程提醒'),
                      ),
                    ),
                    if (state.lastScheduledAt != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '最近排程：${_scheduleTimeFormat.format(state.lastScheduledAt!.toLocal())}',
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
