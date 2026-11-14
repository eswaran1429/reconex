import 'package:flutter/material.dart';
import 'package:reconex/core/themes/app_colors.dart';

/// Hosts a former bottom-nav tab as a pushed page: a slim back bar above the
/// tab's own large header, and the bottom inset kept clear.
class SectionPage extends StatelessWidget {
  final Widget child;

  const SectionPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 48,
      ),
      body: SafeArea(top: false, child: child),
    );
  }
}
