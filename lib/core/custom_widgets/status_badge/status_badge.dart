import 'package:flutter/material.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/data/models/severity.dart';

Color severityColor(Severity? severity) => switch (severity) {
  Severity.critical => AppColors.red500,
  Severity.high => AppColors.orange,
  Severity.medium => AppColors.amber600,
  Severity.low => AppColors.blue500,
  Severity.info || null => AppColors.slate500,
};

/// Scan status (QUEUED, RUNNING, ...) and domain status (ACTIVE, INACTIVE).
Color statusColor(String status) => switch (status) {
  'COMPLETED' || 'ACTIVE' => AppColors.successGreen,
  'RUNNING' => AppColors.amber600,
  'PARTIAL' => AppColors.warning,
  'FAILED' => AppColors.red500,
  _ => AppColors.slate500,
};

/// Small tinted pill, e.g. a severity or status label.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  StatusBadge.severity(Severity? severity, {super.key})
    : label = humanize(severity?.name ?? 'info'),
      color = severityColor(severity);

  StatusBadge.status(String status, {super.key}) : label = humanize(status), color = statusColor(status);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: CustomText(text: label, fontSize: 12, fontWeight: FontWeight.bold, color: color),
    );
  }
}
