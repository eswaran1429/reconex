import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_button/custom_button.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/status_badge/status_badge.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/core/utils/json_utils.dart';
import 'package:reconex/data/models/severity.dart';

// Breakdown sheets for the dashboard stat tiles. Data comes from the
// already-loaded `/domain/dashboard/:id` payload; the action buttons open the
// full lists.

class StatSheets {
  StatSheets._();

  /// `ports: { open, byPort: { "443/https": 3 } }`
  static void ports(Json ports, {required VoidCallback onViewAll}) {
    final byPort = asMap(ports['byPort']).entries.toList()..sort((a, b) => asInt(b.value).compareTo(asInt(a.value)));
    _show(
      title: 'Open ports',
      subtitle: '${asInt(ports['open'])} open across all subdomains',
      empty: 'No open ports found yet. Run a full scan to probe ports.',
      rows: [
        for (final e in byPort)
          _Row(
            icon: Icons.settings_ethernet_rounded,
            color: AppColors.orange,
            title: e.key,
            trailing: '${asInt(e.value)} ${asInt(e.value) == 1 ? 'host' : 'hosts'}',
          ),
      ],
      actionLabel: 'All ports',
      onAction: onViewAll,
    );
  }

  /// `technologies: { total, items: [{ name, category, versions, subdomains }] }`
  static void technologies(Json technologies, {required VoidCallback onViewAll}) {
    final items = asList(technologies['items']).map(asMap).toList();
    _show(
      title: 'Technologies',
      subtitle: '${asInt(technologies['total'])} detected',
      empty: 'No technologies detected yet. Run a full scan to fingerprint the sites.',
      rows: [
        for (final t in items)
          _Row(
            icon: Icons.memory_rounded,
            color: AppColors.teal,
            title: asText(t['name']),
            subtitle: [
              if (t['category'] != null) humanize(asText(t['category'])),
              if (asList(t['versions']).isNotEmpty) 'v${asList(t['versions']).join(', v')}',
            ].join(' · '),
            trailing: _countLabel(t['subdomains'], 'host'),
          ),
      ],
      actionLabel: 'All technologies',
      onAction: onViewAll,
    );
  }

  /// `ssl: { total, valid, invalid, expired, expiringSoon: [], nextExpiry: { hostname, expiresAt } }`
  static void ssl(Json ssl, {required VoidCallback onViewSubdomains}) {
    final next = asMap(ssl['nextExpiry']);
    final expiring = asList(ssl['expiringSoon']).map(asMap).toList();
    _show(
      title: 'SSL certificates',
      subtitle: '${asInt(ssl['valid'])} of ${asInt(ssl['total'])} valid',
      empty: 'No certificates checked yet. Run a full scan to inspect SSL.',
      rows: asInt(ssl['total']) == 0
          ? const []
          : [
              _Row(
                icon: Icons.verified_outlined,
                color: AppColors.successGreen,
                title: 'Valid',
                trailing: '${asInt(ssl['valid'])}',
              ),
              _Row(
                icon: Icons.gpp_bad_outlined,
                color: AppColors.red500,
                title: 'Invalid',
                trailing: '${asInt(ssl['invalid'])}',
              ),
              _Row(
                icon: Icons.event_busy_outlined,
                color: AppColors.red500,
                title: 'Expired',
                trailing: '${asInt(ssl['expired'])}',
              ),
              if (next.isNotEmpty)
                _Row(
                  icon: Icons.schedule_rounded,
                  color: AppColors.blue500,
                  title: 'Next expiry',
                  subtitle: asText(next['hostname']),
                  trailing: formatDate(parseDate(next['expiresAt'])),
                ),
              for (final cert in expiring)
                _Row(
                  icon: Icons.lock_clock_outlined,
                  color: AppColors.warning,
                  title: asText(cert['hostname'] ?? cert['subject']),
                  subtitle: 'Expires within 30 days',
                  trailing: formatDate(parseDate(cert['expiresAt'])),
                ),
            ],
      actionLabel: 'Certificates per subdomain',
      onAction: onViewSubdomains,
    );
  }

  /// `alerts: { total, lastSevenDays, bySeverity: {}, recent: [] }`
  static void alerts(Json alerts) {
    final recent = asList(alerts['recent']).map(asMap).toList();
    _show(
      title: 'Alerts',
      subtitle: '${asInt(alerts['lastSevenDays'])} in the last 7 days · ${asInt(alerts['total'])} total',
      empty: 'No alerts for this domain.',
      rows: [
        for (final a in recent)
          _Row(
            icon: Icons.notifications_active_outlined,
            color: severityColor(Severity.tryParse(a['severity'])),
            title: asText(a['title']),
            subtitle: '${asText(a['message'])}\n${timeAgo(parseDate(a['createdAt']))}',
            badge: StatusBadge.severity(Severity.tryParse(a['severity'])),
          ),
      ],
    );
  }

  /// `subdomains` may be a count or a list of hostnames.
  static String? _countLabel(Object? value, String noun) {
    final n = value is List ? value.length : (value is num ? value.toInt() : null);
    if (n == null) return null;
    return '$n ${n == 1 ? noun : '${noun}s'}';
  }

  static void _show({
    required String title,
    required String subtitle,
    required String empty,
    required List<_Row> rows,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    Get.bottomSheet<void>(
      _StatSheet(
        title: title,
        subtitle: subtitle,
        empty: empty,
        rows: rows,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    );
  }
}

class _StatSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String empty;
  final List<_Row> rows;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatSheet({
    required this.title,
    required this.subtitle,
    required this.empty,
    required this.rows,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              AppSpacing.xl.height,
              CustomText(
                text: title,
                fontSize: AppTextTokens.titleSize,
                fontWeight: FontWeight.bold,
                color: AppColors.normalText,
                textAlign: TextAlign.left,
              ),
              4.height,
              CustomText(text: subtitle, fontSize: 13, color: AppColors.grey500, textAlign: TextAlign.left),
              AppSpacing.lg.height,
              Flexible(
                child: rows.isEmpty
                    ? CustomText(text: empty, fontSize: 14, color: AppColors.grey500, textAlign: TextAlign.left)
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: rows.length,
                        separatorBuilder: (_, _) => const Divider(height: AppSpacing.lg, color: AppColors.grey100),
                        itemBuilder: (_, i) => rows[i],
                      ),
              ),
              if (actionLabel != null && onAction != null) ...[
                AppSpacing.xl.height,
                CustomButton(
                  text: actionLabel!,
                  color: AppColors.amber50,
                  textColor: AppColors.amber700,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    // Navigator.pop, not Get.back: Get.back closes an open snackbar instead of the sheet.
                    Navigator.of(context).pop();
                    onAction!();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final String? trailing;
  final Widget? badge;

  const _Row({required this.icon, required this.color, required this.title, this.subtitle, this.trailing, this.badge});

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;
    return Row(
      crossAxisAlignment: hasSubtitle ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
        AppSpacing.md.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: title,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.normalText,
                textAlign: TextAlign.left,
              ),
              if (hasSubtitle) ...[
                2.height,
                CustomText(text: subtitle!, fontSize: 12, color: AppColors.grey500, textAlign: TextAlign.left),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          AppSpacing.sm.width,
          CustomText(text: trailing!, fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.grey700),
        ],
        if (badge != null) ...[AppSpacing.sm.width, badge!],
      ],
    );
  }
}
