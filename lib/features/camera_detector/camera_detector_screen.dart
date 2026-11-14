import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/section_card/section_card.dart';
import 'package:reconex/core/custom_widgets/state_views/state_views.dart';
import 'package:reconex/core/custom_widgets/status_badge/status_badge.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/data/services/camera_fingerprint.dart';
import 'package:reconex/features/camera_detector/camera_detector_controller.dart';

(String, Color) _likelihoodStyle(CameraLikelihood l) => switch (l) {
  CameraLikelihood.likely => ('Likely camera', AppColors.red500),
  CameraLikelihood.possible => ('Possible', AppColors.amber600),
  CameraLikelihood.unlikely => ('Unlikely', AppColors.slate500),
};

class CameraDetectorScreen extends GetView<CameraDetectorController> {
  const CameraDetectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Camera scan'),
        actions: [
          Obx(
            () => IconButton(
              onPressed: controller.isScanning.value ? null : controller.scan,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Scan again',
            ),
          ),
        ],
      ),
      body: Obx(() {
        final error = controller.error.value;
        if (error != null && controller.suspects.isEmpty) {
          // Nearby hotspots don't need the phone to be on Wi-Fi, so keep them below the error.
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
            children: [
              EmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Can\'t scan',
                message: error,
                actionLabel: 'Try again',
                onAction: controller.scan,
              ),
              _HotspotCard(controller: controller),
            ],
          );
        }
        final flagged = controller.suspects.where((s) => s.verdict.likelihood != CameraLikelihood.unlikely).toList();
        final others = controller.suspects.where((s) => s.verdict.likelihood == CameraLikelihood.unlikely).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
          children: [
            _Summary(controller: controller),
            AppSpacing.lg.height,
            for (final s in flagged) ...[
              _SuspectCard(suspect: s, onTap: () => controller.openDevice(s)),
              AppSpacing.md.height,
            ],
            if (!controller.isScanning.value && flagged.isEmpty)
              const SectionCard(
                child: CustomText(
                  text: 'No device on this Wi-Fi looks like a camera.',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.normalText,
                  textAlign: TextAlign.left,
                ),
              ),
            AppSpacing.lg.height,
            _HotspotCard(controller: controller),
            if (others.isNotEmpty) ...[
              AppSpacing.lg.height,
              CustomText(
                text: 'Other devices (${others.length})',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.grey500,
                textAlign: TextAlign.left,
              ),
              AppSpacing.sm.height,
              for (final s in others) ...[
                _SuspectCard(suspect: s, onTap: () => controller.openDevice(s)),
                AppSpacing.sm.height,
              ],
            ],
            AppSpacing.lg.height,
            const _LimitsCard(),
          ],
        );
      }),
    );
  }
}

class _Summary extends StatelessWidget {
  final CameraDetectorController controller;

  const _Summary({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Obx(() {
        final scanning = controller.isScanning.value;
        final found = controller.hostsFound.value;
        final checked = controller.hostsChecked.value;
        final likely = controller.countOf(CameraLikelihood.likely);
        final possible = controller.countOf(CameraLikelihood.possible);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: controller.self.value?.ssid ?? 'Current Wi-Fi',
              fontSize: AppTextTokens.titleSmSize,
              fontWeight: FontWeight.bold,
              color: AppColors.normalText,
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            4.height,
            CustomText(
              text: scanning
                  ? 'Checking devices… $checked of $found'
                  : '$found devices checked · $likely likely · $possible possible',
              fontSize: 13,
              color: AppColors.grey500,
              textAlign: TextAlign.left,
            ),
            if (scanning) ...[
              AppSpacing.md.height,
              LinearProgressIndicator(
                minHeight: 3,
                value: found == 0 ? null : checked / found,
                backgroundColor: AppColors.grey100,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _SuspectCard extends StatelessWidget {
  final CameraSuspect suspect;
  final VoidCallback onTap;

  const _SuspectCard({required this.suspect, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final verdict = suspect.verdict;
    final (label, color) = _likelihoodStyle(verdict.likelihood);
    final flagged = verdict.likelihood != CameraLikelihood.unlikely;
    final device = suspect.device;

    return SectionCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: AppRadius.rSm),
                child: Icon(flagged ? Icons.videocam_rounded : Icons.devices_other_rounded, color: color),
              ),
              AppSpacing.md.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: device.displayName,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.normalText,
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    4.height,
                    CustomText(
                      text: device.mac == null ? device.ip : '${device.ip} · ${device.mac}',
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
              StatusBadge(label: flagged ? '$label · ${verdict.score}' : label, color: color),
            ],
          ),
          if (verdict.signals.isNotEmpty) ...[
            AppSpacing.md.height,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final signal in verdict.signals)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.grey100, borderRadius: AppRadius.rSm),
                    child: CustomText(
                      text: signal.reason,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey700,
                      textAlign: TextAlign.left,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HotspotCard extends StatelessWidget {
  final CameraDetectorController controller;

  const _HotspotCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Nearby camera hotspots',
      child: Obx(() {
        final list = controller.hotspots;
        final note = controller.hotspotNote.value;
        final String? status = controller.hotspotsScanning.value
            ? 'Listing nearby Wi-Fi…'
            : note ?? (list.isEmpty ? 'None nearby.' : null);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomText(
              text: 'Only finds cameras broadcasting their own Wi-Fi. Stronger signal means closer.',
              fontSize: 12,
              color: AppColors.grey500,
              textAlign: TextAlign.left,
            ),
            if (status != null) ...[
              AppSpacing.md.height,
              CustomText(
                text: status,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.normalText,
                textAlign: TextAlign.left,
              ),
            ],
            for (final h in list) ...[AppSpacing.md.height, _HotspotRow(hotspot: h)],
          ],
        );
      }),
    );
  }
}

class _HotspotRow extends StatelessWidget {
  final CameraHotspot hotspot;

  const _HotspotRow({required this.hotspot});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _likelihoodStyle(hotspot.verdict.likelihood);
    return Row(
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: AppRadius.rSm),
          child: Icon(Icons.wifi_tethering_rounded, color: color),
        ),
        AppSpacing.md.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: hotspot.ssid,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.normalText,
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              4.height,
              CustomText(
                text: '${hotspot.level} dBm · ${hotspot.verdict.reason}',
                fontSize: 12,
                color: AppColors.grey500,
                textAlign: TextAlign.left,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        AppSpacing.sm.width,
        StatusBadge(label: label, color: color),
      ],
    );
  }
}

class _LimitsCard extends StatelessWidget {
  const _LimitsCard();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'What this scan can\'t see',
      child: CustomText(
        text:
            '• Cameras that record to an SD card and never join Wi-Fi.\n'
            '• Cameras on a different network, their own hotspot, or mobile data.\n'
            '• Devices hidden by "client isolation", which hotel and guest Wi-Fi often turn on.\n\n'
            'A clean result doesn\'t mean the room is clear. Check smoke detectors, chargers, clocks and '
            'anything facing the bed or shower. Only scan networks you\'re allowed to use.',
        fontSize: 13,
        color: AppColors.grey600,
        textAlign: TextAlign.left,
        height: 1.45,
      ),
    );
  }
}
