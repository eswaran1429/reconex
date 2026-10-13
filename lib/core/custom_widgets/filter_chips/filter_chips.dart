import 'package:flutter/material.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/status_badge/status_badge.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/data/models/severity.dart';

/// Horizontally scrolling row of toggle chips.
class FilterChipRow extends StatelessWidget {
  final List<String> labels;
  final bool Function(int index) isSelected;
  final ValueChanged<int> onTap;
  final Color Function(int index)? colorOf;

  const FilterChipRow({super.key, required this.labels, required this.isSelected, required this.onTap, this.colorOf});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final selected = isSelected(i);
          final color = colorOf?.call(i) ?? AppColors.amber700;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.12) : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? color : AppColors.grey200),
              ),
              child: CustomText(
                text: labels[i],
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? color : AppColors.grey600,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Multi-select severity filter.
class SeverityFilterBar extends StatelessWidget {
  final Set<Severity> selected;
  final ValueChanged<Severity> onToggle;

  const SeverityFilterBar({super.key, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    const values = Severity.values;
    return FilterChipRow(
      labels: values.map((s) => humanize(s.name)).toList(),
      isSelected: (i) => selected.contains(values[i]),
      onTap: (i) => onToggle(values[i]),
      colorOf: (i) => severityColor(values[i]),
    );
  }
}
