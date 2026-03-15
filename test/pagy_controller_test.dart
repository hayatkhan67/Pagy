import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagy/internal_imports.dart';
import 'package:pagy/pagy.dart';

class FakeRepo implements PagyRepository {
  FakeRepo(this.handler);

  final Future<Response> Function(PagyParams params) handler;

  @override
  Future<Response> getPaginatedData<T>(PagyParams<T> params) => handler(params);
}

Response _okResponse(
    {int totalPages = 2, List<Map<String, dynamic>> data = const []}) {
  return Response(
    requestOptions: RequestOptions(path: '/test'),
    statusCode: 200,
    data: {
      'data': data,
      'pagination': {'totalPages': totalPages},
    },
  );
}

Response _listOnlyResponse(List<Map<String, dynamic>> data) {
  return Response(
    requestOptions: RequestOptions(path: '/test'),
    statusCode: 200,
    data: {'data': data},
  );
}

void main() {
  group('PagyController', () {
    test('persists filters across loadMore', () async {
      final requests = <PagyParams>[];

      final useCase = GetPaginatedDataUseCase(
        FakeRepo((params) async {
          requests.add(params);
          return _okResponse();
        }),
      );

      final controller = PagyController<int>(
        endPoint: '/items',
        fromMap: (json) => json['id'] as int,
        responseParser: PagyParsers.dataWithPagination,
        useCase: useCase,
      );

      await controller.loadData(queryParameter: {'q': 'books'});
      await controller.loadMore();

      expect(requests, hasLength(2));
      expect(requests[1].queryParameter, {'q': 'books'});
    });

    test('preserves filters on refresh when configured', () async {
      final requests = <PagyParams>[];

      final useCase = GetPaginatedDataUseCase(
        FakeRepo((params) async {
          requests.add(params);
          return _okResponse();
        }),
      );

      final controller = PagyController<int>(
        endPoint: '/items',
        fromMap: (json) => json['id'] as int,
        responseParser: PagyParsers.dataWithPagination,
        useCase: useCase,
      );

      await controller.loadData(queryParameter: {'q': 'books'});
      await controller.loadData(
        refresh: true,
        preserveFiltersOnRefresh: true,
      );

      expect(requests, hasLength(2));
      expect(requests[1].queryParameter, {'q': 'books'});
    });

    test('uses controller payloadData when not provided', () async {
      PagyParams? captured;

      final useCase = GetPaginatedDataUseCase(
        FakeRepo((params) async {
          captured = params;
          return _okResponse();
        }),
      );

      final controller = PagyController<int>(
        endPoint: '/items',
        fromMap: (json) => json['id'] as int,
        responseParser: PagyParsers.dataWithPagination,
        payloadData: {'static': true},
        useCase: useCase,
      );

      await controller.loadData();

      expect(captured, isNotNull);
      expect(captured!.payloadData, {'static': true});
    });

    test('retry reuses the last request page', () async {
      final requests = <PagyParams>[];
      var shouldFail = true;

      final useCase = GetPaginatedDataUseCase(
        FakeRepo((params) async {
          requests.add(params);
          if (shouldFail) {
            shouldFail = false;
            throw Exception('boom');
          }
          return _okResponse();
        }),
      );

      final controller = PagyController<int>(
        endPoint: '/items',
        fromMap: (json) => json['id'] as int,
        responseParser: PagyParsers.dataWithPagination,
        useCase: useCase,
      );

      await controller.loadData();
      await controller.retry();

      expect(requests, hasLength(2));
      expect(requests[0].page, 1);
      expect(requests[1].page, 1);
    });

    test('assumes more pages when totalPages is missing (opt-in)', () async {
      final requests = <PagyParams>[];
      final config = PagyConfig();
      final previous =
          config.assumeHasMoreWhenTotalPagesNull;
      config.assumeHasMoreWhenTotalPagesNull = true;
      addTearDown(() {
        config.assumeHasMoreWhenTotalPagesNull = previous;
      });

      final useCase = GetPaginatedDataUseCase(
        FakeRepo((params) async {
          requests.add(params);
          if (params.page == 1) {
            return _listOnlyResponse([
              {'id': 1}
            ]);
          }
          return _listOnlyResponse(const []);
        }),
      );

      final controller = PagyController<int>(
        endPoint: '/items',
        fromMap: (json) => json['id'] as int,
        responseParser: (response) => PagyResponseParser(
          list: response['data'] ?? [],
          totalPages: null,
        ),
        useCase: useCase,
      );

      await controller.loadData();
      expect(controller.state.totalPages, 2);

      await controller.loadMore();
      expect(controller.state.currentPage, 2);
      expect(controller.state.totalPages, 2);
      expect(requests, hasLength(2));
    });

    test('retry should preserve filters from the last failed request', () async {
      final List<PagyParams> requests = [];
      bool shouldFail = true;

      final controller = PagyController<int>(
        endPoint: '/test',
        fromMap: (json) => json['id'] as int,
        responseParser: (res) => PagyResponseParser(
          list: res['data'],
          totalPages: null,
        ),
        useCase: GetPaginatedDataUseCase(FakeRepo((params) async {
          requests.add(params);
          if (shouldFail) {
            throw DioException(requestOptions: RequestOptions(path: '/'));
          }
          return _listOnlyResponse([
            {'id': 1}
          ]);
        })),
      );

      // 1. Initial filtered load that fails
      await controller.loadData(queryParameter: {'search': 'test'});
      expect(controller.state.error, isNotNull);
      expect(requests.last.queryParameter, containsPair('search', 'test'));

      // 2. Retry
      shouldFail = false;
      await controller.retry();

      expect(controller.state.error, isNull);
      expect(requests.last.queryParameter, containsPair('search', 'test'));
      expect(requests, hasLength(2));
    });

    test('refresh with preserveFilters: true should keep current filters', () async {
      final List<PagyParams> requests = [];
      final controller = PagyController<int>(
        endPoint: '/test',
        fromMap: (json) => json['id'] as int,
        responseParser: (res) => PagyResponseParser(
          list: res['data'],
          totalPages: null,
        ),
        useCase: GetPaginatedDataUseCase(FakeRepo((params) async {
          requests.add(params);
          return _listOnlyResponse([
            {'id': 1}
          ]);
        })),
      );

      // 1. Load with filters
      await controller.loadData(queryParameter: {'category': 'tech'});
      expect(requests.last.queryParameter, containsPair('category', 'tech'));

      // 2. Refresh with preservation
      await controller.refresh(preserveFilters: true);
      expect(requests.last.queryParameter, containsPair('category', 'tech'));
    });

    test('refresh should clear filters by default', () async {
      final List<PagyParams> requests = [];
      final controller = PagyController<int>(
        endPoint: '/test',
        fromMap: (json) => json['id'] as int,
        responseParser: (res) => PagyResponseParser(
          list: res['data'],
          totalPages: null,
        ),
        useCase: GetPaginatedDataUseCase(FakeRepo((params) async {
          requests.add(params);
          return _listOnlyResponse([
            {'id': 1}
          ]);
        })),
      );

      // 1. Load with filters
      await controller.loadData(queryParameter: {'category': 'tech'});
      expect(requests.last.queryParameter, containsPair('category', 'tech'));

      // 2. Default refresh
      await controller.refresh();
      expect(requests.last.queryParameter, isNot(contains('category')));
    });
  });
}

