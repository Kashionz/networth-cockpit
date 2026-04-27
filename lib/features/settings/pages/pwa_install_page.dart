import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../widgets/settings_section.dart';

class PwaInstallPage extends StatelessWidget {
  const PwaInstallPage({super.key});

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
                  '安裝 App（PWA）',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '可將 NetWorth Cockpit 安裝到桌面或主畫面，取得更接近原生 App 的體驗。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SettingsSection(
                  title: '安裝步驟',
                  children: [
                    _InstallStep(
                      number: '1',
                      title: 'Chrome / Edge（桌面）',
                      description: '在網址列右側點選「安裝 App」圖示，並確認安裝。',
                    ),
                    Divider(height: 1),
                    _InstallStep(
                      number: '2',
                      title: 'Safari（iPhone / iPad）',
                      description: '點分享按鈕後選擇「加入主畫面」。',
                    ),
                    Divider(height: 1),
                    _InstallStep(
                      number: '3',
                      title: 'Android Chrome',
                      description: '開啟瀏覽器選單後，點選「安裝應用程式」。',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('若瀏覽器支援，請使用網址列或分享選單完成安裝。')),
                    );
                  },
                  icon: const Icon(Icons.download_for_offline_outlined),
                  label: const Text('顯示安裝提示'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstallStep extends StatelessWidget {
  const _InstallStep({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colorScheme.secondaryContainer,
            child: Text(
              number,
              style: TextStyle(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
