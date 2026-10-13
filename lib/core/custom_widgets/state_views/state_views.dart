import 'package:flutter/material.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/shimmer/shimmer.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: const BoxDecoration(color: AppColors.amber50, shape: BoxShape.circle),
              child: Icon(icon, size: 34, color: AppColors.amber600),
            ),
            AppSpacing.lg.height,
            CustomText(
              text: title,
              fontSize: AppTextTokens.titleSmSize,
              fontWeight: FontWeight.bold,
              color: AppColors.normalText,
            ),
            AppSpacing.sm.height,
            CustomText(text: message, fontSize: AppTextTokens.bodySmSize, color: AppColors.grey500, height: 1.4),
            if (actionLabel != null && onAction != null) ...[
              AppSpacing.xl.height,
              TextButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, color: AppColors.amber700),
                label: CustomText(text: actionLabel!, fontWeight: FontWeight.bold, color: AppColors.amber700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: const BoxDecoration(color: AppColors.red50, shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_rounded, size: 34, color: AppColors.red500),
            ),
            AppSpacing.lg.height,
            const CustomText(
              text: 'Something went wrong',
              fontSize: AppTextTokens.titleSmSize,
              fontWeight: FontWeight.bold,
              color: AppColors.normalText,
            ),
            AppSpacing.sm.height,
            CustomText(text: message, fontSize: AppTextTokens.bodySmSize, color: AppColors.grey500, height: 1.4),
            AppSpacing.xl.height,
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.amber700),
              label: const CustomText(text: 'Try again', fontWeight: FontWeight.bold, color: AppColors.amber700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmering placeholder cards shown while a list loads.
class CardListSkeleton extends StatelessWidget {
  final int count;

  const CardListSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return SkeletonList(count: count, itemBuilder: (_) => const TripCardSkeleton());
  }
}
