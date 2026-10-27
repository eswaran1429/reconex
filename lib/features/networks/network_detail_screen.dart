import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/app_widgets/app_widgets.dart';
import 'package:reconex/core/custom_widgets/confirm_dialog/confirm_dialog.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/refresh_indicator/app_refresh_indicator.dart';
import 'package:reconex/core/custom_widgets/section_card/section_card.dart';
import 'package:reconex/core/custom_widgets/state_views/state_views.dart';
import 'package:reconex/core/custom_widgets/status_badge/status_badge.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/core/utils/json_utils.dart';
import 'package:reconex/data/models/network.dart';
import 'package:reconex/data/services/network_service.dart';
import 'package:reconex/features/networks/network_form_sheet.dart';
import 'package:reconex/features/networks/network_widgets.dart';
import 'package:reconex/routes/app_routes.dart';

class NetworkDetailController extends GetxController {
  final NetworkService _networkService = Get.find();
  final String networkId = Get.arguments as String;

  final Rxn<Json> dashboard = Rxn<Json>();
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  String get name => asMap(dashboard.value?['network'])['name'] as String? ?? 'Network';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      dashboard.value = await _networkService.dashboard(networkId);
      error.value = null;
    } catch (e) {
      if (dashboard.value == null) {
        error.value = e.toString();
      } else {
        AppSnackbar.warning('Refresh failed', e.toString());
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> retry() {
    isLoading.value = true;
    error.value = null;
    return load();
  }

  Future<void> open(String route, {Object? arguments}) async {
    await Get.toNamed(route, arguments: arguments ?? networkId);
    load();
  }

  Future<void> rename() async {
    final network = asMap(dashboard.value?['network']);
    final profile = NetworkProfile(id: networkId, name: name, subnet: asText(network['subnet']));
    if (await NetworkFormSheet.show(network: profile) == true) load();
  }

  Future<void> delete() async {
    final confirmed = await AppConfirmDialog.show(
      title: 'Delete $name?',
      message: 'This also deletes its scan history, devices, changes and alerts. This cannot be undone.',
      confirmText: 'Delete',
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed) return;
    try {
      await _networkService.delete(networkId);
      Get.until((route) => route.settings.name == AppRoutes.home);
      AppSnackbar.success('Network deleted', name);
    } catch (e) {
      AppSnackbar.warning('Delete failed', e.toString());
    }
  }
}

class NetworkDetailScreen extends GetView<NetworkDetailController> {
  const NetworkDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.dashboard.value == null ? 'Network' : controller.name)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: AppColors.white,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.rSm),
            onSelected: (v) => v == 'rename' ? controller.rename() : controller.delete(),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'rename',
                child: CustomText(text: 'Rename network', textAlign: TextAlign.left),
              ),
              PopupMenuItem(
                value: 'delete',
                child: CustomText(text: 'Delete network', color: AppColors.red500, textAlign: TextAlign.left),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const CardListSkeleton(count: 4);
        final data = controller.dashboard.value;
        if (data == null) return ErrorState(message: controller.error.value ?? 'No data', onRetry: controller.retry);

        return AppRefreshIndicator(
          onRefresh: controller.load,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList.list(
                children: [
                  _HeaderCard(data: data),
                  AppSpacing.lg.height,
                  _StatsRow(data: data, controller: controller),
                  AppSpacing.lg.height,
                  _PortsCard(data: data),
                  AppSpacing.lg.height,
                  _RecentChangesCard(data: data, controller: controller),
                  AppSpacing.lg.height,
                  _ExploreCard(controller: controller),
                  AppSpacing.xxl.height,
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Json data;

  const _HeaderCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final network = asMap(data['network']);
    final lastScan = asMap(data['lastScan']);
    final lastScanAt = parseDate(data['lastScanAt']);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.gradientButton,
        borderRadius: AppRadius.rLg,
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: asText(network['subnet']),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.white,
            textAlign: TextAlign.left,
          ),
          AppSpacing.lg.height,
          const CustomText(text: 'Last scan', fontSize: 13, color: AppColors.white70, textAlign: TextAlign.left),
          4.height,
          CustomText(
            text: lastScanAt == null ? 'No scans yet' : '${timeAgo(lastScanAt)} · ${formatDateTime(lastScanAt)}',
            fontSize: AppTextTokens.titleSmSize,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
            textAlign: TextAlign.left,
          ),
          if (lastScan['status'] != null) ...[
            4.height,
            CustomText(
              text: '${humanize(asText(lastScan['status']))} · ${asInt(lastScan['changeCount'])} changes',
              fontSize: 13,
              color: AppColors.white70,
              textAlign: TextAlign.left,
            ),
          ],
          AppSpacing.lg.height,
          // Scanning from the phone isn't part of this version, so no scan button.
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.2), borderRadius: AppRadius.rSm),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.white, size: 18),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: CustomText(
                    text:
                        'Scanning from this phone isn\'t available yet. Results already saved for this network are shown here.',
                    fontSize: 12,
                    color: AppColors.white,
                    textAlign: TextAlign.left,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Json data;
  final NetworkDetailController controller;

  const _StatsRow({required this.data, required this.controller});

  @override
  Widget build(BuildContext context) {
    final devices = asMap(data['devices']);
    final seen = devices['seenLastScan'];
    Widget tile(String value, String label, IconData icon, Color color, VoidCallback onTap) => Expanded(
      child: SectionCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            AppSpacing.sm.height,
            CustomText(text: value, fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.normalText),
            CustomText(text: label, fontSize: 12, color: AppColors.grey500, textAlign: TextAlign.left),
          ],
        ),
      ),
    );

    return Row(
      children: [
        tile(
          '${asInt(devices['total'])}',
          'Known devices',
          Icons.devices_other_rounded,
          AppColors.blue500,
          () => controller.open(AppRoutes.networkDevices),
        ),
        AppSpacing.md.width,
        tile(
          seen == null ? '—' : '$seen',
          'Seen last scan',
          Icons.visibility_outlined,
          AppColors.successGreen,
          () => controller.open(AppRoutes.networkDevices),
        ),
        AppSpacing.md.width,
        tile(
          '${asInt(devices['newLastSevenDays'])}',
          'New (7 days)',
          Icons.fiber_new_outlined,
          AppColors.orange,
          () => controller.open(AppRoutes.networkChanges),
        ),
      ],
    );
  }
}

