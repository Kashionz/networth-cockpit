import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/forms/category_tag.dart';

Future<String?> showCategoryPickerSheet({
  required BuildContext context,
  required List<String> categories,
  required String selectedCategory,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return CategoryPickerSheet(
        categories: categories,
        selectedCategory: selectedCategory,
      );
    },
  );
}

class CategoryPickerSheet extends StatelessWidget {
  const CategoryPickerSheet({
    super.key,
    required this.categories,
    required this.selectedCategory,
  });

  final List<String> categories;
  final String selectedCategory;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '選擇分類',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final category in categories)
                  CategoryTag(
                    key: ValueKey('category-option-$category'),
                    label: category,
                    selected: category == selectedCategory,
                    onTap: () => Navigator.of(context).pop(category),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
