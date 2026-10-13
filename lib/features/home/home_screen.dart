import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_navigation_bar/custom_navigation_bar.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/features/account/account_tab.dart';
import 'package:reconex/features/alerts/alerts_tab.dart';
import 'package:reconex/features/domains/domains_tab.dart';

class HomeController extends GetxController {
  final RxInt tab = 0.obs;
}

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  static const List<NavItem> _navItems = [
    NavItem(
      icon: Icon(Icons.language_rounded, size: 21, color: AppColors.grey400),
      activeIcon: Icon(Icons.language_rounded, size: 21),
      label: 'Domains',
    ),
    NavItem(
      icon: Icon(Icons.notifications_none_rounded, size: 21, color: AppColors.grey400),
      activeIcon: Icon(Icons.notifications_rounded, size: 21),
      label: 'Alerts',
    ),
    NavItem(
      icon: Icon(Icons.person_outline_rounded, size: 21, color: AppColors.grey400),
      activeIcon: Icon(Icons.person_rounded, size: 21),
      label: 'Account',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      extendBody: true,
      body: Obx(
        () => IndexedStack(index: controller.tab.value, children: const [DomainsTab(), AlertsTab(), AccountTab()]),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Obx(
            () => CustomNavigationBar(
              currentIndex: controller.tab.value,
              onTap: (i) => controller.tab.value = i,
              items: _navItems,
            ),
          ),
        ),
      ),
    );
  }
}
