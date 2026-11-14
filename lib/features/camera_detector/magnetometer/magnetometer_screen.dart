import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_button/custom_button.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/section_card/section_card.dart';
import 'package:reconex/core/custom_widgets/state_views/state_views.dart';
import 'package:reconex/core/custom_widgets/status_badge/status_badge.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/features/camera_detector/magnetometer/field_meter.dart';
import 'package:reconex/features/camera_detector/magnetometer/magnetometer_controller.dart';

(String, Color) _levelStyle(FieldLevel l) => switch (l) {
  FieldLevel.normal => ('Normal', AppColors.slate500),
  FieldLevel.raised => ('Raised', AppColors.amber600),
  FieldLevel.strong => ('Strong', AppColors.red500),
};

class MagnetometerScreen extends GetView<MagnetometerController> {
  const MagnetometerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(title: const Text('Magnetic field')),
      body: Obx(() {
        final error = controller.error.value;
        if (error != null) {
          return EmptyState(icon: Icons.sensors_off_rounded, title: 'No magnetic sensor', message: error);
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
          children: [
            _Readout(controller: controller),
            AppSpacing.lg.height,
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: controller.calibrating.value ? 'Calibrating…' : 'Calibrate',
                    icon: Icons.tune_rounded,
                    color: AppColors.primary,
                    loading: controller.calibrating.value,
                    onPressed: controller.calibrate,
                  ),
                ),
                AppSpacing.md.width,
                Expanded(
                  child: CustomButton(
                    text: 'Reset peak',
                    icon: Icons.restart_alt_rounded,
                    enabled: controller.delta.value != null,
                    onPressed: controller.resetPeak,
                  ),
                ),
              ],
            ),
            AppSpacing.lg.height,
            const _StepsCard(),
            AppSpacing.lg.height,
            const _HintCard(),
          ],
        );
      }),
    );
  }
}

class _Readout extends StatelessWidget {
  final MagnetometerController controller;

  const _Readout({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Obx(() {
        final delta = controller.delta.value;
        final current = controller.current.value;
        final calibrating = controller.calibrating.value;
        final (label, color) = _levelStyle(controller.level.value);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    text: 'Above room baseline',
                    fontSize: 13,
                    color: AppColors.grey500,
                    textAlign: TextAlign.left,
                  ),
                ),
                if (delta != null && !calibrating) StatusBadge(label: label, color: color),
              ],
            ),
            AppSpacing.sm.height,
            CustomText(
              text: calibrating
                  ? 'Hold still…'
                  : delta == null
                  ? 'Calibrate first'
                  : '${delta.toStringAsFixed(1)} µT',
              fontSize: delta == null || calibrating ? AppTextTokens.titleSize : 44,
              fontWeight: FontWeight.bold,
              color: delta == null || calibrating ? AppColors.normalText : color,
              textAlign: TextAlign.left,
            ),
            4.height,
            CustomText(
              text: [
                if (current != null) 'Field ${current.toStringAsFixed(1)} µT',
                if (delta != null) 'Peak ${controller.peak.value.toStringAsFixed(1)} µT',
              ].join(' · '),
              fontSize: 12,
              color: AppColors.grey500,
              textAlign: TextAlign.left,
            ),
            AppSpacing.md.height,
            SizedBox(
              height: 64,
              width: double.infinity,
              child: CustomPaint(painter: _SparklinePainter(controller.history.toList(), color: color)),
            ),
          ],
        );
      }),
    );
  }
}

/// Line of recent field values, scaled to their own range (at least 10 µT).
class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter(this.values, {required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final lo = values.reduce(math.min);
    final range = math.max(values.reduce(math.max) - lo, 10.0);
    final step = size.width / (MagnetometerController.historyLength - 1);
    final start = size.width - step * (values.length - 1);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final p = Offset(start + step * i, size.height - (values[i] - lo) / range * size.height);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.values != values || old.color != color;
}

class _StepsCard extends StatelessWidget {
  const _StepsCard();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'How to check an object',
      child: CustomText(
        text:
            '1. Hold the phone away from any object and tap Calibrate.\n'
            '2. Move the phone slowly over the object, about 2 cm away.\n'
            '3. A spike in one spot suggests electronics inside.',
        fontSize: 13,
        color: AppColors.grey600,
        textAlign: TextAlign.left,
        height: 1.45,
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'A hint, not proof',
      child: CustomText(
        text:
            'Speakers, magnets, chargers, metal frames and wiring in the wall also raise the field. A spike only '
            'tells you to look closer; a quiet reading doesn\'t mean there\'s no camera.',
        fontSize: 13,
        color: AppColors.grey600,
        textAlign: TextAlign.left,
        height: 1.45,
      ),
    );
  }
}
