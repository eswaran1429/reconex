import 'package:flutter/material.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            gradient: AppColors.gradientButton,
            borderRadius: AppRadius.rMd,
            boxShadow: AppShadows.md,
          ),
          child: const Icon(Icons.hub_rounded, size: 34, color: AppColors.white),
        ),
        AppSpacing.xxl.height,
        CustomText(
          text: title,
          fontSize: AppTextTokens.displaySize,
          fontWeight: AppTextTokens.displayWeight,
          color: AppColors.normalText,
          textAlign: TextAlign.left,
        ),
        AppSpacing.sm.height,
        CustomText(
          text: subtitle,
          fontSize: AppTextTokens.bodySize,
          color: AppColors.lightText,
          textAlign: TextAlign.left,
          height: 1.4,
        ),
      ],
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  final String text;

  const AuthFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.xs),
      child: CustomText(
        text: text,
        fontSize: AppTextTokens.bodySmSize,
        fontWeight: FontWeight.w600,
        color: AppColors.normalText,
        textAlign: TextAlign.left,
      ),
    );
  }
}

class AuthSwitchPrompt extends StatelessWidget {
  final String prompt;
  final String action;
  final VoidCallback onTap;

  const AuthSwitchPrompt({super.key, required this.prompt, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomText(text: prompt, fontSize: AppTextTokens.bodySmSize, color: AppColors.lightText),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
            child: CustomText(
              text: action,
              fontSize: AppTextTokens.bodySmSize,
              fontWeight: FontWeight.bold,
              color: AppColors.amber700,
            ),
          ),
        ),
      ],
    );
  }
}

class PasswordVisibilityToggle extends StatelessWidget {
  final bool obscured;
  final VoidCallback onTap;

  const PasswordVisibilityToggle({super.key, required this.obscured, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppColors.grey500,
        size: 20,
      ),
    );
  }
}
