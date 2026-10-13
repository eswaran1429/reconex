import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/section_card/section_card.dart';
import 'package:reconex/core/custom_widgets/state_views/state_views.dart';
import 'package:reconex/core/custom_widgets/status_badge/status_badge.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/core/utils/json_utils.dart';
import 'package:reconex/features/subdomains/subdomain_detail_controller.dart';

class SubdomainDetailScreen extends GetView<SubdomainDetailController> {
  const SubdomainDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Obx(() => Text(controller.subdomain.value?.hostname ?? 'Subdomain'))),
      body: Obx(() {
        if (controller.isLoading.value) return const CardListSkeleton(count: 3);
        final subdomain = controller.subdomain.value;
        if (subdomain == null) {
          return ErrorState(message: controller.error.value ?? 'No data', onRetry: controller.load);
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            SectionCard(
              title: 'Host',
              trailing: subdomain.status.isEmpty ? null : StatusBadge.status(subdomain.status),
              child: Column(
                children: [
                  InfoRow(label: 'Hostname', value: subdomain.hostname),
                  InfoRow(label: 'IP address', value: subdomain.ipAddress ?? '—'),
                  InfoRow(label: 'First seen', value: formatDateTime(subdomain.firstSeenAt)),
                  InfoRow(label: 'Last seen', value: formatDateTime(subdomain.lastSeenAt)),
                ],
              ),
            ),
            AppSpacing.lg.height,
            _PortsCard(controller: controller),
            AppSpacing.lg.height,
            _SslCard(controller: controller),
            AppSpacing.lg.height,
            _TechnologiesCard(controller: controller),
            AppSpacing.xxl.height,
          ],
        );
      }),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  final Color color;

  const _Hint(this.text, {this.color = AppColors.grey500});

  @override
  Widget build(BuildContext context) =>
      CustomText(text: text, fontSize: 13, color: color, textAlign: TextAlign.left, height: 1.4);
}

class _PortsCard extends StatelessWidget {
  final SubdomainDetailController controller;

  const _PortsCard({required this.controller});

  static bool _isOpen(Json port) => asText(port['status'] ?? port['state']).toLowerCase() != 'closed';

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ports = controller.ports.toList();
      final openCount = ports.where(_isOpen).length;
      return SectionCard(
        title: 'Ports',
        trailing: SmallActionButton(
          label: 'Scan',
          icon: Icons.radar_rounded,
          loading: controller.isScanningPorts.value,
          onTap: controller.scanPorts,
        ),
        child: ports.isEmpty
            ? const _Hint('Not scanned yet. Probes 14 common TCP ports like 22, 80, 443, 3306 and 6379.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Hint('$openCount open of ${ports.length} checked'),
                  AppSpacing.md.height,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [for (final port in ports) _PortChip(port: port, open: _isOpen(port))],
                  ),
                ],
              ),
      );
    });
  }
}

class _PortChip extends StatelessWidget {
  final Json port;
  final bool open;

  const _PortChip({required this.port, required this.open});

  @override
  Widget build(BuildContext context) {
    final color = open ? AppColors.successGreen : AppColors.grey400;
    final service = port['service'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: open ? AppColors.successGreenLight : AppColors.grey50,
        borderRadius: AppRadius.rSm,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: CustomText(
        text: service == null ? asText(port['port']) : '${asText(port['port'])} ${asText(service)}',
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: open ? AppColors.successGreen : AppColors.grey500,
      ),
    );
  }
}

class _SslCard extends StatelessWidget {
  final SubdomainDetailController controller;

  const _SslCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ssl = controller.ssl.value;
      final error = controller.sslError.value;
      return SectionCard(
        title: 'SSL certificate',
        trailing: SmallActionButton(
          label: ssl == null ? 'Check' : 'Recheck',
          icon: Icons.lock_outline_rounded,
          loading: controller.isCheckingSsl.value,
          onTap: controller.checkSsl,
        ),
        child: error != null
            ? _Hint(error, color: AppColors.red500)
            : ssl == null
            ? const _Hint('Connects to port 443 and inspects the certificate.')
            : _sslDetails(ssl),
      );
    });
  }

  Widget _sslDetails(Json ssl) {
    final valid = ssl['valid'] == true;
    final expiresAt = parseDate(ssl['expiresAt']);
    final daysLeft = expiresAt?.difference(DateTime.now()).inDays;
    final expiryColor = daysLeft == null
        ? AppColors.normalText
        : daysLeft < 0
        ? AppColors.red500
        : daysLeft <= 30
        ? AppColors.warning
        : AppColors.normalText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusBadge(label: valid ? 'Valid' : 'Invalid', color: valid ? AppColors.successGreen : AppColors.red500),
        AppSpacing.sm.height,
        if (ssl['validationError'] != null)
          InfoRow(label: 'Problem', value: asText(ssl['validationError']), valueColor: AppColors.red500),
        InfoRow(label: 'Issuer', value: asText(ssl['issuer'])),
        InfoRow(label: 'Subject', value: asText(ssl['subject'])),
        InfoRow(label: 'Valid from', value: formatDate(parseDate(ssl['validFrom']))),
        InfoRow(
          label: 'Expires',
          value: daysLeft == null ? '—' : '${formatDate(expiresAt)} (${daysLeft < 0 ? 'expired' : '$daysLeft days'})',
          valueColor: expiryColor,
        ),
        InfoRow(label: 'TLS', value: asText(ssl['tlsVersion'])),
        InfoRow(label: 'Fingerprint', value: asText(ssl['fingerprint'])),
      ],
    );
  }
}

class _TechnologiesCard extends StatelessWidget {
  final SubdomainDetailController controller;

  const _TechnologiesCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final technologies = controller.technologies.value;
      final error = controller.techError.value;
      return SectionCard(
        title: 'Technologies',
        trailing: SmallActionButton(
          label: technologies == null ? 'Detect' : 'Redetect',
          icon: Icons.memory_rounded,
          loading: controller.isDetectingTech.value,
          onTap: controller.detectTechnologies,
        ),
        child: error != null
            ? _Hint(error, color: AppColors.red500)
            : technologies == null
            ? const _Hint('Fingerprints the site for Nginx, Apache, Cloudflare, Express, Next.js, React and more.')
            : technologies.isEmpty
            ? const _Hint('No known technologies detected.')
            : Column(
                children: [
                  for (final tech in technologies)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.memory_rounded, size: 18, color: AppColors.teal),
                          AppSpacing.md.width,
                          Expanded(
                            child: CustomText(
                              text: asText(tech['name']),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.normalText,
                              textAlign: TextAlign.left,
                            ),
                          ),
                          if (tech['version'] != null) ...[
                            CustomText(text: 'v${asText(tech['version'])}', fontSize: 12, color: AppColors.grey600),
                            AppSpacing.sm.width,
                          ],
                          if (tech['category'] != null)
                            StatusBadge(label: humanize(asText(tech['category'])), color: AppColors.teal),
                        ],
                      ),
                    ),
                ],
              ),
      );
    });
  }
}
