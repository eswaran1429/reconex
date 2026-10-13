import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
import 'package:reconex/data/models/change.dart';
import 'package:reconex/data/services/change_service.dart';

class ChangeDetailController extends GetxController {
  final ChangeService _changeService = Get.find();
  final String changeId = Get.arguments as String;

  final Rxn<Change> change = Rxn<Change>();
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
      change.value = await _changeService.get(changeId);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}

class ChangeDetailScreen extends GetView<ChangeDetailController> {
  const ChangeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change')),
      body: Obx(() {
        if (controller.isLoading.value) return const CardListSkeleton(count: 3);
        final change = controller.change.value;
        if (change == null) return ErrorState(message: controller.error.value ?? 'No data', onRetry: controller.load);

        final color = severityColor(change.severity);
        final scan = change.scan;
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
                        child: Icon(AppIcons.category(change.category), color: color),
                      ),
                      AppSpacing.md.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: humanize(change.type),
                              fontSize: AppTextTokens.titleSmSize,
                              fontWeight: FontWeight.bold,
                              color: AppColors.normalText,
                              textAlign: TextAlign.left,
                            ),
                            2.height,
                            CustomText(
                              text: humanize(change.category),
                              fontSize: 13,
                              color: AppColors.grey500,
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                      StatusBadge.severity(change.severity),
                    ],
                  ),
                  AppSpacing.lg.height,
                  InfoRow(label: 'Key', value: change.key),
                  InfoRow(label: 'Detected', value: formatDateTime(change.createdAt)),
                  if (scan != null)
                    InfoRow(label: 'Scan', value: '${humanize(asText(scan['status']))} · ${asText(scan['id'])}'),
                ],
              ),
            ),
            AppSpacing.lg.height,
            _JsonBlock(title: 'Before', value: change.before),
            AppSpacing.lg.height,
            _JsonBlock(title: 'After', value: change.after),
            AppSpacing.xxl.height,
          ],
        );
      }),
    );
  }
}

class _JsonBlock extends StatelessWidget {
  final String title;
  final dynamic value;

  const _JsonBlock({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = value == null ? 'none' : const JsonEncoder.withIndent('  ').convert(value);
    return SectionCard(
      title: title,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.charcoal, borderRadius: AppRadius.rSm),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: CustomText(
            text: text,
            fontSize: 13,
            color: value == null ? AppColors.grey400 : AppColors.yellowg,
            textAlign: TextAlign.left,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
