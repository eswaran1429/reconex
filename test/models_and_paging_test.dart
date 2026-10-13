import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:reconex/core/controllers/paged_controller.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/data/models/scan.dart';

/// Serves pages from a callback so tests control timing and content.
class _TestPaged extends PagedController<int> {
  _TestPaged(this.fetch);

  final Future<Paginated<int>> Function(int page) fetch;

  @override
  Future<Paginated<int>> fetchPage(int page) => fetch(page);
}

Paginated<int> _page(List<int> items, int page, int totalPages) =>
    Paginated(items: items, page: page, limit: items.length, total: totalPages * items.length, totalPages: totalPages);

void main() {
  group('Scan', () {
    final running = Scan.fromJson({
      'id': 'scan_1',
      'domainId': 'domain_1',
      'status': 'RUNNING',
      'changeCount': 0,
      'steps': {
        'dns': {'status': 'completed'},
        'subdomains': {'status': 'running'},
      },
    });

    test('reads step status from detail objects and defaults to pending', () {
      expect(running.stepStatus('dns'), 'completed');
      expect(running.stepStatus('subdomains'), 'running');
      expect(running.stepStatus('ssl'), 'pending');
      expect(running.isActive, isTrue);
    });

    test('computes progress from steps when server sends none', () {
      // 1 of 7 steps finished.
      expect(running.progressPercent, 14);
    });

    test('mergeStatus applies polling payload and keeps domainId', () {
      final merged = running.mergeStatus({
        'id': 'scan_1',
        'status': 'COMPLETED',
        'progress': 100,
        'currentStep': null,
        'steps': {for (final s in scanSteps) s: 'completed'},
        'completedAt': '2026-10-07T10:00:00Z',
      });
      expect(merged.status, 'COMPLETED');
      expect(merged.isActive, isFalse);
      expect(merged.domainId, 'domain_1');
      expect(merged.progressPercent, 100);
      expect(merged.stepStatus('exposed_resources'), 'completed');
      expect(merged.completedAt, isNotNull);
    });
  });

  group('PagedController', () {
    tearDown(Get.reset);

    test('loads first page then appends next page', () async {
      final c = _TestPaged((page) async => page == 1 ? _page([1, 2], 1, 2) : _page([3, 4], 2, 2));
      await c.refreshList();
      expect(c.items, [1, 2]);
      expect(c.hasMore, isTrue);

      await c.loadMore();
      expect(c.items, [1, 2, 3, 4]);
      expect(c.hasMore, isFalse);

      await c.loadMore(); // No-op past the last page.
      expect(c.items, [1, 2, 3, 4]);
    });

    test('drops a stale response when a newer refresh started', () async {
      final slow = Completer<Paginated<int>>();
      var call = 0;
      final c = _TestPaged((page) {
        call++;
        return call == 1 ? slow.future : Future.value(_page([9], 1, 1));
      });

      final first = c.refreshList(); // e.g. old filter, still in flight
      await c.reload(); // new filter wins
      slow.complete(_page([1, 2, 3], 1, 1));
      await first;

      expect(c.items, [9]);
      expect(c.isLoading.value, isFalse);
    });

    test('shows error only when list is empty', () async {
      final c = _TestPaged((_) => Future.error('boom'));
      await c.refreshList();
      expect(c.error.value, 'boom');
      expect(c.isLoading.value, isFalse);
    });
  });
}
