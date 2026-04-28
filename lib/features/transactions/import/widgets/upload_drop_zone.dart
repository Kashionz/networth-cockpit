import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

class UploadDropZone extends StatefulWidget {
  const UploadDropZone({
    super.key,
    this.onLoadFromPath,
    this.onSubmitCsvContent,
    this.onSelectSampleFile,
    this.statusLabel,
    this.isProcessing = false,
  });

  final Future<void> Function(String path)? onLoadFromPath;
  final void Function(String csvContent)? onSubmitCsvContent;
  final VoidCallback? onSelectSampleFile;
  final String? statusLabel;
  final bool isProcessing;

  @override
  State<UploadDropZone> createState() => _UploadDropZoneState();
}

class _UploadDropZoneState extends State<UploadDropZone> {
  late final TextEditingController _pathController;
  late final TextEditingController _csvController;

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController();
    _csvController = TextEditingController();
  }

  @override
  void dispose() {
    _pathController.dispose();
    _csvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final effectiveStatus = widget.statusLabel ?? '等待選擇檔案';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.accentEdge),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.upload_file_outlined,
                size: 36,
                color: widget.isProcessing
                    ? AppColors.accent
                    : AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '支援 CSV / PDF',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                effectiveStatus,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (widget.isProcessing) ...[
                const SizedBox(height: AppSpacing.md),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: AppSpacing.lg),
              TextField(
                key: const ValueKey('csv-path-input'),
                controller: _pathController,
                enabled: !widget.isProcessing,
                decoration: const InputDecoration(
                  labelText: 'CSV 檔案路徑',
                  hintText:
                      '例如 C:\\\\Users\\\\you\\\\Downloads\\\\statement.csv',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: widget.isProcessing
                    ? null
                    : () {
                        if (widget.onLoadFromPath != null) {
                          widget.onLoadFromPath!(_pathController.text);
                          return;
                        }
                        widget.onSelectSampleFile?.call();
                      },
                child: const Text('從路徑讀取 CSV'),
              ),
              if (widget.onSelectSampleFile != null) ...[
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: widget.isProcessing
                      ? null
                      : widget.onSelectSampleFile,
                  child: const Text('使用範例檔案'),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const ValueKey('csv-content-input'),
                controller: _csvController,
                enabled: !widget.isProcessing,
                minLines: 6,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: '貼上 CSV 內容',
                  hintText: '請貼上包含日期、商家、金額欄位的 CSV 內容',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: widget.isProcessing
                    ? null
                    : widget.onSubmitCsvContent == null
                    ? null
                    : () => widget.onSubmitCsvContent!(_csvController.text),
                child: const Text('使用貼上內容'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
