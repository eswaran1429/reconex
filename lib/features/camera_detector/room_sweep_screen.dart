import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/section_card/section_card.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/routes/app_routes.dart';

/// One scan tool in the sweep.
class SweepTool {
  final String route;
  final IconData icon;
  final String title;
  final String subtitle;

  const SweepTool(this.route, this.icon, this.title, this.subtitle);
}

const List<SweepTool> sweepTools = [
  SweepTool(
    AppRoutes.cameraDetector,
    Icons.wifi_find_rounded,
    'Network & hotspot scan',
    'Cameras on this Wi-Fi, and cameras broadcasting their own',
  ),
  SweepTool(
    AppRoutes.lensFinder,
    Icons.flashlight_on_rounded,
    'Lens & IR finder',
    'Torch glint off a lens, or night-vision LEDs',
  ),
  SweepTool(
    AppRoutes.magnetometer,
    Icons.explore_rounded,
    'Magnetic field meter',
    'Check a suspicious object for electronics inside',
  ),
];

/// Places hidden cameras are most often found.
const List<String> sweepSpots = [
  'Smoke and CO detectors',
  'USB chargers and power adapters',
  'Clocks and alarm clocks',
  'TV, set-top box and speakers',
  'Air purifiers, vents and fans',
  'Picture frames and decor',
  'Mirrors (touch a fingernail to it: no gap may mean two-way glass)',
  'Bathroom and shower fixtures',
  'Anything facing the bed',
];

/// Session-only progress through the sweep. Nothing is saved.
class RoomSweepController extends GetxController {
  final RxSet<String> toolsRun = <String>{}.obs;
  final RxSet<int> spotsChecked = <int>{}.obs;

  int get total => sweepTools.length + sweepSpots.length;
  int get done => toolsRun.length + spotsChecked.length;

  Future<void> open(SweepTool tool) async {
    await Get.toNamed(tool.route);
    toolsRun.add(tool.route);
  }

  void toggleSpot(int i) => spotsChecked.contains(i) ? spotsChecked.remove(i) : spotsChecked.add(i);
}

/// Guided hidden-camera sweep: the three scan tools plus a physical checklist.
class RoomSweepScreen extends GetView<RoomSweepController> {
  const RoomSweepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(title: const Text('Hidden camera sweep')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
        children: [
          Obx(() {
            final done = controller.done;
            final total = controller.total;
            return SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: '$done of $total done',
                    fontSize: AppTextTokens.titleSmSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.normalText,
                    textAlign: TextAlign.left,
                  ),
                  4.height,
                  const CustomText(
                    text: 'Each check catches different cameras. Use all of them; none is proof on its own.',
                    fontSize: 13,
                    color: AppColors.grey500,
                    textAlign: TextAlign.left,
                    height: 1.4,
                  ),
                  AppSpacing.md.height,
                  LinearProgressIndicator(
                    minHeight: 3,
                    value: done / total,
                    backgroundColor: AppColors.grey100,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ],
              ),
            );
          }),
          AppSpacing.lg.height,
          for (final tool in sweepTools) ...[
            Obx(
              () => _ToolCard(
                tool: tool,
                done: controller.toolsRun.contains(tool.route),
                onTap: () => controller.open(tool),
              ),
            ),
            AppSpacing.md.height,
          ],
          AppSpacing.sm.height,
          SectionCard(
            title: 'Look and touch',
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.sm, AppSpacing.sm),
            child: Obx(
              () => Column(
                children: [
                  for (var i = 0; i < sweepSpots.length; i++)
                    CheckboxListTile(
                      value: controller.spotsChecked.contains(i),
                      onChanged: (_) => controller.toggleSpot(i),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.successGreen,
                      title: CustomText(
                        text: sweepSpots[i],
                        fontSize: 14,
                        color: AppColors.normalText,
                        textAlign: TextAlign.left,
                      ),
                    ),
                ],
              ),
            ),
          ),
          AppSpacing.lg.height,
          const CustomText(
            text:
                'Found something? Don\'t touch or unplug it. Take photos, leave the room and report it to the host '
                'or the police.',
            fontSize: 12,
            color: AppColors.grey600,
            textAlign: TextAlign.left,
            height: 1.45,
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final SweepTool tool;
  final bool done;
  final VoidCallback onTap;

  const _ToolCard({required this.tool, required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.successGreen : AppColors.blue500;
    return SectionCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: AppRadius.rSm),
            child: Icon(done ? Icons.check_rounded : tool.icon, color: color),
          ),
          AppSpacing.md.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: tool.title,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.normalText,
                  textAlign: TextAlign.left,
                ),
                4.height,
                CustomText(
                  text: tool.subtitle,
                  fontSize: 12,
                  color: AppColors.grey500,
                  textAlign: TextAlign.left,
                  height: 1.35,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.grey300),
        ],
      ),
    );
  }
}
