import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/controllers/paged_controller.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/paged_list_view/paged_list_view.dart';
import 'package:reconex/core/custom_widgets/section_card/section_card.dart';
import 'package:reconex/core/custom_widgets/state_views/state_views.dart';
import 'package:reconex/core/custom_widgets/status_badge/status_badge.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/data/models/scan.dart';
import 'package:reconex/data/services/scan_service.dart';
import 'package:reconex/routes/app_routes.dart';

class ScansController extends PagedController<Scan> {
  final ScanService _scanService = Get.find();
  final String domainId = Get.arguments as String;

  @override
  Future<Paginated<Scan>> fetchPage(int page) => _scanService.listForDomain(domainId, page: page);

  Future<void> openScan(Scan scan) async {
    await Get.toNamed(AppRoutes.scanDetail, arguments: scan.id);
    refreshList();
  }
}

class ScansScreen extends GetView<ScansController> {
  const ScansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan history')),
      body: PagedListView<Scan>(
        controller: controller,
        empty: const EmptyState(
          icon: Icons.radar_rounded,
          title: 'No scans yet',
          message: 'Run a full scan from the domain page to map its attack surface.',
        ),
        itemBuilder: (_, scan) => _ScanCard(scan: scan, onTap: () => controller.openScan(scan)),
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final Scan scan;
  final VoidCallback onTap;

  const _ScanCard({required this.scan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(scan.status);
    return SectionCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: AppRadius.rSm),
            child: Icon(scan.isActive ? Icons.radar_rounded : Icons.fact_check_outlined, color: color),
          ),
          AppSpacing.md.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: formatDateTime(scan.startedAt ?? scan.createdAt),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.normalText,
                  textAlign: TextAlign.left,
                ),
                4.height,
                CustomText(
                  text: [
                    '${scan.changeCount} changes',
                    if (scan.completedAt != null) formatDuration(scan.startedAt, scan.completedAt),
                    if (scan.trigger != null) humanize(scan.trigger!),
                  ].join(' · '),
                  fontSize: 12,
                  color: AppColors.grey500,
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
          StatusBadge.status(scan.status),
        ],
      ),
    );
  }
}
