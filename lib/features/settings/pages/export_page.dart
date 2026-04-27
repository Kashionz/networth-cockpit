import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../widgets/export_format_picker.dart';
import '../widgets/settings_section.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  ExportFormat _format = ExportFormat.csv;

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
                  description: '檔案內容包含資產、預算與分類設定。',
                  children: [
                    ExportFormatPicker(
                      value: _format,
                      onChanged: (value) => setState(() => _format = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: 160,
                      child: PrimaryButton(
                        label: '匯出資料',
                        icon: Icons.download_outlined,
                        onPressed: () {
                          final format = switch (_format) {
                            ExportFormat.csv => 'CSV',
                            ExportFormat.json => 'JSON',
                          };
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已準備 $format 匯出檔')),
                          );
                        },
                      ),
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
