import 'package:get/get.dart';
import 'package:reconex/core/controllers/paged_controller.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/data/models/change.dart';
import 'package:reconex/data/models/severity.dart';
import 'package:reconex/data/services/change_service.dart';
import 'package:reconex/routes/app_routes.dart';

class ChangesArgs {
  final String domainId;

  /// When set, only changes from this scan are listed.
  final String? scanId;

  const ChangesArgs({required this.domainId, this.scanId});
}

class ChangesController extends PagedController<Change> {
  final ChangeService _changeService = Get.find();
  final ChangesArgs args = Get.arguments as ChangesArgs;

  static const List<String> categories = [
    'subdomains',
    'ports',
    'dns',
    'ssl',
    'technologies',
    'headers',
    'exposed_resources',
  ];

  final RxSet<Severity> severities = <Severity>{}.obs;
  final RxnString category = RxnString();

  @override
  Future<Paginated<Change>> fetchPage(int page) => _changeService.listForDomain(
    args.domainId,
    page: page,
    scanId: args.scanId,
    category: category.value,
    severity: severities.isEmpty ? null : severities.map((s) => s.name).toList(),
  );

  void toggleSeverity(Severity severity) {
    if (!severities.remove(severity)) severities.add(severity);
    reload();
  }

  void selectCategory(String? value) {
    category.value = category.value == value ? null : value;
    reload();
  }

  void openChange(Change change) => Get.toNamed(AppRoutes.changeDetail, arguments: change.id);
}
