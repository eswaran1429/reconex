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
import 'package:reconex/data/models/network.dart';
import 'package:reconex/data/services/network_service.dart';
import 'package:reconex/features/networks/network_widgets.dart';
import 'package:reconex/routes/app_routes.dart';

// ---------------------------------------------------------------- History

class NetworkScansController extends PagedController<NetworkScanRecord> {
  final NetworkService _networkService = Get.find();
  final String networkId = Get.arguments as String;

  @override
  Future<Paginated<NetworkScanRecord>> fetchPage(int page) => _networkService.scans(networkId, page: page);

  void openScan(NetworkScanRecord scan) => Get.toNamed(AppRoutes.networkScan, arguments: scan.id);
}

class NetworkScansScreen extends GetView<NetworkScansController> {
  const NetworkScansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan history')),
      body: PagedListView<NetworkScanRecord>(
        controller: controller,
        empty: const EmptyState(
          icon: Icons.history_rounded,
          title: 'No scans yet',
          message: 'Saved scans for this network will appear here.',
        ),
        itemBuilder: (_, scan) => SectionCard(
          onTap: () => controller.openScan(scan),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: formatDateTime(scan.startedAt),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.normalText,
                      textAlign: TextAlign.left,
                    ),
                    4.height,
                    CustomText(
                      text: [
                        if (scan.devices != null) '${scan.devices} devices',
                        '${scan.changeCount} changes',
                        if (scan.completedAt != null) formatDuration(scan.startedAt, scan.completedAt),
                      ].join(' · '),
                      fontSize: 12,
                      color: AppColors.grey500,
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
              StatusBadge.status(scan.status),
              const Icon(Icons.chevron_right_rounded, color: AppColors.grey300),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- One scan

/// One scan's summary, devices seen and changes found.
class NetworkScanController extends PagedController<NetworkObservation> {
  final NetworkService _networkService = Get.find();
  final String scanId = Get.arguments as String;

  final Rxn<NetworkScanRecord> scan = Rxn<NetworkScanRecord>();
  final RxList<NetworkChange> changes = <NetworkChange>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadScan();
  }

  Future<void> loadScan() async {
    try {
      final record = await _networkService.scan(scanId);
      scan.value = record;
      final page = await _networkService.changes(record.networkId, scanId: scanId);
      changes.assignAll(page.items);
    } catch (_) {
      // The device list shows the error state; the header just stays empty.
    }
  }

  @override
  Future<Paginated<NetworkObservation>> fetchPage(int page) => _networkService.scanDevices(scanId, page: page);

  @override
  Future<void> refreshList() async {
    await Future.wait([super.refreshList(), loadScan()]);
  }

  void openDevice(NetworkObservation o) => Get.toNamed(AppRoutes.networkDevice, arguments: o.deviceId);
}

class NetworkScanScreen extends GetView<NetworkScanController> {
  const NetworkScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: PagedListView<NetworkObservation>(
        controller: controller,
        header: [
          SliverToBoxAdapter(
            child: Obx(() {
              final scan = controller.scan.value;
              if (scan == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: Column(
                  children: [
                    _ScanSummaryCard(scan: scan),
                    if (controller.changes.isNotEmpty) ...[
                      AppSpacing.lg.height,
                      SectionCard(
                        title: 'Changes in this scan',
                        child: Column(
                          children: [for (final change in controller.changes) NetworkChangeTile(change: change)],
                        ),
                      ),
                    ],
                    AppSpacing.lg.height,
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: CustomText(
                        text: 'Devices seen',
                        fontSize: AppTextTokens.titleSmSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.normalText,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
        empty: const EmptyState(
          icon: Icons.devices_other_rounded,
          title: 'No devices in this scan',
          message: 'This scan saved no device results.',
        ),
        itemBuilder: (_, o) => DeviceCard(
          ipAddress: o.ipAddress,
          hostname: o.hostname,
          addressOnly: o.identity == 'ip',
          openPorts: o.ports.where((p) => p.isOpen).length,
          trailing: humanize(o.discoveryMethod ?? 'unknown'),
          onTap: () => controller.openDevice(o),
        ),
      ),
    );
  }
}

class _ScanSummaryCard extends StatelessWidget {
  final NetworkScanRecord scan;

  const _ScanSummaryCard({required this.scan});

  @override
  Widget build(BuildContext context) {
    final note = switch (scan.status) {
      'PARTIAL' => 'This scan stopped early, so it isn\'t a full inventory. Missing devices aren\'t reported.',
      'RUNNING' => 'This scan hasn\'t finished. Results may be incomplete.',
      'FAILED' || 'CANCELLED' => 'This scan didn\'t finish and wasn\'t compared with earlier scans.',
      _ => null,
    };
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBadge.status(scan.status),
          if (note != null) ...[
            AppSpacing.sm.height,
            CustomText(text: note, fontSize: 12, color: AppColors.warning, textAlign: TextAlign.left, height: 1.4),
          ],
          if (scan.error != null) ...[
            AppSpacing.sm.height,
            CustomText(text: scan.error!, fontSize: 12, color: AppColors.red500, textAlign: TextAlign.left),
          ],
          AppSpacing.md.height,
          InfoRow(label: 'Started', value: formatDateTime(scan.startedAt)),
          InfoRow(label: 'Finished', value: formatDateTime(scan.completedAt)),
          if (scan.total != null) InfoRow(label: 'Addresses checked', value: '${scan.probed ?? 0} of ${scan.total}'),
          InfoRow(label: 'Devices', value: scan.devices?.toString() ?? '—'),
          InfoRow(label: 'New devices', value: scan.newDevices?.toString() ?? '—'),
          InfoRow(label: 'Not observed', value: scan.notSeen?.toString() ?? '—'),
          InfoRow(label: 'Open ports', value: scan.openPorts?.toString() ?? '—'),
        ],
      ),
    );
  }
}
