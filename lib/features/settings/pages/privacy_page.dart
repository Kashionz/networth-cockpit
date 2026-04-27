import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/privacy/privacy_mode_provider.dart';
import '../../../core/routing/route_paths.dart';
import '../../../core/theme/app_spacing.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class PrivacyPage extends ConsumerWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(privacyModeProvider);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          SettingsSection(
            title: '隱私',
            children: [
              SwitchListTile(
                value: hidden,
                onChanged: (value) {
                  ref
                      .read(privacyModeControllerProvider.notifier)
                      .setHidden(value);
                },
                title: const Text('隱私模式'),
                subtitle: const Text('開啟後所有金額會以 ¥¥¥¥¥ 顯示,比例與趨勢仍保留。'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsSection(
            title: '更多設定',
            children: [
              SettingsTile(
                icon: Icons.manage_accounts_outlined,
                title: '帳號設定',
                subtitle: '查看條款、提醒與 PWA 安裝引導。',
                onTap: () => context.go(RoutePaths.settingsAccount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
