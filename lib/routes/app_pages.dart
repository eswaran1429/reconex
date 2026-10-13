import 'package:get/get.dart';
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
        Get.lazyPut(() => AlertsController());
      }),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.domainDetail,
      page: () => const DomainDetailScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DomainDetailController());
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
      name: AppRoutes.security,
      page: () => const SecurityScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SecurityController());
      }),
    ),
  ];
}
