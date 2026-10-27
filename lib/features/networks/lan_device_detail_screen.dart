import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/section_card/section_card.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/data/models/lan_device.dart';
import 'package:reconex/data/services/lan_scan_service.dart';

String _orUnknown(String? v) => (v == null || v.isEmpty) ? 'Unknown' : v;

/// Known service names for the ports the scanner checks.
const Map<int, String> _serviceNames = {
  21: 'FTP',
  22: 'SSH',
  23: 'Telnet',
  53: 'DNS',
  80: 'HTTP',
  139: 'NetBIOS',
  443: 'HTTPS',
  445: 'SMB',
  554: 'RTSP',
  1883: 'MQTT',
  3306: 'MySQL',
  5000: 'UPnP',
  8080: 'HTTP alt',
  8443: 'HTTPS alt',
  9100: 'Printer',
};

class LanDeviceController extends GetxController {
  final LanScanService _lan = Get.find();
  final LanDevice device = Get.arguments as LanDevice;

  /// Null until a port check has run.
  final Rxn<List<int>> openPorts = Rxn<List<int>>();
  final RxBool isScanningPorts = false.obs;
  final RxnString portError = RxnString();

  Future<void> checkPorts() async {
    isScanningPorts.value = true;
    portError.value = null;
    try {
      openPorts.value = await _lan.scanPorts(device.ip);
    } catch (e) {
      portError.value = e.toString();
    } finally {
      isScanningPorts.value = false;
    }
  }
}

class LanDeviceDetailScreen extends GetView<LanDeviceController> {
  const LanDeviceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final device = controller.device;
    return Scaffold(
      appBar: AppBar(title: Text(device.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          SectionCard(
            title: 'Device',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (device.isGateway || device.isSelf) ...[
                  CustomText(
                    text: device.isGateway ? 'This is your router' : 'This is the phone you\'re using',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: device.isGateway ? AppColors.purple : AppColors.successGreen,
                    textAlign: TextAlign.left,
                  ),
                  AppSpacing.sm.height,
                ],
                InfoRow(label: 'IP address', value: device.ip),
                InfoRow(label: 'Hostname', value: _orUnknown(device.hostname)),
                InfoRow(label: 'MAC address', value: _orUnknown(device.mac)),
                InfoRow(label: 'Manufacturer', value: _orUnknown(device.vendor)),
                if (device.mac == null) ...[
                  AppSpacing.sm.height,
                  const CustomText(
                    text:
                        'The MAC address and manufacturer aren\'t available for this device. Phones usually can\'t read them.',
                    fontSize: 12,
                    color: AppColors.grey500,
                    textAlign: TextAlign.left,
                    height: 1.4,
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.lg.height,
          _PortsCard(controller: controller),
          AppSpacing.xxl.height,
        ],
      ),
    );
  }
}

class _PortsCard extends StatelessWidget {
  final LanDeviceController controller;

  const _PortsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ports = controller.openPorts.value;
      final error = controller.portError.value;
      return SectionCard(
        title: 'Open ports',
        trailing: SmallActionButton(
          label: ports == null ? 'Check' : 'Recheck',
          icon: Icons.radar_rounded,
          loading: controller.isScanningPorts.value,
          onTap: controller.checkPorts,
        ),
        child: error != null
            ? CustomText(text: error, fontSize: 13, color: AppColors.red500, textAlign: TextAlign.left)
            : ports == null
            ? const CustomText(
                text:
                    'Check which common ports are open on this device. An open port is an observation, not a problem on its own.',
                fontSize: 13,
                color: AppColors.grey500,
                textAlign: TextAlign.left,
                height: 1.4,
              )
            : ports.isEmpty
            ? const CustomText(
                text: 'No common ports open.',
                fontSize: 13,
                color: AppColors.grey500,
                textAlign: TextAlign.left,
              )
            : Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final port in ports)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.successGreenLight,
                        borderRadius: AppRadius.rSm,
                        border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.4)),
                      ),
                      child: CustomText(
                        text: _serviceNames.containsKey(port) ? '$port ${_serviceNames[port]}' : '$port',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.successGreen,
                      ),
                    ),
                ],
              ),
      );
    });
  }
}