class _PortsCard extends StatelessWidget {
  final Json data;

  const _PortsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final ports = asMap(data['ports']);
    final byPort = asMap(ports['byPort']).entries.toList()..sort((a, b) => asInt(b.value).compareTo(asInt(a.value)));
    return SectionCard(
      title: 'Open ports',
      trailing: CustomText(text: '${asInt(ports['open'])}', fontSize: 13, color: AppColors.grey500),
      child: byPort.isEmpty
          ? const CustomText(
              text: 'No open ports in the latest scan. An open port is an observation, not a vulnerability.',
              fontSize: 13,
              color: AppColors.grey500,
              textAlign: TextAlign.left,
              height: 1.4,
            )
          : Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final e in byPort)
                  StatusBadge(label: '${e.key} · ${asInt(e.value)}', color: AppColors.successGreen),
              ],
            ),
    );
  }
}

class _RecentChangesCard extends StatelessWidget {
  final Json data;
  final NetworkDetailController controller;

  const _RecentChangesCard({required this.data, required this.controller});

  @override
  Widget build(BuildContext context) {
    final changes = asList(data['recentChanges']).take(5).map((e) => NetworkChange.fromJson(asMap(e))).toList();
    return SectionCard(
      title: 'Recent changes',
      trailing: GestureDetector(
        onTap: () => controller.open(AppRoutes.networkChanges),
        child: const CustomText(text: 'See all', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.amber700),
      ),
      child: changes.isEmpty
          ? const CustomText(
              text: 'No changes yet. Changes are recorded from the second completed scan onward.',
              fontSize: 13,
              color: AppColors.grey500,
              textAlign: TextAlign.left,
              height: 1.4,
            )
          : Column(children: [for (final change in changes) NetworkChangeTile(change: change)]),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final NetworkDetailController controller;

  const _ExploreCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Explore',
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.lg, AppSpacing.sm, AppSpacing.sm),
      child: Column(
        children: [
          buildSettingsTile(
            icon: Icons.devices_other_rounded,
            iconColor: AppColors.blue500,
            iconBgColor: AppColors.blue50,
            title: 'Devices',
            subtitle: 'Every device seen on this network',
            onTap: () => controller.open(AppRoutes.networkDevices),
          ),
          buildSettingsTile(
            icon: Icons.history_rounded,
            iconColor: AppColors.amber700,
            iconBgColor: AppColors.amber50,
            title: 'Scan history',
            subtitle: 'Saved scans and what each one found',
            onTap: () => controller.open(AppRoutes.networkScans),
          ),
          buildSettingsTile(
            icon: Icons.change_circle_outlined,
            iconColor: AppColors.purple,
            iconBgColor: AppColors.purple.withValues(alpha: 0.1),
            title: 'Changes',
            subtitle: 'Differences between scans',
            onTap: () => controller.open(AppRoutes.networkChanges),
          ),
        ],
      ),
    );
  }
}
