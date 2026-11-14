import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/refresh_indicator/app_refresh_indicator.dart';
import 'package:reconex/core/custom_widgets/section_card/section_card.dart';
import 'package:reconex/core/custom_widgets/shimmer/shimmer.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/data/models/lan_device.dart';
import 'package:reconex/data/services/auth_service.dart';
import 'package:reconex/data/services/lan_scan_service.dart';
import 'package:reconex/features/alerts/alerts_controller.dart';
import 'package:reconex/features/alerts/alerts_tab.dart';
import 'package:reconex/features/domains/domains_controller.dart';
import 'package:reconex/routes/app_routes.dart';

/// Dashboard state: who's signed in and which Wi-Fi the phone is on.
/// Domain and alert data come from their own controllers, shared with the full pages.
class HomeController extends GetxController {
  final AuthService _auth = Get.find();
  final LanScanService _lan = Get.find();

  final Rxn<({String name, String email})> user = Rxn();
  final Rxn<LanSelf> wifi = Rxn<LanSelf>();

  @override
  void onInit() {
    super.onInit();
    _auth.currentUser().then((u) => user.value = u);
    readWifi();
  }

  /// Reads the Wi-Fi without asking for permission; the SSID stays null until the
  /// Networks page has been granted location once.
  Future<void> readWifi() async {
    try {
      wifi.value = await _lan.currentNetwork();
    } catch (_) {
      wifi.value = const LanSelf();
    }
  }

  Future<void> refreshAll() =>
      Future.wait([Get.find<DomainsController>().load(), Get.find<AlertsController>().refreshList(), readWifi()]);

  String get greeting {
    final h = DateTime.now().hour;
    final part = h < 12 ? 'Good morning' : (h < 17 ? 'Good afternoon' : 'Good evening');
    final first = (user.value?.name ?? '').trim().split(RegExp(r'\s+')).first;
    return first.isEmpty ? part : '$part, $first';
  }

