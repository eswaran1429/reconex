import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:reconex/core/network/api_client.dart';
import 'package:reconex/core/storage/token_storage.dart';
import 'package:reconex/data/services/alert_service.dart';
import 'package:reconex/data/services/auth_service.dart';
import 'package:reconex/data/services/change_service.dart';
import 'package:reconex/data/services/domain_service.dart';
import 'package:reconex/data/services/lan_scan_service.dart';
import 'package:reconex/data/services/network_service.dart';
import 'package:reconex/data/services/port_service.dart';
import 'package:reconex/data/services/scan_service.dart';
import 'package:reconex/data/services/subdomain_service.dart';
import 'package:reconex/data/services/technology_service.dart';
import 'package:reconex/routes/app_routes.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final tokenStorage = Get.put(TokenStorage(), permanent: true);
    final api = Get.put(ApiClient(tokenStorage, onUnauthorized: _onUnauthorized), permanent: true);

    Get.put(AuthService(api, tokenStorage), permanent: true);
    Get.put(DomainService(api), permanent: true);
    Get.put(ScanService(api), permanent: true);
    Get.put(ChangeService(api), permanent: true);
    Get.put(AlertService(api), permanent: true);
    Get.put(SubdomainService(api), permanent: true);
    Get.put(PortService(api), permanent: true);
    Get.put(TechnologyService(api), permanent: true);
    Get.put(NetworkService(api), permanent: true);
    Get.put(LanScanService(), permanent: true);
  }

  static Future<void> _onUnauthorized() async {
    if (Get.currentRoute == AppRoutes.login) return;
    Get.offAllNamed(AppRoutes.login);
    AppSnackbar.warning('Session expired', 'Please log in again');
  }
}
