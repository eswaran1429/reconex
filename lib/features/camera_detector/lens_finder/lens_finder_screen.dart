import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/section_card/section_card.dart';
import 'package:reconex/core/custom_widgets/state_views/state_views.dart';
import 'package:reconex/core/custom_widgets/status_badge/status_badge.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/features/camera_detector/lens_finder/bright_spot_detector.dart';
import 'package:reconex/features/camera_detector/lens_finder/lens_finder_controller.dart';

const Map<LensMode, String> _instructions = {
  LensMode.ir:
      'Turn the room lights off. Point the front camera at smoke detectors, chargers, clocks and anything '
      'facing the bed. Night-vision LEDs show as a steady purple or white dot.',
  LensMode.glint:
      'Dim the lights and hold the phone near eye level. Sweep slowly across objects. A lens reflects the '
      'torch back as a tiny bright point that stays put while you move.',
};

/// Clockwise quarter turns from the analysed image (sensor orientation) to the preview as drawn.
///
/// Mirrors what camera_android_camerax + CameraPreview do on screen: net rotation is sensorOrientation
/// plus (rear) or minus (front) the display rotation; the front preview is mirrored horizontally.
int _quarterTurns(CameraValue v) {
  final display = switch (v.deviceOrientation) {
    DeviceOrientation.portraitUp => 0,
    DeviceOrientation.landscapeRight => 90,
    DeviceOrientation.portraitDown => 180,
    DeviceOrientation.landscapeLeft => 270,
  };
  final front = v.description.lensDirection == CameraLensDirection.front;
  return ((v.description.sensorOrientation + (front ? -display : display)) ~/ 90) % 4;
}

class LensFinderScreen extends GetView<LensFinderController> {
  const LensFinderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(title: const Text('Lens & IR finder')),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              final error = controller.error.value;
              if (error != null) {
                return EmptyState(
                  icon: Icons.no_photography_rounded,
                  title: 'Camera unavailable',
                  message: error,
                  actionLabel: 'Try again',
                  onAction: controller.retry,
                );
              }
              final cam = controller.camera.value;
              return ColoredBox(
                color: AppColors.black,
                child: Center(
                  child: cam == null
                      ? const CircularProgressIndicator(color: AppColors.white)
                      : CameraPreview(
                          cam,
                          child: ValueListenableBuilder<CameraValue>(
                            valueListenable: cam,
                            builder: (_, value, _) => Obx(
                              () => CustomPaint(
                                painter: _SpotPainter(
                                  List.of(controller.spots),
                                  _quarterTurns(value),
                                  mirror: value.description.lensDirection == CameraLensDirection.front,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              );
            }),
          ),
          _Panel(controller: controller),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final LensFinderController controller;

  const _Panel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SectionCard(
          child: Obx(() {
            final mode = controller.mode.value;
            final count = controller.spots.length;
            final notice = controller.notice.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<LensMode>(
                        segments: const [
                          ButtonSegment(value: LensMode.ir, icon: Icon(Icons.sensors_rounded), label: Text('IR')),
                          ButtonSegment(
                            value: LensMode.glint,
                            icon: Icon(Icons.flashlight_on_rounded),
                            label: Text('Glint'),
                          ),
                        ],
                        selected: {mode},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) => controller.setMode(s.first),
                      ),
                    ),
                    AppSpacing.md.width,
                    StatusBadge(
                      label: count == 1 ? '1 spot' : '$count spots',
                      color: count == 0 ? AppColors.slate500 : AppColors.red500,
                    ),
                  ],
                ),
                AppSpacing.md.height,
                CustomText(
                  text: _instructions[mode]!,
                  fontSize: 13,
                  color: AppColors.normalText,
                  textAlign: TextAlign.left,
                  height: 1.4,
                ),
                if (notice != null) ...[
                  AppSpacing.sm.height,
                  CustomText(text: notice, fontSize: 12, color: AppColors.amber600, textAlign: TextAlign.left),
                ],
                AppSpacing.sm.height,
                const CustomText(
                  text: 'A guided aid, not proof. Bright reflections can fool it; check anything marked up close.',
                  fontSize: 12,
                  color: AppColors.grey500,
                  textAlign: TextAlign.left,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Rings around detected spots. Points arrive in image coords and are mapped to the preview.
class _SpotPainter extends CustomPainter {
  final List<BrightSpot> spots;
  final int quarterTurns;
  final bool mirror;

  _SpotPainter(this.spots, this.quarterTurns, {required this.mirror});

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..color = AppColors.red500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final longest = size.longestSide;
    for (final s in spots) {
      final (x, y) = toPreview(s.x, s.y, quarterTurns, mirror: mirror);
      canvas.drawCircle(Offset(x * size.width, y * size.height), (s.size * longest).clamp(14, 40), ring);
    }
  }

  @override
  bool shouldRepaint(_SpotPainter old) =>
      old.spots != spots || old.quarterTurns != quarterTurns || old.mirror != mirror;
}
