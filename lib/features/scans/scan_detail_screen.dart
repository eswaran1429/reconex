import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_button/custom_button.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/section_card/section_card.dart';
import 'package:reconex/core/custom_widgets/state_views/state_views.dart';
import 'package:reconex/core/custom_widgets/status_badge/status_badge.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_icons.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/core/utils/json_utils.dart';
import 'package:reconex/data/models/scan.dart';
import 'package:reconex/features/scans/scan_detail_controller.dart';

class ScanDetailScreen extends GetView<ScanDetailController> {
  const ScanDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: Obx(() {
        if (controller.isLoading.value) return const CardListSkeleton(count: 3);
        final scan = controller.scan.value;
        if (scan == null) return ErrorState(message: controller.error.value ?? 'No data', onRetry: controller.retry);

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _StatusCard(scan: scan),
            if (scan.error != null) ...[AppSpacing.lg.height, _ErrorCard(message: scan.error!)],
            AppSpacing.lg.height,
            SectionCard(
              title: 'Steps',
              child: Column(
                children: [
                  for (var i = 0; i < scanSteps.length; i++)
                    _StepRow(scan: scan, step: scanSteps[i], isLast: i == scanSteps.length - 1),
                ],
              ),
            ),
            AppSpacing.xl.height,
            if (!scan.isActive && scan.changeCount > 0)
              CustomButton(
                text: 'View ${scan.changeCount} changes',
                gradient: AppColors.gradientButton,
                textColor: AppColors.white,
                icon: Icons.arrow_forward_rounded,
                onPressed: controller.openChanges,
              )
            else if (scan.status == 'COMPLETED' && scan.changeCount == 0)
              const CustomText(
                text: 'No changes since the previous scan. A domain\'s first scan is the baseline, so it records none.',
                fontSize: 13,
                color: AppColors.grey500,
                height: 1.4,
              ),
            AppSpacing.xxl.height,
          ],
        );
      }),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Scan scan;

  const _StatusCard({required this.scan});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(scan.status);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge.status(scan.status),
              const Spacer(),
              if (scan.isActive)
                CustomText(text: '${scan.progressPercent}%', fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ],
          ),
          if (scan.isActive) ...[
            AppSpacing.md.height,
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: scan.progressPercent / 100),
                duration: const Duration(milliseconds: 500),
                builder: (_, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: AppColors.grey100,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
            AppSpacing.sm.height,
            CustomText(
              text: scan.currentStep == null ? 'Waiting to start…' : 'Scanning ${humanize(scan.currentStep!)}…',
              fontSize: 13,
              color: AppColors.grey500,
              textAlign: TextAlign.left,
            ),
          ],
          AppSpacing.md.height,
          InfoRow(label: 'Started', value: formatDateTime(scan.startedAt ?? scan.createdAt)),
          if (scan.completedAt != null) ...[
            InfoRow(label: 'Completed', value: formatDateTime(scan.completedAt)),
            InfoRow(label: 'Duration', value: formatDuration(scan.startedAt, scan.completedAt)),
          ],
          if (!scan.isActive) InfoRow(label: 'Changes', value: '${scan.changeCount}'),
          if (scan.trigger != null) InfoRow(label: 'Trigger', value: humanize(scan.trigger!)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.red50, borderRadius: AppRadius.rMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.red500),
          AppSpacing.md.width,
          Expanded(
            child: CustomText(text: message, fontSize: 13, color: AppColors.red500, textAlign: TextAlign.left),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final Scan scan;
  final String step;
  final bool isLast;

  const _StepRow({required this.scan, required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final status = scan.stepStatus(step);
    final detail = scan.stepDetail(step);
    final (Color color, Widget marker) = switch (status) {
      'completed' => (AppColors.successGreen, const Icon(Icons.check_rounded, size: 16, color: AppColors.white)),
      'failed' => (AppColors.red500, const Icon(Icons.close_rounded, size: 16, color: AppColors.white)),
      'running' => (
        AppColors.amber600,
        const Padding(
          padding: EdgeInsets.all(6),
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
        ),
      ),
      _ => (AppColors.grey300, const SizedBox.shrink()),
    };

    final lines = <String>[
      if (detail != null && detail['startedAt'] != null && detail['completedAt'] != null)
        formatDuration(parseDate(detail['startedAt']), parseDate(detail['completedAt'])),
      if (detail?['counts'] is Map)
        asMap(detail!['counts']).entries.map((e) => '${humanize(e.key)}: ${e.value}').join(', '),
    ];
    final stepError = detail?['error'];
    final unreachable = asList(detail?['unreachable']);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: marker,
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: AppColors.grey200)),
            ],
          ),
          AppSpacing.md.width,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(AppIcons.category(step), size: 16, color: AppColors.grey600),
                      6.width,
                      CustomText(
                        text: humanize(step),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: status == 'pending' ? AppColors.grey400 : AppColors.normalText,
                      ),
                    ],
                  ),
                  if (lines.isNotEmpty) ...[
                    4.height,
                    CustomText(
                      text: lines.join(' · '),
                      fontSize: 12,
                      color: AppColors.grey500,
                      textAlign: TextAlign.left,
                    ),
                  ],
                  if (stepError != null) ...[
                    4.height,
                    CustomText(
                      text: asText(stepError),
                      fontSize: 12,
                      color: AppColors.red500,
                      textAlign: TextAlign.left,
                    ),
                  ],
                  if (unreachable.isNotEmpty) ...[
                    4.height,
                    CustomText(
                      text: 'Unreachable: ${unreachable.map(asText).join(', ')}',
                      fontSize: 12,
                      color: AppColors.warning,
                      textAlign: TextAlign.left,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
