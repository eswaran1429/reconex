import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:reconex/core/network/paginated.dart';

/// Loads a paginated endpoint page by page. Subclasses implement [fetchPage].
abstract class PagedController<T> extends GetxController {
  final RxList<T> items = <T>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxnString error = RxnString();
  final RxInt total = 0.obs;

  int _page = 0;
  int _totalPages = 0;

  // Bumped on every refresh so responses from an older filter are dropped.
  int _generation = 0;

  bool get hasMore => _page < _totalPages;

  Future<Paginated<T>> fetchPage(int page);

  @override
  void onInit() {
    super.onInit();
    refreshList();
  }

  /// Clears the list and loads page 1, e.g. after a filter change.
  Future<void> reload() {
    items.clear();
    return refreshList();
  }

  Future<void> refreshList() async {
    final generation = ++_generation;
    if (items.isEmpty) isLoading.value = true;
    try {
      final result = await fetchPage(1);
      if (generation != _generation) return;
      items.assignAll(result.items);
      _apply(result);
      error.value = null;
    } catch (e) {
      if (generation != _generation) return;
      if (items.isEmpty) {
        error.value = e.toString();
      } else {
        AppSnackbar.warning('Refresh failed', e.toString());
      }
    } finally {
      if (generation == _generation) isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoading.value || isLoadingMore.value) return;
    final generation = _generation;
    isLoadingMore.value = true;
    try {
      final result = await fetchPage(_page + 1);
      if (generation != _generation) return;
      items.addAll(result.items);
      _apply(result);
    } catch (e) {
      if (generation == _generation) AppSnackbar.warning('Could not load more', e.toString());
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _apply(Paginated<T> result) {
    _page = result.page;
    _totalPages = result.totalPages;
    total.value = result.total;
  }
}
