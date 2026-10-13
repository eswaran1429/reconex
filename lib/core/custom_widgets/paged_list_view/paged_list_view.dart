import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/controllers/paged_controller.dart';
import 'package:reconex/core/custom_widgets/refresh_indicator/app_refresh_indicator.dart';
import 'package:reconex/core/custom_widgets/state_views/state_views.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';

/// Pull-to-refresh list with skeleton, error, empty and load-more states for a [PagedController].
class PagedListView<T> extends StatelessWidget {
  final PagedController<T> controller;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget empty;
  final List<Widget> header;
  final double bottomSpace;

  const PagedListView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    required this.empty,
    this.header = const [],
    this.bottomSpace = 32,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 300) controller.loadMore();
        return false;
      },
      child: AppRefreshIndicator(onRefresh: controller.refreshList, slivers: [...header, Obx(_body)]),
    );
  }

  Widget _body() {
    final items = controller.items;
    final error = controller.error.value;
    final loadingMore = controller.isLoadingMore.value;

    if (controller.isLoading.value && items.isEmpty) {
      return const SliverToBoxAdapter(child: CardListSkeleton());
    }
    if (error != null && items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorState(message: error, onRetry: controller.refreshList),
      );
    }
    if (items.isEmpty) return SliverFillRemaining(hasScrollBody: false, child: empty);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      sliver: SliverList.separated(
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) {
          if (i < items.length) return itemBuilder(context, items[i]);
          return SizedBox(
            height: bottomSpace + (loadingMore ? 40 : 0),
            child: loadingMore
                ? const Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }
}
