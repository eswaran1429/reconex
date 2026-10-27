import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/controllers/paged_controller.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/filter_chips/filter_chips.dart';
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

// ---------------------------------------------------------------- Inventory

class NetworkDevicesController extends PagedController<NetworkDevice> {
  final NetworkService _networkService = Get.find();
  final String networkId = Get.arguments as String;

  final RxBool seenLatestOnly = false.obs;

  @override
  Future<Paginated<NetworkDevice>> fetchPage(int page) =>
      _networkService.devices(networkId, page: page, seenLatest: seenLatestOnly.value);

  void setSeenLatestOnly(bool value) {
    if (seenLatestOnly.value == value) return;
    seenLatestOnly.value = value;
    reload();
  }

  void openDevice(NetworkDevice device) => Get.toNamed(AppRoutes.networkDevice, arguments: device.id);
}

class NetworkDevicesScreen extends GetView<NetworkDevicesController> {
  const NetworkDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      body: PagedListView<NetworkDevice>(
        controller: controller,
        header: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Obx(() {
                final latest = controller.seenLatestOnly.value;
                return FilterChipRow(
                  labels: const ['All known', 'Seen in latest scan'],
                  isSelected: (i) => (i == 1) == latest,
                  onTap: (i) => controller.setSeenLatestOnly(i == 1),
                );
              }),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
        ],
        empty: const EmptyState(
          icon: Icons.devices_other_rounded,
          title: 'No devices',
          message: 'Devices appear here once a scan of this network has been saved.',
        ),
        itemBuilder: (_, d) => DeviceCard(
          ipAddress: d.ipAddress ?? 'Unknown address',
          hostname: d.hostname,
          addressOnly: d.identifiedByAddressOnly,
          openPorts: d.openPorts,
          status: d.lastStatus,
          trailing: 'seen ${timeAgo(d.lastSeenAt)}',
          onTap: () => controller.openDevice(d),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- One device

class NetworkDeviceController extends PagedController<NetworkObservation> {
  final NetworkService _networkService = Get.find();
  final String deviceId = Get.arguments as String;

  final Rxn<NetworkDevice> device = Rxn<NetworkDevice>();
  final RxList<NetworkPort> ports = <NetworkPort>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDevice();
  }

  Future<void> loadDevice() async {
    try {
      final results = await Future.wait([_networkService.device(deviceId), _networkService.devicePorts(deviceId)]);
      device.value = results[0] as NetworkDevice;
      ports.assignAll(results[1] as List<NetworkPort>);
    } catch (_) {
      // History list below shows the error state.
    }
  }

  @override
  Future<Paginated<NetworkObservation>> fetchPage(int page) => _networkService.deviceHistory(deviceId, page: page);

  @override
  Future<void> refreshList() async {
    await Future.wait([super.refreshList(), loadDevice()]);
  }
}

class NetworkDeviceScreen extends GetView<NetworkDeviceController> {
  const NetworkDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final d = controller.device.value;
          return Text(d == null ? 'Device' : (d.hostname ?? d.ipAddress ?? 'Device'));
        }),
      ),
      body: PagedListView<NetworkObservation>(
        controller: controller,
        header: [
          SliverToBoxAdapter(
            child: Obx(() {
              final d = controller.device.value;
              if (d == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: Column(
                  children: [
                    _DeviceInfoCard(device: d),
                    AppSpacing.lg.height,
                    SectionCard(
                      title: 'Ports in latest sighting',
                      child: controller.ports.isEmpty
                          ? const CustomText(
                              text: 'No port results saved for this device.',
                              fontSize: 13,
                              color: AppColors.grey500,
                              textAlign: TextAlign.left,
                            )
                          : Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [for (final p in controller.ports) PortChip(port: p)],
                            ),
                    ),
                    AppSpacing.lg.height,
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: CustomText(
                        text: 'Sightings',
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
          icon: Icons.history_rounded,
          title: 'No sightings',
          message: 'No saved scan has observed this device.',
        ),
        itemBuilder: (_, o) => SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      text: formatDateTime(o.observedAt),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.normalText,
                      textAlign: TextAlign.left,
                    ),
                  ),
                  if (o.scanStatus != null) StatusBadge.status(o.scanStatus!),
                ],
              ),
              4.height,
              CustomText(
                text: '${o.ipAddress} · ${orUnknown(o.hostname)} · ${o.ports.length} open',
                fontSize: 12,
                color: AppColors.grey500,
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceInfoCard extends StatelessWidget {
  final NetworkDevice device;

  const _DeviceInfoCard({required this.device});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Device',
      trailing: switch (device.lastStatus) {
        'seen' => const StatusBadge(label: 'Seen in latest scan', color: AppColors.successGreen),
        'not_seen' => const StatusBadge(label: 'Not observed in latest scan', color: AppColors.grey500),
        _ => null,
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(label: 'IP address', value: orUnknown(device.ipAddress)),
          InfoRow(label: 'Hostname', value: orUnknown(device.hostname)),
          InfoRow(label: 'MAC address', value: orUnknown(device.macAddress)),
          InfoRow(label: 'Manufacturer', value: orUnknown(device.vendor)),
          InfoRow(
            label: 'Found by',
            value: device.discoveryMethod == null ? 'Unknown' : humanize(device.discoveryMethod!),
          ),
          InfoRow(label: 'First seen', value: formatDateTime(device.firstSeenAt)),
          InfoRow(label: 'Last seen', value: formatDateTime(device.lastSeenAt)),
          if (device.identifiedByAddressOnly) ...[
            AppSpacing.sm.height,
            const CustomText(
              text:
                  'Identified by address only: the MAC address wasn\'t available, so a different device '
                  'using this address later would look like the same one.',
              fontSize: 12,
              color: AppColors.grey500,
              textAlign: TextAlign.left,
              height: 1.4,
            ),
          ],
        ],
      ),
    );
  }
}
