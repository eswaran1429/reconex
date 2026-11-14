import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/confirm_dialog/confirm_dialog.dart';
import 'package:reconex/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:reconex/core/network/api_exception.dart';
import 'package:reconex/core/storage/json_cache.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/data/models/domain.dart';
import 'package:reconex/data/services/domain_service.dart';
import 'package:reconex/data/services/scan_service.dart';
import 'package:reconex/features/changes/changes_controller.dart';
import 'package:reconex/features/domains/domain_form_sheet.dart';
import 'package:reconex/features/security/security_controller.dart';
import 'package:reconex/routes/app_routes.dart';

class DomainDetailController extends GetxController {
  final DomainService _domainService = Get.find();
  final ScanService _scanService = Get.find();

  final String domainId = Get.arguments as String;

  final Rxn<Json> dashboard = Rxn<Json>();
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();
  final RxBool isStartingScan = false.obs;

  Domain? get domain => dashboard.value?['domain'] is Map ? Domain.fromJson(dashboard.value!['domain'] as Json) : null;

  final JsonCache _cache = Get.find();
  String get _cacheKey => 'dashboard_$domainId';

  @override
  void onInit() {
    super.onInit();
    _loadCached();
    load();
  }

  /// Paint last-seen data instantly, so the network call isn't a blank shimmer.
  Future<void> _loadCached() async {
    final cached = await _cache.readMap(_cacheKey);
    if (cached != null && dashboard.value == null) {
      dashboard.value = cached;
      isLoading.value = false;
    }
  }

  Future<void> load() async {
    try {
      final data = await _domainService.dashboard(domainId);
      dashboard.value = data;
      error.value = null;
      _cache.write(_cacheKey, data);
    } catch (e) {
      if (dashboard.value == null) {
        error.value = e.toString();
      } else {
        AppSnackbar.warning('Refresh failed', e.toString());
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> retry() {
    isLoading.value = true;
    error.value = null;
    return load();
  }

  Future<void> startScan() async {
    isStartingScan.value = true;
    try {
      final scan = await _scanService.start(domainId);
      isStartingScan.value = false;
      await openScan(scan.id);
    } on ApiException catch (e) {
      // 409 "Scan scan_N is already running for this domain": open that scan instead.
      final running = RegExp(r'scan_\d+').firstMatch(e.message)?.group(0);
      if (e.statusCode == 409 && running != null) {
        isStartingScan.value = false;
        await openScan(running);
      } else {
        AppSnackbar.warning('Could not start scan', e.message);
      }
    } finally {
      if (!isClosed) isStartingScan.value = false;
    }
  }

  Future<void> openScan(String scanId) async {
    await Get.toNamed(AppRoutes.scanDetail, arguments: scanId);
    load();
  }

  Future<void> open(String route, {Object? arguments}) async {
    await Get.toNamed(route, arguments: arguments ?? domainId);
    load();
  }

  void openChanges() => open(AppRoutes.changes, arguments: ChangesArgs(domainId: domainId));

  void openSecurity(int tab) => open(
    AppRoutes.security,
    arguments: SecurityArgs(domainId: domainId, initialTab: tab),
  );

  Future<void> edit() async {
    final current = domain;
    if (current == null) return;
    if (await DomainFormSheet.show(domain: current) == true) load();
  }

  Future<void> delete() async {
    final confirmed = await AppConfirmDialog.show(
      title: 'Delete ${domain?.name ?? 'domain'}?',
      message: 'This also deletes all of its subdomains, scans, changes, alerts and findings. This cannot be undone.',
      confirmText: 'Delete',
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed) return;
    try {
      await _domainService.delete(domainId);
      // Back to the domains list if it is open, else the dashboard.
      Get.until((route) => route.settings.name == AppRoutes.domains || route.settings.name == AppRoutes.home);
      AppSnackbar.success('Domain deleted', domain?.name ?? '');
    } catch (e) {
      AppSnackbar.warning('Delete failed', e.toString());
    }
  }
}
