import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/controllers/paged_controller.dart';
import 'package:reconex/core/custom_widgets/paged_list_view/paged_list_view.dart';
import 'package:reconex/core/custom_widgets/state_views/state_views.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/data/models/network.dart';
import 'package:reconex/data/services/network_service.dart';
import 'package:reconex/features/networks/network_widgets.dart';
import 'package:reconex/routes/app_routes.dart';

class NetworkChangesController extends PagedController<NetworkChange> {
  final NetworkService _networkService = Get.find();
  final String networkId = Get.arguments as String;

  @override
  Future<Paginated<NetworkChange>> fetchPage(int page) => _networkService.changes(networkId, page: page);

  void openChange(NetworkChange change) {
    if (change.deviceId != null) Get.toNamed(AppRoutes.networkDevice, arguments: change.deviceId);
  }
}

class NetworkChangesScreen extends GetView<NetworkChangesController> {
  const NetworkChangesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network changes')),
      body: PagedListView<NetworkChange>(
        controller: controller,
        empty: const EmptyState(
          icon: Icons.change_circle_outlined,
          title: 'No changes',
          message: 'Changes are recorded when a completed scan differs from the previous one.',
        ),
        itemBuilder: (_, change) => Material(
          color: AppColors.white,
          borderRadius: AppRadius.rMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: NetworkChangeTile(change: change, onTap: () => controller.openChange(change)),
          ),
        ),
      ),
    );
  }
}
