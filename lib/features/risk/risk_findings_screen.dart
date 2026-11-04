import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/controllers/paged_controller.dart';
import 'package:reconex/core/custom_widgets/filter_chips/filter_chips.dart';
import 'package:reconex/core/custom_widgets/paged_list_view/paged_list_view.dart';
import 'package:reconex/core/custom_widgets/state_views/state_views.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/data/models/risk.dart';
import 'package:reconex/data/models/severity.dart';
import 'package:reconex/data/services/risk_service.dart';
import 'package:reconex/features/risk/risk_widgets.dart';
import 'package:reconex/routes/app_routes.dart';

class RiskFindingsArgs {
  final String domainId;
  final String? severity;

  const RiskFindingsArgs({required this.domainId, this.severity});
}

class RiskFindingsController extends PagedController<RiskFinding> {
  final RiskService _riskService = Get.find();
  final RiskFindingsArgs args = Get.arguments as RiskFindingsArgs;

  // OPEN | RESOLVED | ALL
  final RxString status = 'OPEN'.obs;
  final RxSet<Severity> severities = <Severity>{}.obs;

  @override
  void onInit() {
    final preset = Severity.tryParse(args.severity);
    if (preset != null) severities.add(preset);
    super.onInit();
  }

  @override
  Future<Paginated<RiskFinding>> fetchPage(int page) => _riskService.findings(
    args.domainId,
    page: page,
    status: status.value,
    severity: severities.isEmpty ? null : severities.map((s) => s.name).toList(),
  );

  void setStatus(String value) {
    if (status.value == value) return;
    status.value = value;
    reload();
  }

  void toggleSeverity(Severity severity) {
    if (!severities.remove(severity)) severities.add(severity);
    reload();
  }

  void openRisk(RiskFinding finding) => Get.toNamed(AppRoutes.riskDetail, arguments: finding.id);
}

class RiskFindingsScreen extends GetView<RiskFindingsController> {
  const RiskFindingsScreen({super.key});

  static const List<String> _statuses = ['OPEN', 'RESOLVED', 'ALL'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Risk findings')),
      body: PagedListView<RiskFinding>(
        controller: controller,
        header: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Obx(() {
                final status = controller.status.value;
                return FilterChipRow(
                  labels: const ['Open', 'Resolved', 'All'],
                  isSelected: (i) => _statuses[i] == status,
                  onTap: (i) => controller.setStatus(_statuses[i]),
                );
              }),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
          SliverToBoxAdapter(
            child: Obx(
              () => SeverityFilterBar(selected: controller.severities.toSet(), onToggle: controller.toggleSeverity),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
        ],
        empty: const EmptyState(
          icon: Icons.verified_user_outlined,
          title: 'No risks',
          message: 'Nothing matches these filters. Risks are found from scan results.',
        ),
        itemBuilder: (_, finding) => Material(
          color: AppColors.white,
          borderRadius: AppRadius.rMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: RiskFindingTile(finding: finding, onTap: () => controller.openRisk(finding)),
          ),
        ),
      ),
    );
  }
}
