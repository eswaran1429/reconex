import 'package:get/get.dart';
import 'package:reconex/core/controllers/paged_controller.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/data/models/app_alert.dart';
import 'package:reconex/data/models/severity.dart';
import 'package:reconex/data/services/alert_service.dart';
import 'package:reconex/routes/app_routes.dart';

class AlertsController extends PagedController<AppAlert> {
  final AlertService _alertService = Get.find();

  final RxSet<Severity> severities = <Severity>{}.obs;

  @override
  Future<Paginated<AppAlert>> fetchPage(int page) =>
      _alertService.list(page: page, severity: severities.isEmpty ? null : severities.map((s) => s.name).toList());

  void toggleSeverity(Severity severity) {
    if (!severities.remove(severity)) severities.add(severity);
    reload();
  }

  void openAlert(AppAlert alert) => Get.toNamed(AppRoutes.domainDetail, arguments: alert.domainId);
}
