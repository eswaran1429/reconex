import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_button/custom_button.dart';
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
import 'package:reconex/data/models/severity.dart';
import 'package:reconex/features/security/security_controller.dart';

class SecurityScreen extends GetView<SecurityController> {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: controller.args.initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Security checks'),
          bottom: const TabBar(
            labelColor: AppColors.amber700,
            unselectedLabelColor: AppColors.grey500,
            indicatorColor: AppColors.primary,
            labelStyle: TextStyle(fontFamily: 'JetBrainsMono', fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Headers'),
              Tab(text: 'Exposed files'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CheckTab(
              check: controller.headers,
              onRun: () => controller.run(controller.headers),
              onRetry: () => controller.loadLatest(controller.headers),
            ),
            _CheckTab(
              check: controller.exposed,
              onRun: () => controller.run(controller.exposed),
              onRetry: () => controller.loadLatest(controller.exposed),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckTab extends StatelessWidget {
  final SecurityCheck check;
  final VoidCallback onRun;
  final VoidCallback onRetry;

  const _CheckTab({required this.check, required this.onRun, required this.onRetry});

  bool get _isHeaders => check.type == 'headers';

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (check.isLoading.value) return const CardListSkeleton(count: 4);
      final error = check.error.value;
      final rows = check.rows.toList();
      if (error != null && rows.isEmpty && !check.isRunning.value) {
        return ErrorState(message: error, onRetry: onRetry);
      }
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _SummaryCard(check: check, onRun: onRun),
          AppSpacing.lg.height,
          if (rows.isNotEmpty)
            SectionCard(
              title: _isHeaders ? 'Headers' : 'Paths checked',
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const Divider(height: AppSpacing.lg, color: AppColors.grey100),
                    _isHeaders ? _HeaderRow(row: rows[i]) : _ExposedRow(row: rows[i]),
                  ],
                ],
              ),
            ),
        ],
      );
    });
  }
}

class _SummaryCard extends StatelessWidget {
  final SecurityCheck check;
  final VoidCallback onRun;

  const _SummaryCard({required this.check, required this.onRun});

  @override
  Widget build(BuildContext context) {
    final isHeaders = check.type == 'headers';
    final total = check.rows.length;
    final issues = check.issueCount;
    final checked = check.scannedAt.value != null;
    final color = !checked
        ? AppColors.grey400
        : issues > 0
        ? AppColors.red500
        : AppColors.successGreen;

    final headline = !checked
        ? 'Not checked yet'
        : issues == 0
        ? (isHeaders ? 'All $total headers present' : 'No exposed files')
        : (isHeaders ? '$issues of $total headers missing' : '$issues of $total paths exposed');

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(
                  !checked
                      ? Icons.shield_outlined
                      : issues > 0
                      ? Icons.gpp_maybe_outlined
                      : Icons.verified_user_outlined,
                  color: color,
                ),
              ),
              AppSpacing.md.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: headline,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.normalText,
                      textAlign: TextAlign.left,
                    ),
                    2.height,
                    CustomText(
                      text: checked
                          ? 'Last checked ${timeAgo(check.scannedAt.value)}'
                          : (isHeaders
                                ? 'Checks HSTS, CSP, X-Frame-Options and 4 more.'
                                : 'Checks about 15 sensitive paths like /.env and /.git/config.'),
                      fontSize: 12,
                      color: AppColors.grey500,
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (check.error.value != null && total > 0) ...[
            AppSpacing.md.height,
            CustomText(text: check.error.value!, fontSize: 12, color: AppColors.red500, textAlign: TextAlign.left),
          ],
          AppSpacing.lg.height,
          CustomButton(
            text: checked ? 'Run check again' : 'Run check',
            gradient: AppColors.gradientButton,
            textColor: AppColors.white,
            icon: Icons.play_arrow_rounded,
            loading: check.isRunning.value,
            onPressed: onRun,
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final Json row;

  const _HeaderRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final present = row['present'] == true;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          present ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 20,
          color: present ? AppColors.successGreen : AppColors.red500,
        ),
        AppSpacing.md.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: asText(row['headerName']),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.normalText,
                textAlign: TextAlign.left,
              ),
              2.height,
              CustomText(
                text: present ? asText(row['value']) : 'Missing',
                fontSize: 12,
                color: AppColors.grey500,
                textAlign: TextAlign.left,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (!present) StatusBadge.severity(Severity.tryParse(row['severity'])),
      ],
    );
  }
}

class _ExposedRow extends StatelessWidget {
  final Json row;

  const _ExposedRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final accessible = row['accessible'] == true;
    return Row(
      children: [
        Icon(
          accessible ? Icons.lock_open_rounded : Icons.lock_rounded,
          size: 20,
          color: accessible ? AppColors.red500 : AppColors.successGreen,
        ),
        AppSpacing.md.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: asText(row['path']),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.normalText,
                textAlign: TextAlign.left,
              ),
              2.height,
              CustomText(
                text: row['statusCode'] == null ? 'No response' : 'HTTP ${asText(row['statusCode'])}',
                fontSize: 12,
                color: AppColors.grey500,
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
        accessible
            ? StatusBadge.severity(Severity.tryParse(row['severity']))
            : const StatusBadge(label: 'Safe', color: AppColors.successGreen),
      ],
    );
  }
}
