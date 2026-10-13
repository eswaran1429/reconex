import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:reconex/data/models/domain.dart';
import 'package:reconex/data/services/domain_service.dart';
import 'package:reconex/features/domains/domain_form_sheet.dart';
import 'package:reconex/routes/app_routes.dart';

class DomainsController extends GetxController {
  final DomainService _domainService = Get.find();

  final RxList<Domain> domains = <Domain>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      domains.assignAll(await _domainService.getAll());
      error.value = null;
    } catch (e) {
      if (domains.isEmpty) {
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

  Future<void> openDomain(Domain domain) async {
    await Get.toNamed(AppRoutes.domainDetail, arguments: domain.id);
    load();
  }

  Future<void> addDomain() async {
    if (await DomainFormSheet.show() == true) load();
  }
}
