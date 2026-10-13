import 'package:flutter/material.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/status_badge/status_badge.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_icons.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/data/models/change.dart';

class ChangeTile extends StatelessWidget {
  final Change change;
  final VoidCallback onTap;

  const ChangeTile({super.key, required this.change, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = severityColor(change.severity);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: AppRadius.rSm),
              child: Icon(AppIcons.category(change.category), color: color, size: 20),
            ),
            AppSpacing.md.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: humanize(change.type),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.normalText,
                    textAlign: TextAlign.left,
                  ),
                  2.height,
                  CustomText(
                    text: change.key,
                    fontSize: 12,
                    color: AppColors.grey500,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AppSpacing.sm.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge.severity(change.severity),
                4.height,
                CustomText(text: timeAgo(change.createdAt), fontSize: 11, color: AppColors.grey400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
