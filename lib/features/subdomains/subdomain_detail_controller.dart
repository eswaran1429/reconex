import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/utils/json_utils.dart';
import 'package:reconex/data/models/subdomain.dart';
import 'package:reconex/data/services/port_service.dart';
import 'package:reconex/data/services/subdomain_service.dart';
import 'package:reconex/data/services/technology_service.dart';

class SubdomainDetailController extends GetxController {
  final SubdomainService _subdomainService = Get.find();
  final PortService _portService = Get.find();
  final TechnologyService _technologyService = Get.find();

  final String subdomainId = Get.arguments as String;

  final Rxn<Subdomain> subdomain = Rxn<Subdomain>();
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  final RxList<Json> ports = <Json>[].obs;
  final RxBool isScanningPorts = false.obs;

  final Rxn<Json> ssl = Rxn<Json>();
  final RxBool isCheckingSsl = false.obs;
  final RxnString sslError = RxnString();

  /// Null until detection has run once.
  final Rxn<List<Json>> technologies = Rxn<List<Json>>();
  final RxBool isDetectingTech = false.obs;
  final RxnString techError = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final results = await Future.wait([_subdomainService.get(subdomainId), _portService.list(subdomainId)]);
      subdomain.value = results[0] as Subdomain;
      ports.assignAll((results[1] as List<dynamic>).map(asMap));
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> scanPorts() async {
    isScanningPorts.value = true;
    try {
      final open = await _portService.discover(subdomainId);
      ports.assignAll((await _portService.list(subdomainId)).map(asMap));
      AppSnackbar.success('Port scan finished', '${open.length} open ports');
    } catch (e) {
      AppSnackbar.warning('Port scan failed', e.toString());
    } finally {
      isScanningPorts.value = false;
    }
  }

  Future<void> checkSsl() async {
    isCheckingSsl.value = true;
    sslError.value = null;
    try {
      ssl.value = await _subdomainService.ssl(subdomainId);
    } catch (e) {
      sslError.value = e.toString();
    } finally {
      isCheckingSsl.value = false;
    }
  }

  Future<void> detectTechnologies() async {
    isDetectingTech.value = true;
    techError.value = null;
    try {
      technologies.value = (await _technologyService.detect(subdomainId)).map(asMap).toList();
    } catch (e) {
      techError.value = e.toString();
    } finally {
      isDetectingTech.value = false;
    }
  }
}
