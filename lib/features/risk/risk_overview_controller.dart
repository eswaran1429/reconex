import 'package:get/get.dart';
import 'package:reconex/core/network/api_exception.dart';
import 'package:reconex/data/models/risk.dart';
import 'package:reconex/data/services/risk_service.dart';
import 'package:reconex/features/risk/risk_findings_screen.dart';
import 'package:reconex/routes/app_routes.dart';

/// Loads the risk score and history for the domain dashboard's Risk Overview.
/// Kept apart from the dashboard load so a missing score never blocks the page.
class RiskOverviewController extends GetxController {
  final RiskService _riskService = Get.find();
  final String domainId = Get.arguments as String;

  final Rxn<RiskScore> score = Rxn<RiskScore>();
  final RxList<RiskHistoryPoint> history = <RiskHistoryPoint>[].obs;
  final RxBool isLoading = true.obs;

  /// True when the domain has no score yet (never scanned).
  final RxBool notScored = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      score.value = await _riskService.score(domainId);
      // Oldest-first for the left-to-right chart; API returns newest-first.
      final page = await _riskService.history(domainId, limit: 20);
      history.assignAll(page.items.reversed);
      notScored.value = false;
      error.value = null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        notScored.value = true;
        error.value = null;
      } else {
        error.value = e.message;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void openFindings({String? severity}) => Get.toNamed(
    AppRoutes.risks,
    arguments: RiskFindingsArgs(domainId: domainId, severity: severity),
  );

  void openRisk(String riskId) => Get.toNamed(AppRoutes.riskDetail, arguments: riskId);
}
