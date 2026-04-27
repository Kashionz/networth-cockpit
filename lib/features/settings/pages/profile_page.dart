import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/privacy/privacy_mode_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/theme_mode_picker.dart';
import 'risk_profile_page.dart';
import 'target_allocation_settings_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(privacyModeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '個人資料',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '調整帳戶偏好與個人設定。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SettingsSection(
                  title: '顯示偏好',
                  description: '常用設定集中在這裡，方便快速調整。',
                  children: [
                    ThemeModePicker(
                      value: themeMode,
                      onChanged: (mode) {
                        ref
                            .read(themeModeControllerProvider.notifier)
                            .setThemeMode(mode);
                      },
                    ),
                    const Divider(height: 1),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: SwitchListTile(
                        value: hidden,
                        onChanged: (value) {
                          ref
                              .read(privacyModeControllerProvider.notifier)
                              .setHidden(value);
                        },
                        title: const Text('隱私模式'),
                        subtitle: const Text('開啟後會即時遮罩所有金額，趨勢與比例仍可閱讀。'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SettingsSection(
                  title: '風險與配置',
                  children: [
                    SettingsTile(
                      icon: Icons.tune,
                      title: '風險屬性',
                      subtitle: '調整 L1-L5 的偏好區間與回顧頻率。',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const RiskProfilePage(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.donut_large,
                      title: '目標配置',
                      subtitle: '設定股票、債券、現金的參考比例。',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                const TargetAllocationSettingsPage(),
                          ),
                        );
                      },
                    ),
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
