import 'package:flutter/material.dart';

class AllocationSegment {
  const AllocationSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class AllocationBar extends StatelessWidget {
  const AllocationBar({required this.segments, this.height = 12, super.key});

  final List<AllocationSegment> segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (sum, item) => sum + item.value);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (final segment in segments)
              Expanded(
                flex: total <= 0 ? 1 : (segment.value / total * 1000).round(),
                child: ColoredBox(color: segment.color),
              ),
          ],
        ),
      ),
    );
  }
}
