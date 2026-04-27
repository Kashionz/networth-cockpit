import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/export_repository.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../widgets/export_format_picker.dart';
import '../widgets/settings_section.dart';

class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({super.key});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  ExportFormat _format = ExportFormat.csv;
  bool _isExporting = false;
  List<ExportArtifact> _history = const <ExportArtifact>[];

  @override
  void initState() {
    super.initState();
    _history = ref.read(exportRepositoryProvider).getHistory();
  }

  Future<void> _exportData() async {
    if (_isExporting) {
      return;
    }

    setState(() => _isExporting = true);
    try {
      final repository = ref.read(exportRepositoryProvider);
      final format = switch (_format) {
        ExportFormat.csv => ExportDataFormat.csv,
        ExportFormat.json => ExportDataFormat.json,
      };
      final artifact = await repository.exportData(format: format);
      if (!mounted) {
        return;
      }

      setState(() => _history = repository.getHistory());
      final resultMessage = artifact.downloadTriggered
          ? '已啟動 ${artifact.format.label} 下載：${artifact.fileName}'
          : '已輸出 ${artifact.format.label} 檔：${artifact.outputLocation}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultMessage)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('匯出失敗：$error')));
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm:ss');

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
                  '資料匯出',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '可先匯出備份，再進行跨平台整理。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SettingsSection(
                  title: '匯出格式',
                  description: '檔案內容包含資產、預算與分類設定。web 會直接下載，非 web 會回傳輸出路徑。',
                  children: [
                    ExportFormatPicker(
                      value: _format,
                      onChanged: (value) => setState(() => _format = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: 160,
                      child: PrimaryButton(
                        label: _isExporting ? '匯出中...' : '匯出資料',
                        icon: Icons.download_outlined,
                        onPressed: _isExporting
                            ? null
                            : () {
                                _exportData();
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SettingsSection(
                  title: '最近匯出紀錄',
                  description: '可追蹤檔名、格式與輸出位置。',
                  children: [
                    if (_history.isEmpty)
                      Text(
                        '尚無匯出紀錄。',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      for (final entry in _history.take(8)) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              entry.downloadTriggered
                                  ? Icons.download_done_outlined
                                  : Icons.folder_open_outlined,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${entry.format.label} • ${entry.fileName}',
                                    style: Theme.of(context).textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    dateFormat.format(entry.createdAt.toLocal()),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '位置：${entry.outputLocation}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '大小：${entry.byteLength} bytes',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (entry != _history.take(8).last)
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
}
