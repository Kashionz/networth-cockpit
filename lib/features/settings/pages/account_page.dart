import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/routing/route_paths.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/account_lifecycle_repository.dart';
import '../../../data/repositories/job_runner_repository.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  late final AccountLifecycleRepository _accountLifecycleRepository;
  late final JobRunnerRepository _jobRunnerRepository;

  late AccountDeletionLifecycle _lifecycle;
  List<JobRun> _jobRuns = const <JobRun>[];

  bool _isSubmittingLifecycleAction = false;
  JobKind? _runningJobKind;
  final Set<String> _retryingRunIds = <String>{};

  @override
  void initState() {
    super.initState();
    _accountLifecycleRepository = ref.read(accountLifecycleRepositoryProvider);
    _jobRunnerRepository = ref.read(jobRunnerRepositoryProvider);
    _lifecycle = _accountLifecycleRepository.getStatus();
    _jobRuns = _jobRunnerRepository.getRuns();
  }

  void _requestDeletion() {
    if (_isSubmittingLifecycleAction) {
      return;
    }

    setState(() => _isSubmittingLifecycleAction = true);
    final next = _accountLifecycleRepository.requestDeletion();
    if (!mounted) {
      return;
    }
    setState(() {
      _lifecycle = next;
      _isSubmittingLifecycleAction = false;
    });

    final expiresText = next.expiresAt == null
        ? ''
        : '，到期日 ${_dateTimeFormat.format(next.expiresAt!.toLocal())}';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已送出刪除申請$expiresText')));
  }

  void _cancelDeletion() {
    if (_isSubmittingLifecycleAction) {
      return;
    }

    setState(() => _isSubmittingLifecycleAction = true);
    final next = _accountLifecycleRepository.cancelDeletion();
    if (!mounted) {
      return;
    }
    setState(() {
      _lifecycle = next;
      _isSubmittingLifecycleAction = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已取消刪除申請')));
  }

  Future<void> _triggerJob(JobKind kind) async {
    if (_runningJobKind != null) {
      return;
    }

    setState(() => _runningJobKind = kind);
    try {
      final run = await _jobRunnerRepository.trigger(kind);
      if (!mounted) {
        return;
      }
      setState(() => _jobRuns = _jobRunnerRepository.getRuns());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${run.kind.code} 已完成，狀態：${run.status.label}（重試 ${run.retryCount} 次）',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('觸發 ${kind.code} 失敗：$error')));
    } finally {
      if (mounted) {
        setState(() => _runningJobKind = null);
      }
    }
  }

  Future<void> _retryFailedRun(JobRun run) async {
    if (_retryingRunIds.contains(run.id)) {
      return;
    }

    setState(() => _retryingRunIds.add(run.id));
    try {
      final retryRun = await _jobRunnerRepository.retry(run.id);
      if (!mounted) {
        return;
      }
      setState(() => _jobRuns = _jobRunnerRepository.getRuns());
      if (retryRun == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('此 job 目前不需重試或已非失敗狀態')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '已建立重試 run：${retryRun.kind.code} -> ${retryRun.status.label}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _retryingRunIds.remove(run.id));
      }
    }
  }

  static final DateFormat _dateTimeFormat = DateFormat('yyyy/MM/dd HH:mm');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final remainingLabel = _buildRemainingLabel(_lifecycle);

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
                  description: '可申請刪除並保留 30 天緩衝期，期間可取消。',
                  children: [
                    Row(
                      children: [
                        Icon(
                          _statusIcon(_lifecycle.status),
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '目前狀態：${_lifecycle.status.label}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (_lifecycle.expiresAt != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '到期日：${_dateTimeFormat.format(_lifecycle.expiresAt!.toLocal())}'
                        '${remainingLabel.isEmpty ? '' : '（$remainingLabel）'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (_lifecycle.cancelledAt != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '取消時間：${_dateTimeFormat.format(_lifecycle.cancelledAt!.toLocal())}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isSubmittingLifecycleAction
                              ? null
                              : _requestDeletion,
                          icon: const Icon(Icons.person_remove_outlined, size: 18),
                          label: const Text('申請刪除'),
                        ),
                        TextButton.icon(
                          onPressed:
                              _isSubmittingLifecycleAction || !_lifecycle.isPending
                              ? null
                              : _cancelDeletion,
                          icon: const Icon(Icons.undo_outlined, size: 18),
                          label: const Text('取消刪除'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '狀態追蹤',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (_lifecycle.events.isEmpty)
                      Text(
                        '尚無流程事件。',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      for (final event in _lifecycle.events.take(6)) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.history, size: 16),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                '${event.type.label}｜'
                                '${_dateTimeFormat.format(event.createdAt.toLocal())}\n'
                                '${event.note}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SettingsSection(
                  title: '排程骨架',
                  description:
                      '可手動觸發 update_prices / daily_snapshot / monthly_report / health_check / subscription_charge / statement_close，並寫入 job_runs（含重試記錄）。',
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final kind in JobKind.values)
                          OutlinedButton.icon(
                            onPressed: _runningJobKind == null
                                ? () {
                                    _triggerJob(kind);
                                  }
                                : null,
                            icon: const Icon(Icons.play_circle_outline, size: 18),
                            label: Text(kind.code),
                          ),
                      ],
                    ),
                    if (_runningJobKind != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '執行中：${_runningJobKind!.code}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.sm),
                    if (_jobRuns.isEmpty)
                      Text(
                        '尚無 job_runs 紀錄。',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      for (var index = 0; index < _jobRuns.length; index++) ...[
                        _JobRunTile(
                          run: _jobRuns[index],
                          dateTimeFormat: _dateTimeFormat,
                          retrying: _retryingRunIds.contains(_jobRuns[index].id),
                          onRetry: () {
                            _retryFailedRun(_jobRuns[index]);
                          },
                        ),
                        if (index != _jobRuns.length - 1)
                          const Divider(height: AppSpacing.lg),
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

  IconData _statusIcon(AccountDeletionStatus status) {
    return switch (status) {
      AccountDeletionStatus.none => Icons.person_outline,
      AccountDeletionStatus.pending => Icons.hourglass_bottom_outlined,
      AccountDeletionStatus.cancelled => Icons.undo_outlined,
      AccountDeletionStatus.expired => Icons.event_busy_outlined,
    };
  }

  String _buildRemainingLabel(AccountDeletionLifecycle lifecycle) {
    if (!lifecycle.isPending || lifecycle.expiresAt == null) {
      return '';
    }
    final now = DateTime.now().toUtc();
    final remaining = lifecycle.expiresAt!.difference(now).inDays;
    if (remaining <= 0) {
      return '今日到期';
    }
    return '剩餘 ${remaining + 1} 天';
  }
}

class _JobRunTile extends StatelessWidget {
  const _JobRunTile({
    required this.run,
    required this.dateTimeFormat,
    required this.retrying,
    required this.onRetry,
  });

  final JobRun run;
  final DateFormat dateTimeFormat;
  final bool retrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = run.status == JobRunStatus.succeeded
        ? Colors.green.shade700
        : colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${run.kind.code} • ${run.status.label}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Icon(Icons.circle, size: 10, color: statusColor),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'requested: ${dateTimeFormat.format(run.requestedAt.toLocal())}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          'attempts: ${run.attempts.length}（retry: ${run.retryCount}）',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (run.retryOfRunId != null)
          Text(
            'retry_of: ${run.retryOfRunId}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: AppSpacing.xs),
        for (final attempt in run.attempts) ...[
          Text(
            '#${attempt.attempt} ${attempt.success ? 'OK' : 'FAIL'} - ${attempt.message}'
            ' (${dateTimeFormat.format(attempt.finishedAt.toLocal())})',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xxs),
        ],
        if (run.status == JobRunStatus.failed)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: retrying ? null : onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(retrying ? '重試中...' : '重試此 run'),
            ),
          ),
      ],
    );
  }
}
