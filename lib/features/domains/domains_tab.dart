import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/refresh_indicator/app_refresh_indicator.dart';
import 'package:reconex/core/custom_widgets/section_card/section_card.dart';
import 'package:reconex/core/custom_widgets/state_views/state_views.dart';
import 'package:reconex/core/custom_widgets/status_badge/status_badge.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/data/models/domain.dart';
import 'package:reconex/features/domains/domains_controller.dart';

class DomainsTab extends GetView<DomainsController> {
  const DomainsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AppRefreshIndicator(
        onRefresh: controller.load,
        slivers: [
          SliverToBoxAdapter(child: _Header(controller: controller)),
          Obx(() {
            if (controller.isLoading.value) return const SliverToBoxAdapter(child: CardListSkeleton());
            final error = controller.error.value;
            if (error != null) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorState(message: error, onRetry: controller.retry),
              );
            }
            if (controller.domains.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.language_rounded,
                  title: 'No domains yet',
                  message: 'Add a domain to start mapping and monitoring its attack surface.',
                  actionLabel: 'Add domain',
                  onAction: controller.addDomain,
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList.separated(
                itemCount: controller.domains.length,
                separatorBuilder: (_, _) => AppSpacing.md.height,
                itemBuilder: (_, i) {
                  final domain = controller.domains[i];
                  return _DomainCard(domain: domain, onTap: () => controller.openDomain(domain));
                },
              ),
            );
          }),
          // Room for the floating navigation bar.
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final DomainsController controller;

  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomText(
                  text: 'Domains',
                  fontSize: AppTextTokens.displaySize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.normalText,
                  textAlign: TextAlign.left,
                ),
                4.height,
                Obx(
                  () => CustomText(
                    text: controller.isLoading.value ? 'Loading…' : '${controller.domains.length} monitored',
                    fontSize: AppTextTokens.bodySmSize,
                    color: AppColors.grey500,
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: controller.addDomain,
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                gradient: AppColors.gradientButton,
                borderRadius: AppRadius.rSm,
                boxShadow: AppShadows.md,
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

class _DomainCard extends StatelessWidget {
  final Domain domain;
  final VoidCallback onTap;

  const _DomainCard({required this.domain, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initial = domain.name.isEmpty ? '?' : domain.name[0].toUpperCase();
    return SectionCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: domain.isActive ? AppColors.amber50 : AppColors.grey100,
              borderRadius: AppRadius.rSm,
            ),
            child: CustomText(
              text: initial,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: domain.isActive ? AppColors.amber700 : AppColors.grey500,
            ),
          ),
          AppSpacing.md.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: domain.name,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.normalText,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                4.height,
                CustomText(
                  text: domain.url,
                  fontSize: 13,
                  color: AppColors.grey500,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          AppSpacing.sm.width,
          StatusBadge.status(domain.status),
          const Icon(Icons.chevron_right_rounded, color: AppColors.grey300),
        ],
      ),
    );
  }
}
