import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_paths.dart';
import '../../../core/theme/app_spacing.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                  '帳號設定',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '管理登入方式與資料保留偏好。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SettingsSection(
                  title: '條款與政策',
                  children: [
                    SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: '隱私政策',
                      subtitle: '查看資料使用與保存方式。',
                      onTap: () => context.go(RoutePaths.legalPrivacy),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.description_outlined,
                      title: '使用者條款',
                      subtitle: '了解服務範圍與責任界線。',
                      onTap: () => context.go(RoutePaths.legalTerms),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.auto_awesome_outlined,
                      title: 'AI 解讀模板',
                      subtitle: '查看 AI 解讀揭露與標準模板。',
                      onTap: () => context.go(RoutePaths.legalAiTemplate),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SettingsSection(
                  title: '提醒與安裝',
                  description: '管理推播提醒與安裝到桌面/主畫面的體驗。',
                  children: [
                    SettingsTile(
                      icon: Icons.notifications_active_outlined,
                      title: '提醒與推播',
                      subtitle: '設定帳單、月底回顧與配置偏離提醒。',
                      onTap: () => context.go(RoutePaths.settingsNotifications),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.download_for_offline_outlined,
                      title: '安裝 App（PWA）',
                      subtitle: '查看桌面與手機安裝引導。',
                      onTap: () => context.go(RoutePaths.settingsPwaInstall),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SettingsSection(
                  title: '帳號刪除',
                  description: '若暫時不需要此服務,可先匯出資料後再申請刪除。',
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已送出刪除申請確認流程')),
                        );
                      },
                      icon: const Icon(Icons.person_remove_outlined, size: 18),
                      label: const Text('刪除帳號'),
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
