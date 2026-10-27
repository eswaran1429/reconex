import 'package:flutter/material.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/section_card/section_card.dart';
import 'package:reconex/core/custom_widgets/status_badge/status_badge.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/core/utils/json_utils.dart';
import 'package:reconex/data/models/network.dart';

/// Missing values are shown as "Unknown", never guessed.
String orUnknown(String? value) => (value == null || value.isEmpty) ? 'Unknown' : value;

/// Title and detail for a change. Absence is worded as "not observed", never "offline".
({String title, String detail, IconData icon}) describeChange(NetworkChange change) {
  final before = asMap(change.before);
  final after = asMap(change.after);
  String host(Json m) => m['hostname'] != null ? '${m['hostname']} (${m['ipAddress']})' : asText(m['ipAddress']);
  String port(Json m) => '${asText(m['port'])}/${asText(m['protocol'])}';

  return switch (change.type) {
    'device_added' => (
      title: 'New device',
      detail: '${host(after)} was not seen in the previous scan',
      icon: Icons.add_circle_outline_rounded,
    ),
    'device_not_seen' => (
      title: 'Not observed in this scan',
      detail: '${host(before)} was seen before. It may be switched off or out of range.',
      icon: Icons.help_outline_rounded,
    ),
    'device_ip_changed' => (
      title: 'IP address changed',
      detail: '${asText(before['ipAddress'])} → ${asText(after['ipAddress'])}',
      icon: Icons.swap_horiz_rounded,
    ),
    'device_hostname_changed' => (
      title: 'Hostname changed',
      detail: '${orUnknown(before['hostname'] as String?)} → ${asText(after['hostname'])}',
      icon: Icons.badge_outlined,
    ),
    'port_opened' => (
      title: 'Port ${port(after)} open',
      detail: '${after['service'] ?? 'Unknown service'} on ${asText(after['ipAddress'])}',
      icon: Icons.lock_open_rounded,
    ),
    'port_closed' => (
      title: 'Port ${port(before)} no longer open',
      detail: '${before['service'] ?? 'Unknown service'} on ${asText(before['ipAddress'])}',
      icon: Icons.lock_outline_rounded,
    ),
    _ => (title: humanize(change.type), detail: '', icon: Icons.change_circle_outlined),
  };
}

class NetworkChangeTile extends StatelessWidget {
  final NetworkChange change;
  final VoidCallback? onTap;

  const NetworkChangeTile({super.key, required this.change, this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = describeChange(change);
    final color = severityColor(change.severity);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: AppRadius.rSm),
              child: Icon(d.icon, color: color, size: 20),
            ),
            AppSpacing.md.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: d.title,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.normalText,
                    textAlign: TextAlign.left,
                  ),
                  if (d.detail.isNotEmpty) ...[
                    2.height,
                    CustomText(text: d.detail, fontSize: 12, color: AppColors.grey500, textAlign: TextAlign.left),
                  ],
                ],
              ),
            ),
            AppSpacing.sm.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge.severity(change.severity),
                4.height,
                CustomText(text: timeAgo(change.createdAt), fontSize: 11, color: AppColors.grey400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card for a device (inventory) or an observation (one scan).
class DeviceCard extends StatelessWidget {
  final String ipAddress;
  final String? hostname;
  final bool addressOnly;
  final int openPorts;
  final String? status;
  final String trailing;
  final VoidCallback onTap;

  const DeviceCard({
    super.key,
    required this.ipAddress,
    required this.hostname,
    required this.addressOnly,
    required this.openPorts,
    required this.trailing,
    required this.onTap,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final notSeen = status == 'not_seen';
    return SectionCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: notSeen ? AppColors.grey100 : AppColors.blue50,
              borderRadius: AppRadius.rSm,
            ),
            child: Icon(Icons.devices_other_rounded, color: notSeen ? AppColors.grey400 : AppColors.blue500),
          ),
          AppSpacing.md.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: hostname ?? ipAddress,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.normalText,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                4.height,
                CustomText(
                  text: [
                    if (hostname != null) ipAddress,
                    '$openPorts open ${openPorts == 1 ? 'port' : 'ports'}',
                    trailing,
                  ].join(' · '),
                  fontSize: 12,
                  color: AppColors.grey500,
                  textAlign: TextAlign.left,
                ),
                if (addressOnly) ...[
                  2.height,
                  const CustomText(
                    text: 'Identified by address only',
                    fontSize: 11,
                    color: AppColors.grey400,
                    textAlign: TextAlign.left,
                  ),
                ],
              ],
            ),
          ),
          if (notSeen) const StatusBadge(label: 'Not seen', color: AppColors.grey500),
          const Icon(Icons.chevron_right_rounded, color: AppColors.grey300),
        ],
      ),
    );
  }
}

class PortChip extends StatelessWidget {
  final NetworkPort port;

  const PortChip({super.key, required this.port});

  @override
  Widget build(BuildContext context) {
    final color = switch (port.state) {
      'open' => AppColors.successGreen,
      'closed' => AppColors.grey500,
      _ => AppColors.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.rSm,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: CustomText(
        text: '${port.port}/${port.protocol} ${port.service ?? ''} · ${port.state}'.replaceAll('  ', ' '),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}
