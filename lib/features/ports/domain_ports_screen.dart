import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/controllers/paged_controller.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/filter_chips/filter_chips.dart';
import 'package:reconex/core/custom_widgets/paged_list_view/paged_list_view.dart';
import 'package:reconex/core/custom_widgets/section_card/section_card.dart';
import 'package:reconex/core/custom_widgets/state_views/state_views.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/core/utils/json_utils.dart';
import 'package:reconex/data/services/domain_service.dart';

class DomainPortsController extends PagedController<Json> {
  final DomainService _domainService = Get.find();
  final String domainId = Get.arguments as String;

  /// Values for the `state` filter; null means all.
  static const List<String?> states = [null, 'open', 'closed'];
  static const List<String> stateLabels = ['All', 'Open', 'Closed'];

  final RxnString state = RxnString();

  @override
  Future<Paginated<Json>> fetchPage(int page) => _domainService.ports(domainId, page: page, state: state.value);

  void selectState(String? value) {
    if (state.value == value) return;
    state.value = value;
    reload();
  }
}

class DomainPortsScreen extends GetView<DomainPortsController> {
  const DomainPortsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const states = DomainPortsController.states;
    return Scaffold(
      appBar: AppBar(title: const Text('Ports')),
      body: PagedListView<Json>(
        controller: controller,
        header: [
          SliverToBoxAdapter(
            child: Obx(() {
              final selected = controller.state.value;
              return FilterChipRow(
                labels: DomainPortsController.stateLabels,
                isSelected: (i) => states[i] == selected,
                onTap: (i) => controller.selectState(states[i]),
              );
            }),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
        ],
        empty: const EmptyState(
          icon: Icons.settings_ethernet_rounded,
          title: 'No ports',
          message: 'No ports match this filter. Run a full scan to probe ports on every subdomain.',
        ),
        itemBuilder: (_, port) => _PortCard(port: port),
      ),
    );
  }
}

class _PortCard extends StatelessWidget {
  final Json port;

  const _PortCard({required this.port});

  @override
  Widget build(BuildContext context) {
    final open = asText(port['state'] ?? port['status']).toLowerCase() != 'closed';
    final color = open ? AppColors.successGreen : AppColors.grey500;
    final details = [
      port['ipAddress'] ?? 'No IP',
      if (port['service'] != null) port['service'],
      if (port['protocol'] != null) port['protocol'],
    ].join(' · ');
    return SectionCard(
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: open ? AppColors.successGreenLight : AppColors.grey50,
              borderRadius: AppRadius.rSm,
            ),
            child: CustomText(text: asText(port['port']), fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
          AppSpacing.md.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: asText(port['hostname']),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.normalText,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                4.height,
                CustomText(text: details, fontSize: 12, color: AppColors.grey500, textAlign: TextAlign.left),
              ],
            ),
          ),
          AppSpacing.sm.width,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: CustomText(text: open ? 'Open' : 'Closed', fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
