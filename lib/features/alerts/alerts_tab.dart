import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/filter_chips/filter_chips.dart';
import 'package:reconex/core/custom_widgets/paged_list_view/paged_list_view.dart';
import 'package:reconex/core/custom_widgets/state_views/state_views.dart';
import 'package:reconex/core/custom_widgets/status_badge/status_badge.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/data/models/app_alert.dart';
import 'package:reconex/features/alerts/alerts_controller.dart';

class AlertsTab extends GetView<AlertsController> {
  const AlertsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: PagedListView<AppAlert>(
        controller: controller,
        bottomSpace: AppSpacing.xxl,
        header: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomText(
                    text: 'Alerts',
                    fontSize: AppTextTokens.displaySize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.normalText,
                    textAlign: TextAlign.left,
                  ),
                  4.height,
                  Obx(
                    () => CustomText(
                      text: controller.isLoading.value ? 'Loading…' : '${controller.total.value} across all domains',
                      fontSize: AppTextTokens.bodySmSize,
                      color: AppColors.grey500,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Obx(
              () => SeverityFilterBar(selected: controller.severities.toSet(), onToggle: controller.toggleSeverity),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
        ],
        empty: const EmptyState(
          icon: Icons.notifications_none_rounded,
          title: 'No alerts',
          message: 'Alerts appear here when scans find risky changes, like a newly opened port or an exposed file.',
        ),
        itemBuilder: (_, alert) => AlertCard(alert: alert, onTap: () => controller.openAlert(alert)),
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  final AppAlert alert;
  final VoidCallback onTap;

  const AlertCard({super.key, required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = severityColor(alert.severity);
    return Material(
      color: AppColors.white,
      borderRadius: AppRadius.rMd,
      clipBehavior: Clip.antiAlias,
      child:
          // InkWell(
          // onTap: onTap,
          // child:
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            StatusBadge.severity(alert.severity),
                            const Spacer(),
                            CustomText(text: timeAgo(alert.createdAt), fontSize: 12, color: AppColors.grey400),
                          ],
                        ),
                        AppSpacing.sm.height,
                        CustomText(
                          text: alert.title,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.normalText,
                          textAlign: TextAlign.left,
                        ),
                        4.height,
                        CustomText(
                          text: alert.message,
                          fontSize: 13,
                          color: AppColors.lightText,
                          textAlign: TextAlign.left,
                          height: 1.35,
                        ),
                        AppSpacing.sm.height,
                        Row(
                          children: [
                            Icon(
                              alert.isNetwork ? Icons.wifi_rounded : Icons.language_rounded,
                              size: 14,
                              color: AppColors.grey400,
                            ),
                            4.width,
                            Expanded(
                              child: CustomText(
                                text: alert.sourceName,
                                fontSize: 12,
                                color: AppColors.grey500,
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      // ),
    );
  }
}
