import 'package:flutter/material.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';

/// White rounded card with an optional title row.
class SectionCard extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const SectionCard({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Ink paints the card on the Material, so ripples stay visible above the white fill.
    return Material(
      color: AppColors.transparent,
      child: Ink(
        decoration: BoxDecoration(color: AppColors.white, borderRadius: AppRadius.rMd, boxShadow: AppShadows.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.rMd,
          child: Container(
            width: double.infinity,
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          text: title!,
                          fontSize: AppTextTokens.titleSmSize,
                          fontWeight: FontWeight.bold,
                          color: AppColors.normalText,
                          textAlign: TextAlign.left,
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                  AppSpacing.md.height,
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact text button with an inline spinner, for section actions like "Scan".
class SmallActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;

  const SmallActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: AppRadius.rSm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppColors.amber50, borderRadius: AppRadius.rSm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            loading
                ? const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amber700),
                  )
                : Icon(icon, size: 16, color: AppColors.amber700),
            6.width,
            CustomText(text: label, fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.amber700),
          ],
        ),
      ),
    );
  }
}

/// Label/value row used in detail cards.
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const InfoRow({super.key, required this.label, required this.value, this.valueColor = AppColors.normalText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: CustomText(text: label, fontSize: 13, color: AppColors.grey500, textAlign: TextAlign.left),
          ),
          Expanded(
            child: CustomText(
              text: value,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor,
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
