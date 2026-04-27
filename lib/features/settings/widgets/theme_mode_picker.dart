import 'package:flutter/material.dart';

class ThemeModePicker extends StatelessWidget {
  const ThemeModePicker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('跟隨系統')),
            ButtonSegment(value: ThemeMode.light, label: Text('淺色模式')),
            ButtonSegment(value: ThemeMode.dark, label: Text('暗色模式')),
          ],
          selected: {value},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              onChanged(selection.first);
            }
          },
        ),
        const SizedBox(height: 8),
        Text('可隨時切換淺色、暗色或跟隨系統。', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
