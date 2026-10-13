import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/refresh_indicator/app_refresh_indicator.dart';
import 'package:reconex/core/custom_widgets/section_card/section_card.dart';
import 'package:reconex/core/custom_widgets/state_views/state_views.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/core/utils/json_utils.dart';
import 'package:reconex/data/services/domain_service.dart';

class DomainTechnologiesController extends GetxController {
  final DomainService _domainService = Get.find();
  final String domainId = Get.arguments as String;

  final RxList<Json> technologies = <Json>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    error.value = null;
    try {
      technologies.assignAll((await _domainService.technologies(domainId)).map(asMap));
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> retry() {
    isLoading.value = true;
    return load();
  }
}

class DomainTechnologiesScreen extends GetView<DomainTechnologiesController> {
  const DomainTechnologiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Technologies')),
      body: Obx(() {
        if (controller.isLoading.value) return const CardListSkeleton(count: 4);
        final error = controller.error.value;
        if (error != null && controller.technologies.isEmpty) {
          return ErrorState(message: error, onRetry: controller.retry);
        }
        final items = controller.technologies;
        return AppRefreshIndicator(
          onRefresh: controller.load,
          slivers: [
            if (items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.memory_rounded,
                  title: 'No technologies',
                  message: 'Run a full scan to fingerprint the sites on every subdomain.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => AppSpacing.md.height,
                  itemBuilder: (_, i) => _TechnologyCard(technology: items[i]),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _TechnologyCard extends StatelessWidget {
  final Json technology;

  const _TechnologyCard({required this.technology});

  @override
  Widget build(BuildContext context) {
    final subdomains = asList(technology['subdomains']).map(asMap).toList();
    final count = technology['subdomainCount'] is num ? asInt(technology['subdomainCount']) : subdomains.length;
    final category = technology['category'];
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: AppRadius.rSm),
                child: const Icon(Icons.memory_rounded, color: AppColors.teal, size: 20),
              ),
              AppSpacing.md.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: asText(technology['name']),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.normalText,
                      textAlign: TextAlign.left,
                    ),
                    if (category != null) ...[
                      2.height,
                      CustomText(
                        text: humanize(asText(category)),
                        fontSize: 12,
                        color: AppColors.grey500,
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ],
                ),
              ),
              CustomText(
                text: '$count ${count == 1 ? 'host' : 'hosts'}',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.grey700,
              ),
            ],
          ),
          if (subdomains.isNotEmpty) ...[
            const Divider(height: AppSpacing.xl, color: AppColors.grey100),
            for (final s in subdomains)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        text: asText(s['hostname']),
                        fontSize: 13,
                        color: AppColors.normalText,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (s['version'] != null) ...[
                      AppSpacing.sm.width,
                      CustomText(text: 'v${asText(s['version'])}', fontSize: 12, color: AppColors.grey500),
                    ],
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
