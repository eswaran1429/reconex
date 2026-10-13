import 'package:get/get.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/core/utils/json_utils.dart';
import 'package:reconex/data/services/domain_service.dart';

class SecurityArgs {
  final String domainId;

  /// 0 = security headers, 1 = exposed resources.
  final int initialTab;

  const SecurityArgs({required this.domainId, this.initialTab = 0});
}

/// State of one check type: latest stored snapshot, replaced by a live run.
class SecurityCheck {
  SecurityCheck(this.type);

  /// `headers` or `exposed_resources`, as used by `/domain/history`.
  final String type;
  final RxList<Json> rows = <Json>[].obs;
  final Rxn<DateTime> scannedAt = Rxn<DateTime>();
  final RxBool isLoading = true.obs;
  final RxBool isRunning = false.obs;
  final RxnString error = RxnString();

  bool isIssue(Json row) => type == 'headers' ? row['present'] != true : row['accessible'] == true;

  int get issueCount => rows.where(isIssue).length;
}

class SecurityController extends GetxController {
  final DomainService _domainService = Get.find();
  final SecurityArgs args = Get.arguments as SecurityArgs;

  final SecurityCheck headers = SecurityCheck('headers');
  final SecurityCheck exposed = SecurityCheck('exposed_resources');

  @override
  void onInit() {
    super.onInit();
    loadLatest(headers);
    loadLatest(exposed);
  }

  Future<void> loadLatest(SecurityCheck check) async {
    check.isLoading.value = true;
    check.error.value = null;
    try {
      final page = await _domainService.history(args.domainId, type: check.type, limit: 1);
      if (page.items.isNotEmpty) _apply(check, asList(page.items.first['results']), page.items.first['scannedAt']);
    } catch (e) {
      check.error.value = e.toString();
    } finally {
      check.isLoading.value = false;
    }
  }

  Future<void> run(SecurityCheck check) async {
    check.isRunning.value = true;
    check.error.value = null;
    try {
      final rows = check == headers
          ? await _domainService.securityHeaders(args.domainId)
          : await _domainService.exposedResources(args.domainId);
      _apply(check, rows, rows.isEmpty ? null : asMap(rows.first)['scannedAt']);
    } catch (e) {
      check.error.value = e.toString();
    } finally {
      check.isRunning.value = false;
    }
  }

  void _apply(SecurityCheck check, List<dynamic> rows, Object? scannedAt) {
    final list = rows.map(asMap).toList()
      // Issues first.
      ..sort((a, b) => (check.isIssue(b) ? 1 : 0) - (check.isIssue(a) ? 1 : 0));
    check.rows.assignAll(list);
    check.scannedAt.value = parseDate(scannedAt) ?? DateTime.now();
  }
}
