import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pagy/pagy.dart';

class FakePageRepository implements PagyPageRepository {
  FakePageRepository(this.handler);

  final Future<PagyPage<dynamic>> Function(PagyPageParams<dynamic> params)
      handler;

  @override
  Future<PagyPage<T>> getPage<T>(PagyPageParams<T> params) async {
    final page = await handler(params as PagyPageParams<dynamic>);
    return PagyPage<T>(
      items: page.items.cast<T>(),
      totalPages: page.totalPages,
      totalItems: page.totalItems,
      hasMore: page.hasMore,
    );
  }
}

void main() {
  group('PagyController (page use case)', () {
    test('uses page use case to populate items and totalPages', () async {
      final repo = FakePageRepository((params) async {
        return PagyPage<int>(
          items: [1, 2, 3],
          totalPages: 5,
        );
      });

      final useCase = GetPaginatedPageUseCase(repo);

      final controller = PagyController<int>(
        endPoint: '/items',
        fromMap: (json) => json['id'] as int,
        responseParser: PagyParsers.dataWithPagination,
        pageUseCase: useCase,
      );

      await controller.loadData();

      expect(controller.items, [1, 2, 3]);
      expect(controller.state.totalPages, 5);
    });
  });

  group('a new query drops the old results while it loads', () {
    late Completer<void> gate;
    late PagyController<int> controller;
    final queries = <Map<String, dynamic>?>[];

    setUp(() async {
      queries.clear();
      gate = Completer<void>()..complete(); // first load goes straight through
      final repo = FakePageRepository((params) async {
        queries.add(params.queryParameter);
        await gate.future;
        final q = params.queryParameter?['q'];
        return PagyPage<int>(items: q == null ? [1, 2, 3] : [9], totalPages: 1);
      });
      controller = PagyController<int>(
        endPoint: '/items',
        fromMap: (json) => json['id'] as int,
        responseParser: PagyParsers.dataWithPagination,
        pageUseCase: GetPaginatedPageUseCase(repo),
      );
      await controller.loadData();
      gate = Completer<void>(); // later requests wait until released
    });

    test('search clears the list so the loader / shimmer can show', () async {
      final pending = controller.search('x');
      expect(controller.state.isFetching, isTrue);
      expect(controller.state.data, isEmpty);
      expect(controller.items, isEmpty);
      gate.complete();
      await pending;
      expect(controller.items, [9]);
      expect(queries.last, {'q': 'x'});
    });

    test('clearFilters clears the list too, then reloads without a query',
        () async {
      gate.complete();
      await controller.search('x');
      gate = Completer<void>();
      final pending = controller.clearFilters();
      expect(controller.state.isFetching, isTrue);
      expect(controller.state.data, isEmpty);
      gate.complete();
      await pending;
      expect(controller.items, [1, 2, 3]);
    });

    test('applyFilters clears the list while loading', () async {
      final pending = controller.applyFilters({'q': 'y'});
      expect(controller.state.data, isEmpty);
      gate.complete();
      await pending;
      expect(controller.items, [9]);
    });

    test('refresh keeps the items on screen (the query did not change)',
        () async {
      final pending = controller.refresh();
      expect(controller.state.isFetching, isTrue);
      expect(controller.state.data, [1, 2, 3]);
      gate.complete();
      await pending;
      expect(controller.items, [1, 2, 3]);
    });
  });
}
