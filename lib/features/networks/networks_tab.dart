import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/section_card/section_card.dart';
import 'package:reconex/core/custom_widgets/state_views/state_views.dart';
import 'package:reconex/core/custom_widgets/status_badge/status_badge.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/data/models/lan_device.dart';
import 'package:reconex/data/services/lan_scan_service.dart';
import 'package:reconex/routes/app_routes.dart';

/// Detects the current Wi-Fi and scans it for connected devices, Fing-style.
class NetworksController extends GetxController {
  final LanScanService _lan = Get.find();

  final Rxn<LanSelf> self = Rxn<LanSelf>();
  final RxList<LanDevice> devices = <LanDevice>[].obs;
  final RxBool isDetecting = true.obs;
  final RxBool isScanning = false.obs;
  final RxnString error = RxnString();

  StreamSubscription<LanDevice>? _sub;

  @override
  void onInit() {
    super.onInit();
    detect();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  /// Reads the current Wi-Fi, then starts scanning it.
  Future<void> detect() async {
    isDetecting.value = true;
    error.value = null;
    try {
      await _lan.requestWifiNamePermission();
      final net = await _lan.currentNetwork();
      self.value = net;
      if (!net.onWifi) {
        error.value = 'Connect to a Wi-Fi network to see the devices on it.';
        return;
      }
      _startScan(net);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isDetecting.value = false;
    }
  }

  void rescan() {
    final net = self.value;
    if (net != null && net.onWifi) {
      _startScan(net);
    } else {
      detect();
    }
  }

  void _startScan(LanSelf net) {
    _sub?.cancel();
    devices.clear();
    isScanning.value = true;
    _sub = _lan
        .discover(net)
        .listen(
          _merge,
          onDone: () => isScanning.value = false,
          onError: (Object e) {
            error.value = e.toString();
            isScanning.value = false;
          },
        );
  }

  void _merge(LanDevice device) {
    final i = devices.indexWhere((d) => d.ip == device.ip);
    if (i >= 0) {
      devices[i] = device;
    } else {
      devices.add(device);
      devices.sort((a, b) => a.hostId.compareTo(b.hostId));
    }
  }

  int get onlineCount => devices.length;

  void openCameraScan() => Get.toNamed(AppRoutes.roomSweep);

  void openDevice(LanDevice device) => Get.toNamed(AppRoutes.lanDevice, arguments: device);
}

class NetworksTab extends GetView<NetworksController> {
  const NetworksTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _Header(controller: controller),
          Expanded(
            child: Obx(() {
              if (controller.isDetecting.value) return const CardListSkeleton();
              final error = controller.error.value;
              if (error != null && controller.devices.isEmpty) {
                return _NotOnWifi(message: error, onRetry: controller.detect);
              }
              if (controller.devices.isEmpty && !controller.isScanning.value) {
                return EmptyState(
                  icon: Icons.wifi_find_rounded,
                  title: 'No devices found',
                  message: 'Nothing answered on this network. Some devices don\'t respond to discovery.',
                  actionLabel: 'Scan again',
                  onAction: controller.rescan,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
                itemCount: controller.devices.length,
                separatorBuilder: (_, _) => AppSpacing.md.height,
                itemBuilder: (_, i) {
                  final device = controller.devices[i];
                  return _DeviceCard(device: device, onTap: () => controller.openDevice(device));
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final NetworksController controller;

  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(() {
                  final net = controller.self.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: net?.ssid ?? (net?.onWifi == true ? 'Wi-Fi network' : 'Not connected'),
                        fontSize: AppTextTokens.displaySize - 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.normalText,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      4.height,
                      CustomText(
                        text: controller.isDetecting.value
                            ? 'Detecting…'
                            : (net?.onWifi == true
                                  ? '${net!.subnetLabel} · ${controller.onlineCount} devices'
                                  : 'No Wi-Fi'),
                        fontSize: AppTextTokens.bodySmSize,
                        color: AppColors.grey500,
                        textAlign: TextAlign.left,
                      ),
                    ],
                  );
                }),
              ),
              // Tooltip(
              //   message: 'Scan for hidden cameras',
              //   child: GestureDetector(
              //     onTap: controller.openCameraScan,
              //     child: Container(
              //       height: 48,
              //       width: 48,
              //       decoration: BoxDecoration(
              //         color: AppColors.white,
              //         borderRadius: AppRadius.rSm,
              //         boxShadow: AppShadows.md,
              //       ),
              //       child: const Icon(Icons.videocam_outlined, color: AppColors.normalText, size: 24),
              //     ),
              //   ),
              // ),
              AppSpacing.sm.width,
              Obx(
                () => GestureDetector(
                  onTap: controller.isScanning.value ? null : controller.rescan,
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientButton,
                      borderRadius: AppRadius.rSm,
                      boxShadow: AppShadows.md,
                    ),
                    child: controller.isScanning.value
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white),
                          )
                        : const Icon(Icons.refresh_rounded, color: AppColors.white, size: 26),
                  ),
                ),
              ),
            ],
          ),
          Obx(() {
            if (!controller.isScanning.value) return const SizedBox.shrink();
            return const Padding(
              padding: EdgeInsets.only(top: AppSpacing.md),
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: AppColors.grey100,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _NotOnWifi extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _NotOnWifi({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'Not on Wi-Fi',
      message: message,
      actionLabel: 'Try again',
      onAction: onRetry,
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final LanDevice device;
  final VoidCallback onTap;

  const _DeviceCard({required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = device.isGateway
        ? (Icons.router_rounded, AppColors.purple)
        : device.isSelf
        ? (Icons.smartphone_rounded, AppColors.successGreen)
        : (Icons.devices_other_rounded, AppColors.blue500);

    return SectionCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: AppRadius.rSm),
            child: Icon(icon, color: color),
          ),
          AppSpacing.md.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: device.displayName,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.normalText,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                4.height,
                CustomText(
                  text: device.mac == null ? device.ip : '${device.ip} · ${device.mac}',
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
          if (device.isGateway) const StatusBadge(label: 'Router', color: AppColors.purple),
          if (device.isSelf) const StatusBadge(label: 'This device', color: AppColors.successGreen),
          const Icon(Icons.chevron_right_rounded, color: AppColors.grey300),
        ],
      ),
    );
  }
}
