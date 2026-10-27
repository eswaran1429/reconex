import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_button/custom_button.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/filter_chips/filter_chips.dart';
import 'package:reconex/core/custom_widgets/section_card/section_card.dart';
import 'package:reconex/core/custom_widgets/state_views/state_views.dart';
import 'package:reconex/core/custom_widgets/status_badge/status_badge.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/core/utils/json_utils.dart';
import 'package:reconex/data/models/asset_graph.dart';
import 'package:reconex/data/models/severity.dart';
import 'package:reconex/data/services/domain_service.dart';
import 'package:reconex/routes/app_routes.dart';

class AssetMapController extends GetxController {
  final DomainService _domainService = Get.find();
  final String domainId = Get.arguments as String;

  final Rxn<AssetGraph> graph = Rxn<AssetGraph>();
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  /// Empty means every host is shown.
  final RxSet<Severity> severities = <Severity>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    error.value = null;
    try {
      graph.value = await _domainService.graph(domainId);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> retry() {
    isLoading.value = true;
    return load();
  }

  void toggleSeverity(Severity severity) {
    if (!severities.remove(severity)) severities.add(severity);
  }

  List<GraphSubdomain> get visible {
    final all = graph.value?.subdomains ?? const [];
    if (severities.isEmpty) return all;
    return all.where((s) => severities.contains(s.severity)).toList();
  }

  void openSubdomain(String subdomainId) => Get.toNamed(AppRoutes.subdomainDetail, arguments: subdomainId);
}

class AssetMapScreen extends GetView<AssetMapController> {
  const AssetMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attack surface map')),
      body: Obx(() {
        if (controller.isLoading.value) return const CardListSkeleton(count: 3);
        final graph = controller.graph.value;
        if (graph == null) {
          return ErrorState(message: controller.error.value ?? 'No data', onRetry: controller.retry);
        }
        if (graph.subdomains.isEmpty) {
          return const EmptyState(
            icon: Icons.hub_outlined,
            title: 'Nothing to map yet',
            message: 'Run a full scan to discover subdomains, ports, certificates and technologies.',
          );
        }
        final visible = controller.visible;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.sm.height,
            _SeverityFilter(graph: graph, controller: controller),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: CustomText(
                text: '${_hostCount(visible.length)} on ${_ipCount(visible)} · pinch to zoom, tap a host for details',
                fontSize: 12,
                color: AppColors.grey500,
                textAlign: TextAlign.left,
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? const EmptyState(
                      icon: Icons.filter_alt_off_outlined,
                      title: 'No hosts match',
                      message: 'No host has the selected severity. Clear the filter to see every host.',
                    )
                  : _MapView(
                      // A new layout gets a fresh view, so it is fitted to the screen again.
                      key: ValueKey(visible.map((s) => s.id).join(',')),
                      layout: _MapLayout.compute(visible),
                      domainName: graph.domain.name,
                      baseHost: Uri.tryParse(graph.domain.url)?.host ?? graph.domain.name,
                      onTapHost: (s) => _HostSheet.show(s, onOpen: () => controller.openSubdomain(s.id)),
                    ),
            ),
          ],
        );
      }),
    );
  }

  static String _hostCount(int n) => '$n ${n == 1 ? 'host' : 'hosts'}';

  static String _ipCount(List<GraphSubdomain> subs) {
    final n = subs.map((s) => s.ipAddress).toSet().length;
    return '$n ${n == 1 ? 'IP' : 'IPs'}';
  }
}

class _SeverityFilter extends StatelessWidget {
  final AssetGraph graph;
  final AssetMapController controller;

  const _SeverityFilter({required this.graph, required this.controller});

