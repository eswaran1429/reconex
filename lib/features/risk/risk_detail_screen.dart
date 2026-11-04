import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/section_card/section_card.dart';
import 'package:reconex/core/custom_widgets/state_views/state_views.dart';
import 'package:reconex/core/custom_widgets/status_badge/status_badge.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/core/utils/json_utils.dart';
import 'package:reconex/data/models/risk.dart';
import 'package:reconex/data/services/risk_service.dart';
import 'package:reconex/features/risk/risk_widgets.dart';

class RiskDetailController extends GetxController {
  final RiskService _riskService = Get.find();
  final String riskId = Get.arguments as String;

  final Rxn<RiskDetail> detail = Rxn<RiskDetail>();
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      detail.value = await _riskService.detail(riskId);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}

class RiskDetailScreen extends GetView<RiskDetailController> {
  const RiskDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Risk')),
      body: Obx(() {
        if (controller.isLoading.value) return const CardListSkeleton(count: 3);
        final detail = controller.detail.value;
        if (detail == null) return ErrorState(message: controller.error.value ?? 'No data', onRetry: controller.load);
        return _Body(detail: detail);
      }),
    );
  }
}

class _Body extends StatelessWidget {
  final RiskDetail detail;

  const _Body({required this.detail});

  @override
  Widget build(BuildContext context) {
    final finding = detail.finding;
    final color = severityColor(finding.severity);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: AppRadius.rSm),
                    child: Icon(riskCategoryIcon(finding.category), color: color),
                  ),
                  AppSpacing.md.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusBadge.severity(finding.severity),
                        4.height,
                        CustomText(
                          text: riskCategoryLabel(finding.category),
                          fontSize: 13,
                          color: AppColors.grey500,
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                  if (!finding.isOpen) const StatusBadge(label: 'Resolved', color: AppColors.successGreen),
                ],
              ),
              AppSpacing.md.height,
              CustomText(
                text: finding.title,
                fontSize: AppTextTokens.titleSmSize,
                fontWeight: FontWeight.bold,
                color: AppColors.normalText,
                textAlign: TextAlign.left,
                height: 1.3,
              ),
              if (finding.description != null) ...[
                AppSpacing.sm.height,
                CustomText(
                  text: finding.description!,
                  fontSize: 14,
                  color: AppColors.lightText,
                  textAlign: TextAlign.left,
                  height: 1.45,
                ),
              ],
            ],
          ),
        ),
        AppSpacing.lg.height,
        SectionCard(
          title: 'Why it affects the score',
          child: Column(
            children: [
              InfoRow(label: 'Severity', value: humanize(finding.severity?.name ?? 'info'), valueColor: color),
              InfoRow(label: 'Score added', value: '+${finding.scoreContribution}', valueColor: color),
              InfoRow(label: 'Status', value: humanize(finding.status)),
              InfoRow(label: 'First seen', value: formatDateTime(finding.firstSeenAt)),
              InfoRow(label: 'Last seen', value: formatDateTime(finding.lastSeenAt)),
              if (finding.resolvedAt != null) InfoRow(label: 'Resolved', value: formatDateTime(finding.resolvedAt)),
            ],
          ),
        ),
        if (finding.affectedAssets.isNotEmpty) ...[
          AppSpacing.lg.height,
          SectionCard(
            title: finding.affectedAssets.length == 1 ? 'Affected asset' : 'Affected assets',
            child: Column(
              children: [
                for (final asset in finding.affectedAssets)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.dns_outlined, size: 18, color: AppColors.blue500),
                        AppSpacing.md.width,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                text: asset.label,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.normalText,
                                textAlign: TextAlign.left,
                              ),
                              if (asset.ipAddress != null && asset.hostname != null)
                                CustomText(
                                  text: asset.ipAddress!,
                                  fontSize: 12,
                                  color: AppColors.grey500,
                                  textAlign: TextAlign.left,
                                ),
                            ],
                          ),
                        ),
                        StatusBadge(label: humanize(asset.type), color: AppColors.slate500),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (detail.evidence.isNotEmpty) ...[AppSpacing.lg.height, _EvidenceCard(evidence: detail.evidence)],
        if (finding.remediation != null) ...[AppSpacing.lg.height, _RemediationCard(text: finding.remediation!)],
        AppSpacing.xxl.height,
      ],
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  final Map<String, dynamic> evidence;

  const _EvidenceCard({required this.evidence});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Evidence',
      child: Column(
        children: [
          for (final entry in evidence.entries) InfoRow(label: humanize(entry.key), value: _format(entry.value)),
        ],
      ),
    );
  }

  static String _format(Object? value) {
    if (value == null) return '—';
    if (value is List) return value.map(asText).join(', ');
    return asText(value);
  }
}

class _RemediationCard extends StatelessWidget {
  final String text;

  const _RemediationCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.successGreenLight, borderRadius: AppRadius.rMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build_rounded, size: 18, color: AppColors.successGreen),
              AppSpacing.sm.width,
              const CustomText(
                text: 'Recommended fix',
                fontSize: AppTextTokens.titleSmSize,
                fontWeight: FontWeight.bold,
                color: AppColors.successGreen,
              ),
            ],
          ),
          AppSpacing.md.height,
          CustomText(text: text, fontSize: 14, color: AppColors.normalText, textAlign: TextAlign.left, height: 1.5),
        ],
      ),
    );
  }
}
