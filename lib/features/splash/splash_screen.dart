import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/features/splash/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.gradientButton),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutBack,
                builder: (context, value, child) => Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Transform.scale(scale: 0.6 + 0.4 * value, child: child),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 110,
                      width: 110,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: AppRadius.rLg,
                        boxShadow: AppShadows.lg,
                      ),
                      child: const Icon(Icons.hub_rounded, size: 56, color: AppColors.amber600),
                    ),
                    AppSpacing.xxl.height,
                    const CustomText(
                      text: 'Reconex',
                      fontSize: AppTextTokens.displaySize + 4,
                      fontWeight: AppTextTokens.displayWeight,
                      color: AppColors.white,
                      letterSpacing: 1.2,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const SizedBox(
                height: 26,
                width: 26,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white),
              ),
              40.height,
            ],
          ),
        ),
      ),
    );
  }
}
