import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/bindings/initial_binding.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/routes/app_pages.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Reconex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.backgroundColor,
        fontFamily: 'JetBrainsMono',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundColor,
          surfaceTintColor: AppColors.transparent,
          foregroundColor: AppColors.normalText,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.normalText,
          ),
        ),
      ),
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
    );
  }
}
