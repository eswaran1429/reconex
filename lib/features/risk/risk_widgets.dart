import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/status_badge/status_badge.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_icons.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/data/models/risk.dart';
import 'package:reconex/data/models/severity.dart';

Color riskLevelColor(RiskLevel? level) => switch (level) {
  RiskLevel.low => AppColors.successGreen,
  RiskLevel.moderate => AppColors.blue500,
  RiskLevel.high => AppColors.amber600,
  RiskLevel.veryHigh => AppColors.orange,
  RiskLevel.critical => AppColors.red500,
  null => AppColors.slate500,
};

/// Risk categories map onto the existing asset-category icons.
IconData riskCategoryIcon(String category) => AppIcons.category(switch (category) {
  'exposed_resource' => 'exposed_resources',
  'header' => 'headers',
  'technology' => 'technologies',
  'port' => 'ports',
  _ => category,
});

String riskCategoryLabel(String category) => switch (category) {
  'exposed_resource' => 'Exposed resource',
  'port' => 'Exposed service',
  'ssl' => 'Certificate',
  'header' => 'Security header',
  'technology' => 'Technology',
  _ => humanize(category),
};

/// Circular 0-100 gauge with the score and level in the middle.
class RiskGauge extends StatelessWidget {
  final int score;
  final RiskLevel? level;
  final String levelLabel;
  final double size;

  const RiskGauge({super.key, required this.score, required this.level, required this.levelLabel, this.size = 132});

  @override
  Widget build(BuildContext context) {
    final color = riskLevelColor(level);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: score / 100),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => CustomPaint(
          painter: _GaugePainter(progress: value, color: color),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(text: '$score', fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.normalText),
                CustomText(text: levelLabel, fontSize: 13, fontWeight: FontWeight.bold, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    final track = Paint()
      ..color = AppColors.grey100
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    // Start at top, sweep clockwise.
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, track);
    if (progress > 0) canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress.clamp(0.0, 1.0), false, arc);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.progress != progress || old.color != color;
}

/// Stacked proportional bar of findings by severity, most severe first.
class SeverityDistributionBar extends StatelessWidget {
  final Map<String, int> bySeverity;

  const SeverityDistributionBar({super.key, required this.bySeverity});

  @override
  Widget build(BuildContext context) {
    final entries = [
      for (final s in Severity.values)
        if ((bySeverity[s.name] ?? 0) > 0) (s, bySeverity[s.name]!),
    ];
    final total = entries.fold<int>(0, (sum, e) => sum + e.$2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: total == 0
                ? Container(color: AppColors.grey100)
                : Row(
                    children: [
                      for (final e in entries)
                        Expanded(
                          flex: e.$2,
                          child: Container(color: severityColor(e.$1)),
                        ),
                    ],
                  ),
          ),
        ),
        AppSpacing.md.height,
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            for (final s in Severity.values)
              _LegendDot(color: severityColor(s), label: humanize(s.name), count: bySeverity[s.name] ?? 0),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendDot({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        6.width,
        CustomText(text: '$label $count', fontSize: 12, color: AppColors.grey600),
      ],
    );
  }
}

/// Sparkline of score over scans. [points] oldest-first.
class RiskHistoryChart extends StatelessWidget {
  final List<RiskHistoryPoint> points;

  const RiskHistoryChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: CustomText(
            text: 'Not enough history yet. The trend appears after a few scans.',
            fontSize: 12,
            color: AppColors.grey500,
          ),
        ),
      );
    }
    return SizedBox(
      height: 90,
      child: CustomPaint(painter: _HistoryPainter(points), size: Size.infinite),
    );
  }
}

class _HistoryPainter extends CustomPainter {
  _HistoryPainter(this.points);

  final List<RiskHistoryPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    // Scores are 0-100; give a little vertical padding.
    const maxScore = 100.0;
    final dx = size.width / (points.length - 1);
    double y(int score) => size.height - 6 - (score / maxScore) * (size.height - 12);

    final path = Path();
    final fill = Path();
    for (var i = 0; i < points.length; i++) {
      final px = dx * i;
      final py = y(points[i].score);
      if (i == 0) {
        path.moveTo(px, py);
        fill.moveTo(px, size.height);
        fill.lineTo(px, py);
      } else {
        path.lineTo(px, py);
        fill.lineTo(px, py);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    final color = riskLevelColor(points.last.level);
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    // Dot on the latest point.
    canvas.drawCircle(Offset(dx * (points.length - 1), y(points.last.score)), 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_HistoryPainter old) => old.points != points;
}

class RiskFindingTile extends StatelessWidget {
  final RiskFinding finding;
  final VoidCallback onTap;

  const RiskFindingTile({super.key, required this.finding, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = severityColor(finding.severity);
    final asset = finding.affectedAssets.isEmpty ? null : finding.affectedAssets.first.label;
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
              child: Icon(riskCategoryIcon(finding.category), color: color, size: 20),
            ),
            AppSpacing.md.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: finding.title,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.normalText,
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  2.height,
                  CustomText(
                    text: asset == null
                        ? riskCategoryLabel(finding.category)
                        : '${riskCategoryLabel(finding.category)} · $asset',
                    fontSize: 12,
                    color: AppColors.grey500,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AppSpacing.sm.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge.severity(finding.severity),
                4.height,
                CustomText(
                  text: '+${finding.scoreContribution}',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ],
            ),
            if (!finding.isOpen) ...[
              AppSpacing.sm.width,
              const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
