import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

class UploadDropZone extends StatelessWidget {
  const UploadDropZone({
    super.key,
    required this.onSelectSampleFile,
    this.statusLabel,
    this.isProcessing = false,
  });

  final VoidCallback onSelectSampleFile;
  final String? statusLabel;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final effectiveStatus = statusLabel ?? '等待選擇檔案';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.accentEdge),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.upload_file_outlined,
              size: 36,
              color: isProcessing ? AppColors.accent : AppColors.textTertiary,
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
            if (isProcessing) ...[
              const SizedBox(height: AppSpacing.md),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: isProcessing ? null : onSelectSampleFile,
              child: const Text('使用範例檔案'),
            ),
          ],
        ),
      ),
    );
  }
}
