import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/account_lifecycle_repository.dart';
import '../../../data/repositories/job_runner_repository.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../widgets/settings_section.dart';

class RiskProfilePage extends ConsumerStatefulWidget {
  const RiskProfilePage({super.key});

  @override
  ConsumerState<RiskProfilePage> createState() => _RiskProfilePageState();
}

class _RiskProfilePageState extends ConsumerState<RiskProfilePage> {
  static final DateFormat _dateFormat = DateFormat('yyyy/MM/dd');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy/MM/dd HH:mm');

  late final AccountLifecycleRepository _accountLifecycleRepository;
  late final JobRunnerRepository _jobRunnerRepository;
  late RiskReassessmentLifecycle _riskLifecycle;

  final TextEditingController _majorEventController = TextEditingController();
  double _riskLevel = 3;

  @override
  void initState() {
    super.initState();
    _accountLifecycleRepository = ref.read(accountLifecycleRepositoryProvider);
    _jobRunnerRepository = ref.read(jobRunnerRepositoryProvider);
    _riskLifecycle = _accountLifecycleRepository.getRiskReassessmentStatus();
    _riskLevel = _riskLifecycle.riskPreferenceLevel;
  }

  @override
  void dispose() {
    _majorEventController.dispose();
    super.dispose();
  }

  void _refreshRiskLifecycle() {
    final next = _accountLifecycleRepository.getRiskReassessmentStatus();
    setState(() {
      _riskLifecycle = next;
      _riskLevel = next.riskPreferenceLevel;
    });
  }

  void _saveRiskPreference() {
    final next = _accountLifecycleRepository.updateRiskPreferenceLevel(
      _riskLevel,
    );
    setState(() => _riskLifecycle = next);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已更新風險屬性設定')));
  }

  void _createMajorEventTask() {
    final reason = _majorEventController.text.trim();
    final next = _accountLifecycleRepository.triggerMajorEventReassessment(
      note: reason,
    );
    _majorEventController.clear();
    setState(() => _riskLifecycle = next);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已建立重大事件再評估任務')));
  }

  void _completeTask(RiskReassessmentTask task) {
    final next = _accountLifecycleRepository.completeRiskReassessmentTask(
      taskId: task.id,
      note: '已完成風險問卷再評估',
    );
    setState(() => _riskLifecycle = next);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已更新任務完成狀態')));
  }

  @override
  Widget build(BuildContext context) {
    final latestFailure = _jobRunnerRepository.latestUnacknowledgedFailure();
    final nextAnnualDueAt = _riskLifecycle.nextAnnualDueAt;
    final riskTasks = _riskLifecycle.tasks.take(6).toList(growable: false);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('風險屬性')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SettingsSection(
                title: '目前偏好',
                description: '可依照睡眠品質與投資期限調整，之後仍可再修改。',
                children: [
                  if (latestFailure != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: colorScheme.error),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              '最近排程異常：${latestFailure.kind.code}（${latestFailure.message}）',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _jobRunnerRepository.acknowledgeFailure(
                                latestFailure.runId,
                              );
                              _refreshRiskLifecycle();
                            },
                            child: const Text('已讀'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Text(
                    'L${_riskLevel.round()}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Slider(
                    value: _riskLevel,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: 'L${_riskLevel.round()}',
                    onChanged: (value) => setState(() => _riskLevel = value),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '目前建議：以分散配置為主，維持固定檢視頻率。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 160,
                      child: PrimaryButton(
                        label: '儲存偏好',
                        onPressed: _saveRiskPreference,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '再評估狀態',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    nextAnnualDueAt == null
                        ? '尚未建立定期再評估任務。'
                        : '下次定期再評估：${_dateFormat.format(nextAnnualDueAt.toLocal())}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '任務統計：待處理 ${_riskLifecycle.pendingTaskCount} / 已完成 ${_riskLifecycle.completedTaskCount}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  if (_riskLifecycle.lastCompletedAt != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '最近完成：${_dateTimeFormat.format(_riskLifecycle.lastCompletedAt!.toLocal())}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _majorEventController,
                    decoration: const InputDecoration(
                      labelText: '重大事件觸發入口',
                      hintText: '例如：收入結構改變、家庭支出變化',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _createMajorEventTask,
                      icon: const Icon(Icons.add_alert_outlined, size: 18),
                      label: const Text('建立再評估任務'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (riskTasks.isEmpty)
                    Text(
                      '尚無再評估任務。',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    for (final task in riskTasks) ...[
                      Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          title: Text(task.type.label),
                          subtitle: Text(
                            '狀態：${task.status.label}\n'
                            '到期：${_dateTimeFormat.format(task.dueAt.toLocal())}'
                            '${task.note == null ? '' : '\n備註：${task.note}'}',
                          ),
                          isThreeLine: true,
                          trailing: task.isActionable
                              ? TextButton(
                                  onPressed: () => _completeTask(task),
                                  child: const Text('標記完成'),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
