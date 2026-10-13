import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/filter_chips/filter_chips.dart';
import 'package:reconex/core/custom_widgets/paged_list_view/paged_list_view.dart';
import 'package:reconex/core/custom_widgets/state_views/state_views.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/data/models/change.dart';
import 'package:reconex/features/changes/change_tile.dart';
import 'package:reconex/features/changes/changes_controller.dart';

class ChangesScreen extends GetView<ChangesController> {
  const ChangesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const categories = ChangesController.categories;
    return Scaffold(
      appBar: AppBar(title: Text(controller.args.scanId == null ? 'Changes' : 'Scan changes')),
      body: PagedListView<Change>(
        controller: controller,
        header: [
          SliverToBoxAdapter(
            child: Obx(
              () => SeverityFilterBar(selected: controller.severities.toSet(), onToggle: controller.toggleSeverity),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
          SliverToBoxAdapter(
            child: Obx(() {
              final selected = controller.category.value;
              return FilterChipRow(
                labels: categories.map(humanize).toList(),
                isSelected: (i) => categories[i] == selected,
                onTap: (i) => controller.selectCategory(categories[i]),
              );
            }),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
        ],
        empty: const EmptyState(
          icon: Icons.change_circle_outlined,
          title: 'No changes',
          message: 'Nothing matches these filters. Changes are recorded when a scan differs from the previous one.',
        ),
        itemBuilder: (_, change) => Material(
          color: AppColors.white,
          borderRadius: AppRadius.rMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: ChangeTile(change: change, onTap: () => controller.openChange(change)),
          ),
        ),
      ),
    );
  }
}
