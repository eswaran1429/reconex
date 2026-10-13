import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/controllers/paged_controller.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/paged_list_view/paged_list_view.dart';
import 'package:reconex/core/custom_widgets/section_card/section_card.dart';
import 'package:reconex/core/custom_widgets/state_views/state_views.dart';
import 'package:reconex/core/custom_widgets/status_badge/status_badge.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/data/models/subdomain.dart';
import 'package:reconex/data/services/subdomain_service.dart';
import 'package:reconex/routes/app_routes.dart';

class SubdomainsController extends PagedController<Subdomain> {
  final SubdomainService _subdomainService = Get.find();
  final String domainId = Get.arguments as String;

  final RxBool isDiscovering = false.obs;

  @override
  Future<Paginated<Subdomain>> fetchPage(int page) => _subdomainService.list(domainId, page: page);

  Future<void> discover() async {
    isDiscovering.value = true;
    try {
      final found = await _subdomainService.discover(domainId);
      AppSnackbar.success('Discovery finished', 'Found ${found.length} subdomains');
      await refreshList();
    } catch (e) {
      AppSnackbar.warning('Discovery failed', e.toString());
    } finally {
      isDiscovering.value = false;
    }
  }

  void openSubdomain(Subdomain subdomain) => Get.toNamed(AppRoutes.subdomainDetail, arguments: subdomain.id);
}

class SubdomainsScreen extends GetView<SubdomainsController> {
  const SubdomainsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subdomains'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Obx(
              () => SmallActionButton(
                label: 'Discover',
                icon: Icons.travel_explore_rounded,
                loading: controller.isDiscovering.value,
                onTap: controller.discover,
              ),
            ),
          ),
        ],
      ),
      body: PagedListView<Subdomain>(
        controller: controller,
        empty: EmptyState(
          icon: Icons.account_tree_outlined,
          title: 'No subdomains yet',
          message: 'Run discovery to check common prefixes like www, api, admin and mail.',
          actionLabel: 'Discover now',
          onAction: controller.discover,
        ),
        itemBuilder: (_, subdomain) =>
            _SubdomainCard(subdomain: subdomain, onTap: () => controller.openSubdomain(subdomain)),
      ),
    );
  }
}

class _SubdomainCard extends StatelessWidget {
  final Subdomain subdomain;
  final VoidCallback onTap;

  const _SubdomainCard({required this.subdomain, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: AppRadius.rSm),
            child: const Icon(Icons.dns_outlined, color: AppColors.teal),
          ),
          AppSpacing.md.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: subdomain.hostname,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.normalText,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                4.height,
                CustomText(
                  text: '${subdomain.ipAddress ?? 'No IP'} · seen ${timeAgo(subdomain.lastSeenAt)}',
                  fontSize: 12,
                  color: AppColors.grey500,
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
          if (subdomain.status.isNotEmpty) StatusBadge.status(subdomain.status),
          const Icon(Icons.chevron_right_rounded, color: AppColors.grey300),
        ],
      ),
    );
  }
}