  String get initials {
    final parts = (user.value?.name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  Future<void> open(String route) async {
    await Get.toNamed(route);
    // The Networks page may have just been granted location, which reveals the SSID.
    if (route == AppRoutes.networks || route == AppRoutes.roomSweep) readWifi();
  }
}

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final domains = Get.find<DomainsController>();
    final alerts = Get.find<AlertsController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: AppRefreshIndicator(
          onRefresh: controller.refreshAll,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
              sliver: SliverList.list(
                children: [
                  _Header(controller: controller),
                  AppSpacing.xl.height,
                  _Overview(controller: controller, domains: domains, alerts: alerts),
                  AppSpacing.xl.height,
                  _CameraBanner(onOpen: controller.open),
                  AppSpacing.xl.height,
                  const _SectionLabel('Monitor'),
                  AppSpacing.md.height,
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Obx(
                            () => _ToolTile(
                              icon: Icons.language_rounded,
                              color: AppColors.amber700,
                              tint: AppColors.amber50,
                              title: 'Domains',
                              subtitle: domains.isLoading.value ? 'Loading…' : '${domains.domains.length} monitored',
                              onTap: () => controller.open(AppRoutes.domains),
                            ),
                          ),
                        ),
                        AppSpacing.md.width,
                        Expanded(
                          child: Obx(() {
                            final net = controller.wifi.value;
                            return _ToolTile(
                              icon: Icons.wifi_rounded,
                              color: AppColors.blue500,
                              tint: AppColors.blue500.withValues(alpha: 0.1),
                              title: 'Wi-Fi devices',
                              subtitle: net == null
                                  ? 'Checking…'
                                  : (net.onWifi ? (net.ssid ?? net.subnetLabel) : 'Not on Wi-Fi'),
                              onTap: () => controller.open(AppRoutes.networks),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.md.height,
                  // _RecentAlerts(alerts: alerts, onSeeAll: () => controller.open(AppRoutes.alerts)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final HomeController controller;

  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: AppRadius.rSm,
          child: Image.asset('assets/images/reconex_logo.png', height: 44, width: 44),
        ),
        AppSpacing.md.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                () => CustomText(
                  text: controller.greeting,
                  fontSize: 13,
                  color: AppColors.grey500,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              2.height,
              const CustomText(
                text: 'Reconex',
                fontSize: AppTextTokens.titleSize,
                fontWeight: FontWeight.bold,
                color: AppColors.normalText,
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
        _CircleButton(
          onTap: () => controller.open(AppRoutes.alerts),
          child: const Icon(Icons.notifications_none_rounded, color: AppColors.normalText, size: 22),
        ),
        AppSpacing.sm.width,
        GestureDetector(
          onTap: () => controller.open(AppRoutes.account),
          child: Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.gradientButton),
            child: Obx(
              () => CustomText(
                text: controller.initials,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _CircleButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(height: 44, width: 44, child: Center(child: child)),
      ),
    );
  }
}

/// Dark summary card: the three numbers people check first.
class _Overview extends StatelessWidget {
  final HomeController controller;
  final DomainsController domains;
  final AlertsController alerts;

  const _Overview({required this.controller, required this.domains, required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: AppRadius.rMd,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkSlate, AppColors.charcoal],
        ),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
              AppSpacing.sm.width,
              const CustomText(
                text: 'Security overview',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ],
          ),
          AppSpacing.xl.height,
          Obx(() {
            final net = controller.wifi.value;
            return Row(
              children: [
                _Stat(value: domains.isLoading.value ? null : '${domains.domains.length}', label: 'Domains'),
                const _StatDivider(),
                _Stat(value: alerts.isLoading.value ? null : '${alerts.total.value}', label: 'Alerts'),
                const _StatDivider(),
                _Stat(
                  value: net == null ? null : (net.onWifi ? 'On' : 'Off'),
                  label: 'Wi-Fi',
                  valueColor: net?.onWifi == true ? AppColors.successGreen : AppColors.grey400,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  /// Null while loading.
  final String? value;
  final String label;
  final Color valueColor;

  const _Stat({required this.value, required this.label, this.valueColor = AppColors.white});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 32,
            child: value == null
                ? const Center(
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white70),
                    ),
                  )
                : CustomText(text: value!, fontSize: 26, fontWeight: FontWeight.bold, color: valueColor),
          ),
          4.height,
          CustomText(text: label, fontSize: 12, color: AppColors.white70),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => Container(width: 1, height: 36, color: AppColors.white.withValues(alpha: 0.12));
}

/// Featured entry for the hidden-camera sweep, with shortcuts to each tool.
class _CameraBanner extends StatelessWidget {
  final Future<void> Function(String route) onOpen;

  const _CameraBanner({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: () => onOpen(AppRoutes.roomSweep),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(color: AppColors.red50, borderRadius: AppRadius.rSm),
                child: const Icon(Icons.videocam_rounded, color: AppColors.red500, size: 28),
              ),
              AppSpacing.md.width,
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: 'Hidden camera detector',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.normalText,
                      textAlign: TextAlign.left,
                    ),
                    SizedBox(height: 4),
                    CustomText(
                      text: 'Sweep a hotel room or rental in a few minutes',
                      fontSize: 13,
                      color: AppColors.grey500,
                      textAlign: TextAlign.left,
                      height: 1.35,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.grey300),
            ],
          ),
          AppSpacing.lg.height,
          Row(
            children: [
              Expanded(
                child: _Shortcut(
                  icon: Icons.wifi_find_rounded,
                  label: 'Network',
                  onTap: () => onOpen(AppRoutes.cameraDetector),
                ),
              ),
              AppSpacing.sm.width,
              Expanded(
                child: _Shortcut(
                  icon: Icons.flashlight_on_rounded,
                  label: 'Lens / IR',
                  onTap: () => onOpen(AppRoutes.lensFinder),
                ),
              ),
              AppSpacing.sm.width,
              Expanded(
                child: _Shortcut(
                  icon: Icons.explore_rounded,
                  label: 'Magnetic',
                  onTap: () => onOpen(AppRoutes.magnetometer),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Shortcut({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.grey100,
      borderRadius: AppRadius.rSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            children: [
              Icon(icon, size: 20, color: AppColors.grey700),
              4.height,
              CustomText(text: label, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey700),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolTile({
    required this.icon,
    required this.color,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(color: tint, borderRadius: AppRadius.rSm),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              const Icon(Icons.arrow_outward_rounded, color: AppColors.grey300, size: 18),
            ],
          ),
          AppSpacing.md.height,
          CustomText(
            text: title,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.normalText,
            textAlign: TextAlign.left,
          ),
          2.height,
          CustomText(
            text: subtitle,
            fontSize: 12,
            color: AppColors.grey500,
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const _SectionLabel(this.text, {this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomText(
            text: text,
            fontSize: AppTextTokens.titleSmSize,
            fontWeight: FontWeight.bold,
            color: AppColors.normalText,
            textAlign: TextAlign.left,
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _RecentAlerts extends StatelessWidget {
  final AlertsController alerts;
  final VoidCallback onSeeAll;

  const _RecentAlerts({required this.alerts, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          'Recent alerts',
          trailing: TextButton(
            onPressed: onSeeAll,
            child: const CustomText(
              text: 'See all',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.amber700,
            ),
          ),
        ),
        AppSpacing.sm.height,
        Obx(() {
          if (alerts.isLoading.value && alerts.items.isEmpty) {
            return const Shimmer(child: SkeletonBox(height: 96, radius: AppRadius.md));
          }
          if (alerts.items.isEmpty) {
            return SectionCard(
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: AppColors.successGreen),
                  AppSpacing.md.width,
                  Expanded(
                    child: CustomText(
                      text: alerts.error.value == null
                          ? 'No alerts. Scans will report risky changes here.'
                          : 'Couldn\'t load alerts.',
                      fontSize: 13,
                      color: AppColors.grey600,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            );
          }
          final recent = alerts.items.take(3).toList();
          return Column(
            children: [
              for (final a in recent) ...[AlertCard(alert: a, onTap: () => alerts.openAlert(a)), AppSpacing.md.height],
            ],
          );
        }),
      ],
    );
  }
}
