import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/app_widgets/app_widgets.dart';
import 'package:reconex/core/custom_widgets/custom_button/custom_button.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
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
import 'package:reconex/data/models/change.dart';
import 'package:reconex/features/changes/change_tile.dart';
import 'package:reconex/features/domain_detail/domain_detail_controller.dart';
import 'package:reconex/features/domain_detail/stat_sheets.dart';
import 'package:reconex/routes/app_routes.dart';

class DomainDetailScreen extends GetView<DomainDetailController> {
  const DomainDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.domain?.name ?? 'Domain')),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: AppColors.white,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.rSm),
            onSelected: (v) => v == 'edit' ? controller.edit() : controller.delete(),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: CustomText(text: 'Edit domain', textAlign: TextAlign.left),
              ),
              PopupMenuItem(
                value: 'delete',
                child: CustomText(text: 'Delete domain', color: AppColors.red500, textAlign: TextAlign.left),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const CardListSkeleton(count: 4);
        final error = controller.error.value;
        final data = controller.dashboard.value;
        if (error != null || data == null) {
          return ErrorState(message: error ?? 'No data', onRetry: controller.retry);
        }
        return AppRefreshIndicator(
          onRefresh: controller.load,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList.list(
                children: [
                  _HeaderCard(data: data, controller: controller),
                  AppSpacing.lg.height,
                  _StatsGrid(data: data, controller: controller),
                  AppSpacing.lg.height,
                  _IssuesCard(data: data, controller: controller),
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
  final DomainDetailController controller;

  const _HeaderCard({required this.data, required this.controller});

  @override
  Widget build(BuildContext context) {
    final domain = asMap(data['domain']);
    final lastScan = asMap(data['lastScan']);
    final lastScanAt = parseDate(data['lastScanAt']);
    final scanRunning = lastScan['status'] == 'QUEUED' || lastScan['status'] == 'RUNNING';

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
          Row(
            children: [
              Expanded(
                child: CustomText(
                  text: asText(domain['url']),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
                child: CustomText(
                  text: humanize(asText(domain['status'])),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor(asText(domain['status'])),
                ),
              ),
            ],
          ),
          AppSpacing.lg.height,
          const CustomText(text: 'Last scan', fontSize: 13, color: AppColors.white70, textAlign: TextAlign.left),
          4.height,
          CustomText(
            text: lastScanAt == null ? 'Never scanned' : timeAgo(lastScanAt),
            fontSize: AppTextTokens.titleSize + 2,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
            textAlign: TextAlign.left,
          ),
          if (lastScan['status'] != null && !scanRunning) ...[
            4.height,
            CustomText(
              text: '${humanize(asText(lastScan['status']))} · ${asInt(lastScan['changeCount'])} changes',
              fontSize: 13,
              color: AppColors.white70,
              textAlign: TextAlign.left,
            ),
          ],
          AppSpacing.xl.height,
          if (scanRunning)
            CustomButton(
              text: 'Scan in progress · View',
              color: AppColors.white,
              textColor: AppColors.amber700,
              icon: Icons.radar_rounded,
              onPressed: () => controller.openScan(asText(lastScan['id'])),
            )
          else
            Obx(
              () => CustomButton(
                text: 'Run full scan',
                color: AppColors.white,
                textColor: AppColors.amber700,
                icon: Icons.radar_rounded,
                loading: controller.isStartingScan.value,
                onPressed: controller.startScan,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Json data;
  final DomainDetailController controller;

  const _StatsGrid({required this.data, required this.controller});

  @override
  Widget build(BuildContext context) {
    final ssl = asMap(data['ssl']);
    void openSubdomains() => controller.open(AppRoutes.subdomains);

    final tiles = [
      _StatTile(
        icon: Icons.account_tree_outlined,
        color: AppColors.purple,
        value: '${asInt(asMap(data['subdomains'])['total'])}',
        label: 'Subdomains',
        onTap: openSubdomains,
      ),
      _StatTile(
        icon: Icons.settings_ethernet_rounded,
        color: AppColors.orange,
        value: '${asInt(asMap(data['ports'])['open'])}',
        label: 'Open ports',
        onTap: () => StatSheets.ports(asMap(data['ports']), onViewAll: () => controller.open(AppRoutes.ports)),
      ),
      _StatTile(
        icon: Icons.dns_outlined,
        color: AppColors.blue500,
        value: '${asInt(asMap(data['dns'])['total'])}',
        label: 'DNS records',
        onTap: () => controller.open(AppRoutes.dns),
      ),
      _StatTile(
        icon: Icons.memory_rounded,
        color: AppColors.teal,
        value: '${asInt(asMap(data['technologies'])['total'])}',
        label: 'Technologies',
        onTap: () => StatSheets.technologies(
          asMap(data['technologies']),
          onViewAll: () => controller.open(AppRoutes.technologies),
        ),
      ),
      _StatTile(
        icon: Icons.lock_outline_rounded,
        color: AppColors.successGreen,
        value: '${asInt(ssl['valid'])}/${asInt(ssl['total'])}',
        label: 'Valid SSL certs',
        onTap: () => StatSheets.ssl(ssl, onViewSubdomains: openSubdomains),
      ),
      _StatTile(
        icon: Icons.notifications_active_outlined,
        color: AppColors.red500,
        value: '${asInt(asMap(data['alerts'])['lastSevenDays'])}',
        label: 'Alerts (7 days)',
        onTap: () => StatSheets.alerts(asMap(data['alerts'])),
      ),
    ];

    // Rows instead of a fixed-ratio grid, so tiles grow with text scale instead of overflowing.
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) AppSpacing.md.height,
          Row(
            children: [
              Expanded(child: tiles[i]),
              AppSpacing.md.width,
              Expanded(child: tiles[i + 1]),
            ],
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _StatTile({required this.icon, required this.color, required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          AppSpacing.sm.height,
          CustomText(
            text: value,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.normalText,
            textAlign: TextAlign.left,
          ),
          CustomText(
            text: label,
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

class _IssuesCard extends StatelessWidget {
  final Json data;
  final DomainDetailController controller;

  const _IssuesCard({required this.data, required this.controller});

  @override
  Widget build(BuildContext context) {
    final headers = asMap(data['securityHeaders']);
    final exposed = asMap(data['exposedResources']);
    final ssl = asMap(data['ssl']);
    final expiring = asList(ssl['expiringSoon']).length;
    final expired = asInt(ssl['expired']);

    return SectionCard(
      title: 'Security issues',
      child: Column(
        children: [
          _IssueRow(
            icon: Icons.http_rounded,
            title: 'Missing security headers',
            count: asList(headers['missing']).length,
            checked: headers['scannedAt'] != null,
            onTap: () => controller.openSecurity(0),
          ),
          _IssueRow(
            icon: Icons.folder_open_rounded,
            title: 'Exposed files',
            count: asList(exposed['accessible']).length,
            checked: exposed['scannedAt'] != null,
            onTap: () => controller.openSecurity(1),
          ),
          _IssueRow(
            icon: Icons.lock_clock_outlined,
            title: 'Expired or expiring SSL',
            count: expired + expiring,
            checked: asInt(ssl['total']) > 0,
            onTap: () => StatSheets.ssl(ssl, onViewSubdomains: () => controller.open(AppRoutes.subdomains)),
          ),
        ],
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final bool checked;
  final VoidCallback onTap;

  const _IssueRow({
    required this.icon,
    required this.title,
    required this.count,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = !checked
        ? AppColors.grey400
        : count > 0
        ? AppColors.red500
        : AppColors.successGreen;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.grey600),
            AppSpacing.md.width,
            Expanded(
              child: CustomText(
                text: title,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.normalText,
                textAlign: TextAlign.left,
              ),
            ),
            StatusBadge(label: !checked ? 'Not checked' : (count > 0 ? '$count found' : 'None'), color: color),
            const Icon(Icons.chevron_right_rounded, color: AppColors.grey300, size: 20),
          ],
        ),
      ),
    );
  }
}

class _RecentChangesCard extends StatelessWidget {
  final Json data;
  final DomainDetailController controller;

  const _RecentChangesCard({required this.data, required this.controller});

  @override
  Widget build(BuildContext context) {
    final changes = asList(data['recentChanges']).take(5).map((e) => Change.fromJson(asMap(e))).toList();

    return SectionCard(
      title: 'Recent changes',
      trailing: GestureDetector(
        onTap: controller.openChanges,
        child: const CustomText(text: 'See all', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.amber700),
      ),
      child: changes.isEmpty
          ? const CustomText(
              text: 'No changes yet. Changes are recorded from the second scan onward.',
              fontSize: 13,
              color: AppColors.grey500,
              textAlign: TextAlign.left,
              height: 1.4,
            )
          : Column(
              children: [
                for (final change in changes)
                  ChangeTile(
                    change: change,
                    onTap: () => controller.open(AppRoutes.changeDetail, arguments: change.id),
                  ),
              ],
            ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final DomainDetailController controller;

  const _ExploreCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Explore',
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.lg, AppSpacing.sm, AppSpacing.sm),
      child: Column(
        children: [
          buildSettingsTile(
            icon: Icons.history_rounded,
            iconColor: AppColors.amber700,
            iconBgColor: AppColors.amber50,
            title: 'Scan history',
            subtitle: 'Every full scan and its results',
            onTap: () => controller.open(AppRoutes.scans),
          ),
          buildSettingsTile(
            icon: Icons.change_circle_outlined,
            iconColor: AppColors.purple,
            iconBgColor: AppColors.purple.withValues(alpha: 0.1),
            title: 'Changes',
            subtitle: 'Differences found between scans',
            onTap: controller.openChanges,
          ),
          buildSettingsTile(
            icon: Icons.account_tree_outlined,
            iconColor: AppColors.teal,
            iconBgColor: AppColors.tealLight,
            title: 'Subdomains',
            subtitle: 'Hosts, ports, SSL and technologies',
            onTap: () => controller.open(AppRoutes.subdomains),
          ),
          buildSettingsTile(
            icon: Icons.dns_outlined,
            iconColor: AppColors.blue500,
            iconBgColor: AppColors.blue50,
            title: 'DNS records',
            subtitle: 'A, AAAA, CNAME, MX, NS, TXT, SOA',
            onTap: () => controller.open(AppRoutes.dns),
          ),
          buildSettingsTile(
            icon: Icons.shield_outlined,
            iconColor: AppColors.red500,
            iconBgColor: AppColors.red50,
            title: 'Security checks',
            subtitle: 'Security headers and exposed files',
            onTap: () => controller.openSecurity(0),
          ),
        ],
      ),
    );
  }
}
