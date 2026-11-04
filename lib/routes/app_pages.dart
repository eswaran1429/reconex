import 'package:get/get.dart';
import 'package:reconex/features/asset_map/asset_map_screen.dart';
import 'package:reconex/features/alerts/alerts_controller.dart';
import 'package:reconex/features/auth/controllers/login_controller.dart';
import 'package:reconex/features/auth/controllers/signup_controller.dart';
import 'package:reconex/features/auth/screens/login_screen.dart';
import 'package:reconex/features/auth/screens/signup_screen.dart';
import 'package:reconex/features/changes/change_detail_screen.dart';
import 'package:reconex/features/changes/changes_controller.dart';
import 'package:reconex/features/changes/changes_screen.dart';
import 'package:reconex/features/dns/dns_screen.dart';
import 'package:reconex/features/domain_detail/domain_detail_controller.dart';
import 'package:reconex/features/domain_detail/domain_detail_screen.dart';
import 'package:reconex/features/domains/domains_controller.dart';
import 'package:reconex/features/home/home_screen.dart';
import 'package:reconex/features/networks/lan_device_detail_screen.dart';
// Risk feature disabled for now.
// import 'package:reconex/features/risk/risk_detail_screen.dart';
// import 'package:reconex/features/risk/risk_findings_screen.dart';
// import 'package:reconex/features/risk/risk_overview_controller.dart';
import 'package:reconex/features/networks/network_changes_screen.dart';
import 'package:reconex/features/networks/network_detail_screen.dart';
import 'package:reconex/features/networks/network_devices_screen.dart';
import 'package:reconex/features/networks/network_scans_screen.dart';
import 'package:reconex/features/networks/networks_tab.dart';
import 'package:reconex/features/ports/domain_ports_screen.dart';
import 'package:reconex/features/scans/scan_detail_controller.dart';
import 'package:reconex/features/scans/scan_detail_screen.dart';
import 'package:reconex/features/scans/scans_screen.dart';
import 'package:reconex/features/security/security_controller.dart';
import 'package:reconex/features/security/security_screen.dart';
import 'package:reconex/features/splash/splash_controller.dart';
import 'package:reconex/features/splash/splash_screen.dart';
import 'package:reconex/features/subdomains/subdomain_detail_controller.dart';
import 'package:reconex/features/subdomains/subdomain_detail_screen.dart';
import 'package:reconex/features/subdomains/subdomains_screen.dart';
import 'package:reconex/features/technologies/domain_technologies_screen.dart';
import 'package:reconex/routes/app_routes.dart';

class AppPages {
  AppPages._();

  static const String initial = AppRoutes.splash;

  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: BindingsBuilder(() {
        Get.put(SplashController());
      }),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => LoginController());
      }),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SignupController());
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => HomeController());
        Get.lazyPut(() => DomainsController());
        Get.lazyPut(() => NetworksController());
        Get.lazyPut(() => AlertsController());
      }),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.domainDetail,
      page: () => const DomainDetailScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DomainDetailController());
        // Risk feature disabled for now.
        // Get.lazyPut(() => RiskOverviewController());
      }),
    ),
    GetPage(
      name: AppRoutes.scans,
      page: () => const ScansScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ScansController());
      }),
    ),
    GetPage(
      name: AppRoutes.scanDetail,
      page: () => const ScanDetailScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ScanDetailController());
      }),
    ),
    GetPage(
      name: AppRoutes.changes,
      page: () => const ChangesScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ChangesController());
      }),
    ),
    GetPage(
      name: AppRoutes.changeDetail,
      page: () => const ChangeDetailScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ChangeDetailController());
      }),
    ),
    GetPage(
      name: AppRoutes.subdomains,
      page: () => const SubdomainsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SubdomainsController());
      }),
    ),
    GetPage(
      name: AppRoutes.subdomainDetail,
      page: () => const SubdomainDetailScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SubdomainDetailController());
      }),
    ),
    GetPage(
      name: AppRoutes.dns,
      page: () => const DnsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DnsController());
      }),
    ),
    GetPage(
      name: AppRoutes.ports,
      page: () => const DomainPortsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DomainPortsController());
      }),
    ),
    GetPage(
      name: AppRoutes.technologies,
      page: () => const DomainTechnologiesScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DomainTechnologiesController());
      }),
    ),
    GetPage(
      name: AppRoutes.assetMap,
      page: () => const AssetMapScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AssetMapController());
      }),
    ),
    GetPage(
      name: AppRoutes.security,
      page: () => const SecurityScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SecurityController());
      }),
    ),
    GetPage(
      name: AppRoutes.networkDetail,
      page: () => const NetworkDetailScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => NetworkDetailController());
      }),
    ),
    GetPage(
      name: AppRoutes.networkScans,
      page: () => const NetworkScansScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => NetworkScansController());
      }),
    ),
    GetPage(
      name: AppRoutes.networkScan,
      page: () => const NetworkScanScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => NetworkScanController());
      }),
    ),
    GetPage(
      name: AppRoutes.networkDevices,
      page: () => const NetworkDevicesScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => NetworkDevicesController());
      }),
    ),
    GetPage(
      name: AppRoutes.networkDevice,
      page: () => const NetworkDeviceScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => NetworkDeviceController());
      }),
    ),
    GetPage(
      name: AppRoutes.networkChanges,
      page: () => const NetworkChangesScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => NetworkChangesController());
      }),
    ),
    GetPage(
      name: AppRoutes.lanDevice,
      page: () => const LanDeviceDetailScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => LanDeviceController());
      }),
    ),
    // Risk feature disabled for now.
    // GetPage(
    //   name: AppRoutes.risks,
    //   page: () => const RiskFindingsScreen(),
    //   binding: BindingsBuilder(() {
    //     Get.lazyPut(() => RiskFindingsController());
    //   }),
    // ),
    // GetPage(
    //   name: AppRoutes.riskDetail,
    //   page: () => const RiskDetailScreen(),
    //   binding: BindingsBuilder(() {
    //     Get.lazyPut(() => RiskDetailController());
    //   }),
    // ),
  ];
}