  @override
  Widget build(BuildContext context) {
    const values = Severity.values;
    return Obx(() {
      final selected = controller.severities.toSet();
      return FilterChipRow(
        labels: [for (final s in values) '${humanize(s.name)} ${graph.bySeverity[s] ?? 0}'],
        isSelected: (i) => selected.contains(values[i]),
        onTap: (i) => controller.toggleSeverity(values[i]),
        colorOf: (i) => severityColor(values[i]),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Layout: domain in the centre, one hub per IP address on an inner ring, and
// each host on an outer ring inside its IP's slice. Slices are sized by how
// many hosts share the IP, so hosts on the same server sit together.
// ---------------------------------------------------------------------------

class _PlacedHub {
  final String? ip;
  final Offset position;

  const _PlacedHub(this.ip, this.position);
}

class _PlacedHost {
  final GraphSubdomain subdomain;
  final Offset position;
  final int hub;

  const _PlacedHost(this.subdomain, this.position, this.hub);
}

class _MapLayout {
  static const double _hostSpacing = 104;
  static const double _margin = 96;

  final double size;
  final List<_PlacedHub> hubs;
  final List<_PlacedHost> hosts;

  const _MapLayout(this.size, this.hubs, this.hosts);

  Offset get center => Offset(size / 2, size / 2);

  factory _MapLayout.compute(List<GraphSubdomain> subdomains) {
    final groups = <String?, List<GraphSubdomain>>{};
    for (final s in subdomains) {
      groups.putIfAbsent(s.ipAddress, () => []).add(s);
    }
    final ordered = groups.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length));

    final total = subdomains.length;
    final outer = math.max(170.0, total * _hostSpacing / (2 * math.pi));
    final inner = math.max(100.0, outer * 0.5);
    final size = 2 * (outer + _margin);
    final center = Offset(size / 2, size / 2);
    Offset polar(double r, double a) => center + Offset(r * math.cos(a), r * math.sin(a));

    final hubs = <_PlacedHub>[];
    final hosts = <_PlacedHost>[];
    var angle = -math.pi / 2;
    for (final group in ordered) {
      final sweep = 2 * math.pi * group.value.length / total;
      hubs.add(_PlacedHub(group.key, polar(inner, angle + sweep / 2)));
      for (var j = 0; j < group.value.length; j++) {
        final a = angle + (j + 0.5) * sweep / group.value.length;
        hosts.add(_PlacedHost(group.value[j], polar(outer, a), hubs.length - 1));
      }
      angle += sweep;
    }
    return _MapLayout(size, hubs, hosts);
  }
}

class _MapView extends StatefulWidget {
  final _MapLayout layout;
  final String domainName;
  final String baseHost;
  final ValueChanged<GraphSubdomain> onTapHost;

  const _MapView({
    super.key,
    required this.layout,
    required this.domainName,
    required this.baseHost,
    required this.onTapHost,
  });

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  static const double _domainNode = 76;
  static const Size _hubSize = Size(120, 28);
  static const double _hostCircle = 48;
  static const double _hostWidth = 100;

  final TransformationController _transform = TransformationController();
  Size? _viewport;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  /// Scales the whole map to fit the viewport and centres it.
  void _fit() {
    final viewport = _viewport;
    if (viewport == null) return;
    final size = widget.layout.size;
    final scale = math.min(1.0, math.min(viewport.width, viewport.height) / size);
    _transform.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw((viewport.width - size * scale) / 2, (viewport.height - size * scale) / 2, 0);
  }

  String _label(String hostname) {
    final base = widget.baseHost;
    if (hostname == base || !hostname.endsWith('.$base')) return hostname;
    return hostname.substring(0, hostname.length - base.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    return LayoutBuilder(
      builder: (context, constraints) {
        final first = _viewport == null;
        _viewport = constraints.biggest;
        if (first) _fit();
        return Stack(
          children: [
            InteractiveViewer(
              transformationController: _transform,
              constrained: false,
              minScale: 0.2,
              maxScale: 3,
              boundaryMargin: const EdgeInsets.all(400),
              child: SizedBox.square(
                dimension: layout.size,
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _EdgePainter(layout))),
                    for (final hub in layout.hubs)
                      Positioned(
                        left: hub.position.dx - _hubSize.width / 2,
                        top: hub.position.dy - _hubSize.height / 2,
                        width: _hubSize.width,
                        height: _hubSize.height,
                        child: _IpHub(ip: hub.ip),
                      ),
                    for (final host in layout.hosts)
                      Positioned(
                        left: host.position.dx - _hostWidth / 2,
                        top: host.position.dy - _hostCircle / 2,
                        width: _hostWidth,
                        child: _HostNode(
                          subdomain: host.subdomain,
                          label: _label(host.subdomain.hostname),
                          size: _hostCircle,
                          onTap: () => widget.onTapHost(host.subdomain),
                        ),
                      ),
                    Positioned(
                      left: layout.center.dx - 80,
                      top: layout.center.dy - _domainNode / 2,
                      width: 160,
                      child: _DomainNode(name: widget.domainName, size: _domainNode),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: AppSpacing.lg,
              bottom: AppSpacing.lg + MediaQuery.of(context).padding.bottom,
              child: FloatingActionButton.small(
                heroTag: null,
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.grey700,
                tooltip: 'Fit to screen',
                onPressed: _fit,
                child: const Icon(Icons.fit_screen_rounded),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EdgePainter extends CustomPainter {
  final _MapLayout layout;

  _EdgePainter(this.layout);

  @override
  void paint(Canvas canvas, Size size) {
    final hubPaint = Paint()
      ..color = AppColors.grey300
      ..strokeWidth = 2;
    for (final hub in layout.hubs) {
      canvas.drawLine(layout.center, hub.position, hubPaint);
    }
    for (final host in layout.hosts) {
      final severity = host.subdomain.severity;
      final paint = Paint()
        ..color = severity == null ? AppColors.grey200 : severityColor(severity).withValues(alpha: 0.45)
        ..strokeWidth = 1.5;
      canvas.drawLine(layout.hubs[host.hub].position, host.position, paint);
    }
  }

  @override
  bool shouldRepaint(_EdgePainter oldDelegate) => oldDelegate.layout != layout;
}

class _DomainNode extends StatelessWidget {
  final String name;
  final double size;

  const _DomainNode({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.gradientButton,
            boxShadow: AppShadows.lg,
            border: Border.all(color: AppColors.white, width: 3),
          ),
          child: const Icon(Icons.language_rounded, color: AppColors.white, size: 34),
        ),
        AppSpacing.xs.height,
        CustomText(
          text: name,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.normalText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _IpHub extends StatelessWidget {
  final String? ip;

  const _IpHub({required this.ip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blue500.withValues(alpha: 0.4)),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(ip == null ? Icons.help_outline_rounded : Icons.dns_rounded, size: 13, color: AppColors.blue500),
          AppSpacing.xs.width,
          Flexible(
            child: CustomText(
              text: ip ?? 'No IP',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.blue500,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _HostNode extends StatelessWidget {
  final GraphSubdomain subdomain;
  final String label;
  final double size;
  final VoidCallback onTap;

  const _HostNode({required this.subdomain, required this.label, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final severity = subdomain.severity;
    final color = severity == null ? AppColors.grey400 : severityColor(severity);
    final ssl = subdomain.ssl;
    final sslColor = ssl == null ? AppColors.grey300 : (ssl.valid == false ? AppColors.red500 : AppColors.successGreen);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: severity == null ? AppColors.white : color.withValues(alpha: 0.1),
              border: Border.all(color: color, width: 2.5),
              boxShadow: AppShadows.sm,
            ),
            child: Icon(Icons.public_rounded, size: 22, color: color),
          ),
          AppSpacing.xs.height,
          CustomText(
            text: label,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.normalText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          2.height,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ssl?.valid == false ? Icons.lock_open_rounded : Icons.lock_rounded, size: 11, color: sslColor),
              AppSpacing.xs.width,
              _miniStat(Icons.settings_ethernet_rounded, subdomain.openPorts.length),
              AppSpacing.xs.width,
              _miniStat(Icons.memory_rounded, subdomain.technologies.length),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, int count) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: AppColors.grey500),
      2.width,
      CustomText(text: '$count', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.grey600),
    ],
  );
}

// ---------------------------------------------------------------------------
// Host details sheet
// ---------------------------------------------------------------------------

class _HostSheet extends StatelessWidget {
  final GraphSubdomain subdomain;
  final VoidCallback onOpen;

  const _HostSheet({required this.subdomain, required this.onOpen});

  static void show(GraphSubdomain subdomain, {required VoidCallback onOpen}) {
    Get.bottomSheet<void>(
      _HostSheet(subdomain: subdomain, onOpen: onOpen),
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = subdomain;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: SafeArea(
        child: SingleChildScrollView(
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
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      text: s.hostname,
                      fontSize: AppTextTokens.titleSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.normalText,
                      textAlign: TextAlign.left,
                    ),
                  ),
                  if (s.severity != null) ...[AppSpacing.sm.width, StatusBadge.severity(s.severity)],
                ],
              ),
              4.height,
              CustomText(
                text: s.ipAddress ?? 'No IP address',
                fontSize: 13,
                color: AppColors.grey500,
                textAlign: TextAlign.left,
              ),
              _section('Risks'),
              if (s.findings.isEmpty)
                _muted('No risks flagged for this host.')
              else
                for (final f in s.findings) _FindingRow(finding: f),
              _section('Ports'),
              if (s.ports.isEmpty)
                _muted('No ports scanned yet.')
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [for (final p in s.ports) _PortChip(port: p)],
                ),
              _section('SSL certificate'),
              if (s.ssl == null)
                _muted('No certificate stored.')
              else ...[
                InfoRow(
                  label: 'Status',
                  value: s.ssl!.valid == false ? 'Invalid' : 'Valid',
                  valueColor: s.ssl!.valid == false ? AppColors.red500 : AppColors.successGreen,
                ),
                InfoRow(label: 'Issuer', value: asText(s.ssl!.issuer)),
                InfoRow(label: 'Expires', value: formatDate(s.ssl!.expiresAt)),
                InfoRow(label: 'TLS', value: s.ssl!.tlsVersion ?? '—'),
              ],
              _section('Technologies'),
              if (s.technologies.isEmpty)
                _muted('No technologies detected.')
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [for (final t in s.technologies) _TechChip(technology: t)],
                ),
              AppSpacing.xl.height,
              CustomButton(
                text: 'Open host details',
                color: AppColors.amber50,
                textColor: AppColors.amber700,
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  // Navigator.pop, not Get.back: Get.back closes an open snackbar instead of the sheet.
                  Navigator.of(context).pop();
                  onOpen();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
    child: CustomText(
      text: title,
      fontSize: AppTextTokens.bodySize,
      fontWeight: FontWeight.bold,
      color: AppColors.normalText,
      textAlign: TextAlign.left,
    ),
  );

  static Widget _muted(String text) =>
      CustomText(text: text, fontSize: 13, color: AppColors.grey500, textAlign: TextAlign.left);
}

class _FindingRow extends StatelessWidget {
  final GraphFinding finding;

  const _FindingRow({required this.finding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            height: 8,
            width: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: severityColor(finding.severity)),
          ),
          AppSpacing.sm.width,
          Expanded(
            child: CustomText(
              text: finding.label,
              fontSize: 13,
              color: AppColors.normalText,
              textAlign: TextAlign.left,
            ),
          ),
          AppSpacing.sm.width,
          StatusBadge.severity(finding.severity),
        ],
      ),
    );
  }
}

class _PortChip extends StatelessWidget {
  final GraphPort port;

  const _PortChip({required this.port});

  @override
  Widget build(BuildContext context) {
    final open = port.isOpen;
    final color = open ? AppColors.successGreen : AppColors.grey500;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: open ? AppColors.successGreenLight : AppColors.grey50,
        borderRadius: AppRadius.rSm,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: CustomText(
        text: port.service == null ? '${port.port}' : '${port.port} ${port.service}',
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}

class _TechChip extends StatelessWidget {
  final GraphTechnology technology;

  const _TechChip({required this.technology});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: AppRadius.rSm),
      child: CustomText(
        text: technology.version == null ? technology.name : '${technology.name} ${technology.version}',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.teal,
      ),
    );
  }
}
