import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/section_card/section_card.dart';
import 'package:reconex/core/custom_widgets/shimmer/shimmer.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/data/models/risk.dart';
import 'package:reconex/features/risk/risk_overview_controller.dart';
import 'package:reconex/features/risk/risk_widgets.dart';

/// Risk Overview block on the domain dashboard: score gauge, severity split,
/// trend and top risks. Driven by [RiskOverviewController].
class RiskOverviewSection extends GetView<RiskOverviewController> {
  const RiskOverviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Shimmer(
          child: SizedBox(height: 180, width: double.infinity, child: SkeletonBox(height: 180, radius: 20)),
        );
      }
      if (controller.notScored.value) return const _NotScoredCard();
      final error = controller.error.value;
      if (error != null && controller.score.value == null) {
        return _RiskErrorCard(message: error, onRetry: controller.load);
      }
      final score = controller.score.value;
      if (score == null) return const SizedBox.shrink();
      return _RiskCard(score: score, controller: controller);
    });
  }
}

class _RiskCard extends StatelessWidget {
  final RiskScore score;
  final RiskOverviewController controller;

  const _RiskCard({required this.score, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Risk overview',
      trailing: GestureDetector(
        onTap: () => controller.openFindings(),
        child: const CustomText(
          text: 'All risks',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.amber700,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RiskGauge(score: score.score, level: score.level, levelLabel: score.levelLabel),
              AppSpacing.lg.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DeltaRow(delta: score.delta, previous: score.previousScore),
                    AppSpacing.sm.height,
                    CustomText(
                      text: '${score.findingCount} active ${score.findingCount == 1 ? 'risk' : 'risks'}',
                      fontSize: AppTextTokens.bodySize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.normalText,
                      textAlign: TextAlign.left,
                    ),
                    4.height,
                    CustomText(
                      text:
                          'Scored after each scan from exposed services, sensitive resources, certificates and headers.',
                      fontSize: 12,
                      color: AppColors.grey500,
                      textAlign: TextAlign.left,
                      height: 1.35,
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.lg.height,
          SeverityDistributionBar(bySeverity: score.bySeverity),
          if (score.breakdown.isNotEmpty) ...[AppSpacing.lg.height, _BreakdownList(breakdown: score.breakdown)],
          AppSpacing.lg.height,
          const CustomText(
            text: 'Score trend',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.normalText,
            textAlign: TextAlign.left,
          ),
          AppSpacing.sm.height,
          RiskHistoryChart(points: controller.history),
          if (score.topRisks.isNotEmpty) ...[
            AppSpacing.lg.height,
            const CustomText(
              text: 'Top risks',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.normalText,
              textAlign: TextAlign.left,
            ),
            AppSpacing.xs.height,
            for (final risk in score.topRisks)
              RiskFindingTile(finding: risk, onTap: () => controller.openRisk(risk.id)),
          ],
        ],
      ),
    );
  }
}

/// Which categories add to the score, and whether any hit their cap.
class _BreakdownList extends StatelessWidget {
  final List<RiskBreakdown> breakdown;

  const _BreakdownList({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final scoring = breakdown.where((b) => b.points > 0).toList()..sort((a, b) => b.points.compareTo(a.points));
    if (scoring.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CustomText(
          text: 'What drives the score',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.normalText,
          textAlign: TextAlign.left,
        ),
        AppSpacing.sm.height,
        for (final b in scoring)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(riskCategoryIcon(b.category), size: 16, color: AppColors.grey600),
                AppSpacing.sm.width,
                Expanded(
                  child: CustomText(
                    text: '${riskCategoryLabel(b.category)} (${b.findings})',
                    fontSize: 13,
                    color: AppColors.normalText,
                    textAlign: TextAlign.left,
                  ),
                ),
                if (b.capped) ...[
                  const CustomText(text: 'capped', fontSize: 11, color: AppColors.grey400),
                  AppSpacing.sm.width,
                ],
                CustomText(
                  text: '+${b.points}',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.normalText,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DeltaRow extends StatelessWidget {
  final int? delta;
  final int? previous;

  const _DeltaRow({required this.delta, required this.previous});

  @override
  Widget build(BuildContext context) {
    if (delta == null || previous == null) {
      return const CustomText(
        text: 'First scored scan',
        fontSize: 13,
        color: AppColors.grey500,
        textAlign: TextAlign.left,
      );
    }
    final up = delta! > 0;
    final flat = delta == 0;
    // Higher score = worse, so up is red.
    final color = flat ? AppColors.grey500 : (up ? AppColors.red500 : AppColors.successGreen);
    return Row(
      children: [
        Icon(
          flat ? Icons.trending_flat_rounded : (up ? Icons.trending_up_rounded : Icons.trending_down_rounded),
          size: 18,
          color: color,
        ),
        4.width,
        CustomText(
          text: flat ? 'No change' : '${up ? '+' : ''}$delta vs last scan',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ],
    );
  }
}

class _NotScoredCard extends StatelessWidget {
  const _NotScoredCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Risk overview',
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: const BoxDecoration(color: AppColors.amber50, shape: BoxShape.circle),
            child: const Icon(Icons.shield_outlined, color: AppColors.amber600),
          ),
          AppSpacing.md.width,
          const Expanded(
            child: CustomText(
              text: 'No risk score yet. Run a scan to score this domain\'s attack surface.',
              fontSize: 13,
              color: AppColors.grey500,
              textAlign: TextAlign.left,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _RiskErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Risk overview',
      trailing: GestureDetector(
        onTap: onRetry,
        child: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.amber700),
      ),
      child: CustomText(text: message, fontSize: 13, color: AppColors.grey500, textAlign: TextAlign.left),
    );
  }
}
