import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/privacy/privacy_mode_provider.dart';
import '../../../core/routing/route_paths.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_mode_provider.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                RepaintBoundary(child: _DesktopSidebar(location: location)),
                Expanded(child: RepaintBoundary(child: child)),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('NetWorth Cockpit'),
            actions: const [_ThemeIconButton(), _PrivacyIconButton()],
          ),
          body: RepaintBoundary(child: child),
          bottomNavigationBar: _MobileBottomNav(location: location),
        );
      },
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 244,
      color: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BrandHeader(),
            const SizedBox(height: AppSpacing.lg),
            for (final item in _navItems)
              _NavButton(item: item, selected: _matches(location, item.path)),
            const Spacer(),
            const _ThemeSwitchTile(),
            const SizedBox(height: AppSpacing.sm),
            const _PrivacyIconButton(expanded: true),
          ],
        ),
      ),
    );
  }
}

class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _mobileItems.indexWhere(
      (item) => _matches(location, item.path),
    );
    final effectiveIndex = selectedIndex < 0 ? 0 : selectedIndex;

    return NavigationBar(
      selectedIndex: effectiveIndex,
      onDestinationSelected: (index) {
        if (index == effectiveIndex) {
          return;
        }
        context.go(_mobileItems[index].path);
      },
      destinations: [
        for (final item in _mobileItems)
          NavigationDestination(icon: Icon(item.icon), label: item.label),
      ],
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'N',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NetWorth Cockpit',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                '淨值駕駛艙',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.selected});

  final _NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: TextButton.icon(
        onPressed: selected ? null : () => context.go(item.path),
        icon: Icon(item.icon, size: 18),
        label: Align(alignment: Alignment.centerLeft, child: Text(item.label)),
        style: TextButton.styleFrom(
          foregroundColor: selected
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant,
          backgroundColor: selected
              ? colorScheme.surfaceContainerHighest
              : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    );
  }
}

class _ThemeIconButton extends ConsumerWidget {
  const _ThemeIconButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = _isDarkMode(themeMode, Theme.of(context).brightness);
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: isDark ? '切換為亮色模式' : '切換為暗色模式',
      onPressed: () {
        ref
            .read(themeModeControllerProvider.notifier)
            .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
      },
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _ThemeSwitchTile extends ConsumerWidget {
  const _ThemeSwitchTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = _isDarkMode(themeMode, Theme.of(context).brightness);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              '暗色模式',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (value) {
              ref
                  .read(themeModeControllerProvider.notifier)
                  .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
          ),
        ],
      ),
    );
  }
}

class _PrivacyIconButton extends ConsumerWidget {
  const _PrivacyIconButton({this.expanded = false});

  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(privacyModeProvider);
    final label = hidden ? '顯示金額' : '隱藏金額';
    return expanded
        ? OutlinedButton.icon(
            onPressed: () {
              ref.read(privacyModeControllerProvider.notifier).toggle();
            },
            icon: Icon(hidden ? Icons.visibility_off : Icons.visibility),
            label: Text(label),
          )
        : IconButton(
            tooltip: label,
            onPressed: () {
              ref.read(privacyModeControllerProvider.notifier).toggle();
            },
            icon: Icon(hidden ? Icons.visibility_off : Icons.visibility),
          );
  }
}

bool _isDarkMode(ThemeMode mode, Brightness brightness) {
  if (mode == ThemeMode.dark) {
    return true;
  }
  if (mode == ThemeMode.light) {
    return false;
  }
  return brightness == Brightness.dark;
}

class _NavItem {
  const _NavItem(this.label, this.path, this.icon);

  final String label;
  final String path;
  final IconData icon;
}

const _navItems = [
  _NavItem('總覽', RoutePaths.dashboard, Icons.dashboard_outlined),
  _NavItem('帳單匯入', RoutePaths.transactionsImport, Icons.upload_file),
  _NavItem('收入', RoutePaths.income, Icons.account_balance_wallet_outlined),
  _NavItem('訂閱', RoutePaths.subscriptions, Icons.subscriptions_outlined),
  _NavItem('預算', RoutePaths.budget, Icons.account_balance_wallet_outlined),
  _NavItem('配置', RoutePaths.portfolioAllocation, Icons.donut_large),
  _NavItem('隱私', RoutePaths.settingsPrivacy, Icons.privacy_tip_outlined),
];

const _mobileItems = [
  _NavItem('總覽', RoutePaths.dashboard, Icons.dashboard_outlined),
  _NavItem('收入', RoutePaths.income, Icons.account_balance_wallet_outlined),
  _NavItem('訂閱', RoutePaths.subscriptions, Icons.subscriptions_outlined),
  _NavItem('預算', RoutePaths.budget, Icons.account_balance_wallet_outlined),
  _NavItem('報告', RoutePaths.insights, Icons.insights_outlined),
  _NavItem('隱私', RoutePaths.settingsPrivacy, Icons.privacy_tip_outlined),
];

bool _matches(String location, String path) {
  if (path == RoutePaths.dashboard) {
    return location == RoutePaths.dashboard;
  }
  if (path == RoutePaths.settingsPrivacy) {
    return location.startsWith('/settings');
  }
  return location.startsWith(path);
}
