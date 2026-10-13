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
import 'package:reconex/core/utils/json_utils.dart';
import 'package:reconex/data/services/domain_service.dart';

class DnsController extends GetxController {
  final DomainService _domainService = Get.find();
  final String domainId = Get.arguments as String;

  final RxList<Json> records = <Json>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  static const List<String> typeOrder = ['A', 'AAAA', 'CNAME', 'MX', 'NS', 'TXT', 'SOA'];

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Live lookup; the server replaces its stored records with the result.
  Future<void> load() async {
    error.value = null;
    try {
      records.assignAll((await _domainService.dns(domainId)).map(asMap));
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

  Map<String, List<Json>> get byType {
    final groups = <String, List<Json>>{};
    for (final record in records) {
      groups.putIfAbsent(asText(record['type']), () => []).add(record);
    }
    final keys = groups.keys.toList()
      ..sort((a, b) {
        final ia = typeOrder.indexOf(a), ib = typeOrder.indexOf(b);
        return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
      });
    return {for (final k in keys) k: groups[k]!};
  }
}

class DnsScreen extends GetView<DnsController> {
  const DnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DNS records')),
      body: Obx(() {
        if (controller.isLoading.value) return const CardListSkeleton(count: 4);
        final error = controller.error.value;
        if (error != null && controller.records.isEmpty) {
          return ErrorState(message: error, onRetry: controller.retry);
        }
        final groups = controller.byType;
        return AppRefreshIndicator(
          onRefresh: controller.load,
          slivers: [
            if (groups.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.dns_outlined,
                  title: 'No DNS records',
                  message: 'The lookup found no A, AAAA, CNAME, MX, NS, TXT or SOA records.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList.list(
                  children: [
                    const CustomText(
                      text: 'Looked up live just now. Pull down to look up again.',
                      fontSize: 12,
                      color: AppColors.grey500,
                      textAlign: TextAlign.left,
                    ),
                    AppSpacing.md.height,
                    for (final entry in groups.entries) ...[
                      _TypeCard(type: entry.key, records: entry.value),
                      AppSpacing.md.height,
                    ],
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String type;
  final List<Json> records;

  const _TypeCard({required this.type, required this.records});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: type,
      trailing: CustomText(text: '${records.length}', fontSize: 13, color: AppColors.grey500),
      child: Column(
        children: [
          for (var i = 0; i < records.length; i++) ...[
            if (i > 0) const Divider(height: AppSpacing.lg, color: AppColors.grey100),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: asText(records[i]['value']),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.normalText,
                        textAlign: TextAlign.left,
                      ),
                      2.height,
                      CustomText(
                        text: asText(records[i]['name']),
                        fontSize: 12,
                        color: AppColors.grey500,
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
                if (records[i]['ttl'] != null)
                  CustomText(text: 'TTL ${asText(records[i]['ttl'])}', fontSize: 11, color: AppColors.grey400),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
