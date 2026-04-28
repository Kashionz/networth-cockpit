import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pwa/pwa_install_client.dart';
import '../../../core/theme/app_spacing.dart';
import '../widgets/settings_section.dart';

class PwaInstallPage extends ConsumerStatefulWidget {
  const PwaInstallPage({super.key});

  @override
  ConsumerState<PwaInstallPage> createState() => _PwaInstallPageState();
}

class _PwaInstallPageState extends ConsumerState<PwaInstallPage> {
  late Future<PwaInstallStatus> _statusFuture;
  bool _isPromptingInstall = false;

  @override
  void initState() {
    super.initState();
    _statusFuture = _loadStatus();
  }

  Future<PwaInstallStatus> _loadStatus() {
    return ref.read(pwaInstallClientProvider).getStatus();
  }

  void _refreshStatus() {
    setState(() {
      _statusFuture = _loadStatus();
    });
  }

  Future<void> _promptInstall() async {
    if (_isPromptingInstall) {
      return;
    }

    setState(() => _isPromptingInstall = true);
    final result = await ref.read(pwaInstallClientProvider).promptInstall();
    if (!mounted) {
      return;
    }

    final message = switch (result.outcome) {
      PwaInstallPromptOutcome.accepted => '已送出安裝請求，請依瀏覽器提示完成安裝。',
      PwaInstallPromptOutcome.dismissed => '你已暫時取消安裝，可稍後再試一次。',
      PwaInstallPromptOutcome.unavailable => '目前無法直接觸發安裝，請改用手動安裝步驟。',
      PwaInstallPromptOutcome.error => '安裝提示觸發失敗，請稍後再試。',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    setState(() => _isPromptingInstall = false);
    _refreshStatus();
  }

  PwaInstallStatus _fallbackStatus() {
    return const PwaInstallStatus(
      availability: PwaInstallAvailability.manual,
      promptSupported: false,
      canPromptInstall: false,
      isInstalled: false,
    );
  }

  String _statusDescription(PwaInstallStatus status) {
    return switch (status.availability) {
      PwaInstallAvailability.installable => '目前環境支援安裝提示，可直接點擊「立即安裝」。',
      PwaInstallAvailability.manual => '目前無法直接叫出安裝提示，請使用下方手動安裝引導。',
      PwaInstallAvailability.installed => '目前已在此裝置安裝完成。',
    };
  }

  Color _statusColor(ColorScheme colorScheme, PwaInstallStatus status) {
    return switch (status.availability) {
      PwaInstallAvailability.installable => colorScheme.primary,
      PwaInstallAvailability.manual => colorScheme.tertiary,
      PwaInstallAvailability.installed => colorScheme.secondary,
    };
  }

  IconData _statusIcon(PwaInstallStatus status) {
    return switch (status.availability) {
      PwaInstallAvailability.installable => Icons.download_for_offline_outlined,
      PwaInstallAvailability.manual => Icons.touch_app_outlined,
      PwaInstallAvailability.installed => Icons.verified_outlined,
    };
  }

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
                FutureBuilder<PwaInstallStatus>(
                  future: _statusFuture,
                  builder: (context, snapshot) {
                    final status = snapshot.data ?? _fallbackStatus();
                    final statusColor = _statusColor(colorScheme, status);

                    return SettingsSection(
                      title: '目前狀態',
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            _statusIcon(status),
                            color: statusColor,
                          ),
                          title: Text(status.availability.label),
                          subtitle: Text(_statusDescription(status)),
                        ),
                        Text(
                          status.promptSupported
                              ? 'beforeinstallprompt 支援: 是'
                              : 'beforeinstallprompt 支援: 否',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            if (status.canPromptInstall)
                              FilledButton.icon(
                                onPressed: _isPromptingInstall
                                    ? null
                                    : _promptInstall,
                                icon: const Icon(
                                  Icons.download_for_offline_outlined,
                                ),
                                label: Text(
                                  _isPromptingInstall ? '安裝中...' : '立即安裝',
                                ),
                              ),
                            OutlinedButton.icon(
                              onPressed: _refreshStatus,
                              icon: const Icon(Icons.refresh_outlined),
                              label: const Text('重新檢查狀態'),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                const SettingsSection(
                  title: '安裝步驟',
                  children: [
                    _InstallStep(
                      number: '1',
                      title: 'Chrome / Edge（桌面）',
                      description: '可先嘗試點上方「立即安裝」，或使用網址列右側安裝圖示。',
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
