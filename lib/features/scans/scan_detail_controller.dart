import 'dart:async';

import 'package:get/get.dart';
import 'package:reconex/data/models/scan.dart';
import 'package:reconex/data/services/scan_service.dart';
import 'package:reconex/features/changes/changes_controller.dart';
import 'package:reconex/routes/app_routes.dart';

class ScanDetailController extends GetxController {
  final ScanService _scanService = Get.find();
  final String scanId = Get.arguments as String;

  final Rxn<Scan> scan = Rxn<Scan>();
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  static const Duration _pollInterval = Duration(seconds: 2);
  Timer? _poll;
  bool _polling = false;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    _poll?.cancel();
    super.onClose();
  }

  Future<void> load() async {
    try {
      scan.value = await _scanService.get(scanId);
      error.value = null;
    } catch (e) {
      if (scan.value == null) error.value = e.toString();
    } finally {
      isLoading.value = false;
      _syncPolling();
    }
  }

  Future<void> retry() {
    isLoading.value = true;
    error.value = null;
    return load();
  }

  void _syncPolling() {
    if (isClosed) return;
    if (scan.value?.isActive == true) {
      _poll ??= Timer.periodic(_pollInterval, (_) => _tick());
    } else {
      _poll?.cancel();
      _poll = null;
    }
  }

  Future<void> _tick() async {
    final current = scan.value;
    if (_polling || current == null) return;
    _polling = true;
    try {
      final next = current.mergeStatus(await _scanService.status(scanId));
      if (isClosed) return;
      scan.value = next;
      // Finished: fetch the full record for step details, change count and errors.
      if (!next.isActive) await load();
    } catch (_) {
      // Transient failure; the next tick retries.
    } finally {
      _polling = false;
    }
  }

  void openChanges() {
    final current = scan.value;
    if (current == null) return;
    Get.toNamed(
      AppRoutes.changes,
      arguments: ChangesArgs(domainId: current.domainId, scanId: current.id),
    );
  }
}
