import 'package:flutter/material.dart';

enum ExportFormat { csv, json }

class ExportFormatPicker extends StatelessWidget {
  const ExportFormatPicker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ExportFormat value;
  final ValueChanged<ExportFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ExportFormat>(
      segments: const [
        ButtonSegment<ExportFormat>(
          value: ExportFormat.csv,
          label: Text('CSV'),
        ),
        ButtonSegment<ExportFormat>(
          value: ExportFormat.json,
          label: Text('JSON'),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
      showSelectedIcon: false,
    );
  }
}
