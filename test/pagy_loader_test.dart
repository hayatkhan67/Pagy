import 'dart:async';

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

Response _pageResponse(List<int> ids, {int totalPages = 3}) {
  return Response(
    requestOptions: RequestOptions(path: '/items'),
    statusCode: 200,
    data: {
      'data': [
        for (final id in ids) {'id': id}
      ],
      'pagination': {'totalPages': totalPages},
    },
  );
}

PagyController<int> _controller(GetPaginatedDataUseCase useCase,
    {int limit = 2, int? firstPage}) {
  return PagyController<int>(
    endPoint: '/items',
    fromMap: (json) => json['id'] as int,
    limit: limit,
    firstPage: firstPage,
    responseParser: PagyParsers.dataWithPagination,
    useCase: useCase,
  );
}

void main() {
  group('failed refresh', () {
    test('keeps previously loaded items visible and in sync', () async {
      var shouldFail = false;

      final useCase = GetPaginatedDataUseCase(
        FakeRepo((params) async {
          if (shouldFail) {
            throw DioException(
              requestOptions: RequestOptions(path: '/items'),
              type: DioExceptionType.connectionError,
            );
          }
          return _pageResponse([1, 2]);
        }),
      );

      final controller = _controller(useCase);
      await controller.loadData();
      expect(controller.state.data, [1, 2]);

      shouldFail = true;
      await controller.refresh();

      expect(controller.state.error, isNotNull);
      expect(
        controller.state.data,
        [1, 2],
        reason: 'a failed refresh must not blank the visible list',
      );
      expect(
        controller.items,
        controller.state.data,
        reason: 'items and state.data must not diverge',
      );
      expect(controller.metadata.loadedItems, 2);
    });

    test('a later helper mutation does not collapse the list', () async {
      var shouldFail = false;

      final useCase = GetPaginatedDataUseCase(
        FakeRepo((params) async {
          if (shouldFail) {
            throw DioException(
              requestOptions: RequestOptions(path: '/items'),
              type: DioExceptionType.connectionError,
            );
          }
          return _pageResponse([1, 2]);
        }),
      );

      final controller = _controller(useCase);
      await controller.loadData();

      shouldFail = true;
      await controller.refresh();

      controller.add(3);
      expect(controller.state.data, [1, 2, 3]);
    });
  });

  group('load-more dedupe', () {
    test('a second load-more while one is in flight is ignored', () async {
      final requests = <PagyParams>[];
      final gate = Completer<void>();

      final useCase = GetPaginatedDataUseCase(
        FakeRepo((params) async {
          requests.add(params);
          if (params.page == 2) await gate.future;
          return _pageResponse([1, 2]);
        }),
      );

      final controller = _controller(useCase);
      await controller.loadData();
      expect(requests, hasLength(1));

      final first = controller.loadData(refresh: false);
      final second = controller.loadData(refresh: false);

      gate.complete();
      await Future.wait([first, second]);

      expect(
        requests.where((r) => r.page == 2),
        hasLength(1),
        reason: 'the duplicate notification must not fire a second request',
      );
      expect(controller.state.error, isNull);
      expect(controller.state.isMoreFetching, isFalse);
    });

    test('refresh is still allowed while a load-more is in flight', () async {
      final requests = <PagyParams>[];

      final useCase = GetPaginatedDataUseCase(
        FakeRepo((params) async {
          requests.add(params);
          return _pageResponse([1, 2]);
        }),
      );

      final controller = _controller(useCase);
      await controller.loadData();
      await controller.loadData(refresh: false);
      await controller.refresh();

      expect(requests.map((r) => r.page), [1, 2, 1]);
    });
  });

  group('error propagation through loadData', () {
    test('a DioException reaches errorBuilder as a typed PagyError', () async {
      final useCase = GetPaginatedDataUseCase(
        FakeRepo((params) async {
          throw DioException(
            requestOptions: RequestOptions(path: '/items'),
            response: Response(
              requestOptions: RequestOptions(path: '/items'),
              statusCode: 401,
            ),
            type: DioExceptionType.badResponse,
          );
        }),
      );

      final controller = _controller(useCase);
      await controller.loadData();

      final error = controller.state.error;
      expect(error, isNotNull);
      expect(error!.type, PagyErrorType.unauthorized);
      expect(error.statusCode, 401);
      expect(error.suggestion, isNotNull);
    });

    test('a PagyError thrown downstream is passed through untouched', () async {
      final useCase = GetPaginatedDataUseCase(
        FakeRepo((params) async {
          throw PagyError.serverError(message: 'boom', statusCode: 503);
        }),
      );

      final controller = _controller(useCase);
      await controller.loadData();

      expect(controller.state.error!.type, PagyErrorType.serverError);
      expect(controller.state.error!.statusCode, 503);
      expect(controller.state.error!.message, 'boom');
    });

    test('a cancelled PagyError is swallowed, not surfaced', () async {
      final useCase = GetPaginatedDataUseCase(
        FakeRepo((params) async {
          throw PagyError.cancelled();
        }),
      );

      final controller = _controller(useCase);
      await controller.loadData();

      expect(
        controller.state.error,
        isNull,
        reason:
            'cancellations are internal bookkeeping, not user-facing errors',
      );
    });
  });

  group('reset / fresh-state consistency', () {
    test('reset() matches a never-loaded controller', () async {
      final useCase = GetPaginatedDataUseCase(
        FakeRepo((params) async => _pageResponse([1, 2])),
      );

      final fresh = _controller(useCase);
      final loaded = _controller(useCase);

      await loaded.loadData();
      expect(loaded.state.currentPage, 1);

      loaded.reset();

      expect(loaded.state.currentPage, fresh.state.currentPage);
      expect(loaded.state.totalPages, fresh.state.totalPages);
      expect(loaded.state.data, isEmpty);
      expect(loaded.items, isEmpty);
    });

    test('a never-loaded controller is not on its last page', () {
      final useCase = GetPaginatedDataUseCase(
        FakeRepo((params) async => _pageResponse([1, 2])),
      );

      final controller = _controller(useCase);

      expect(controller.state.currentPage, 0);
      expect(controller.metadata.isLastPage, isFalse);
      expect(controller.metadata.hasMore, isTrue);
      expect(controller.metadata.rangeDescription, 'No items');
    });

    test('the first fetch after reset() loads page 1, not page 2', () async {
      final requests = <PagyParams>[];
      final useCase = GetPaginatedDataUseCase(
        FakeRepo((params) async {
          requests.add(params);
          return _pageResponse([1, 2]);
        }),
      );

      final controller = _controller(useCase);
      await controller.loadData();
      controller.reset();

      await controller.loadMore();

      expect(requests.map((r) => r.page), [1, 1]);
    });
  });

  group('firstPage', () {
    tearDown(() => PagyConfig().reset());

    GetPaginatedDataUseCase recording(List<PagyParams> requests) =>
        GetPaginatedDataUseCase(
          FakeRepo((params) async {
            requests.add(params);
            return _pageResponse([1, 2]);
          }),
        );

    test('defaults to 1-based requests', () async {
      final requests = <PagyParams>[];
      final controller = _controller(recording(requests));

      await controller.loadData();
      await controller.loadMore();

      expect(requests.map((r) => r.page), [1, 2]);
    });

    test('global firstPage: 0 sends zero-indexed pages', () async {
      PagyConfig()
          .initialize(baseUrl: 'https://api.example.com/', firstPage: 0);
      final requests = <PagyParams>[];
      final controller = _controller(recording(requests));

      await controller.loadData();
      await controller.loadMore();

      expect(requests.map((r) => r.page), [0, 1]);
      // State and metadata stay 1-based regardless of the backend.
      expect(controller.state.currentPage, 2);
      expect(controller.metadata.isFirstPage, isFalse);
    });

    test('controller firstPage overrides the global setting', () async {
      PagyConfig()
          .initialize(baseUrl: 'https://api.example.com/', firstPage: 0);
      final requests = <PagyParams>[];
      final controller = _controller(recording(requests), firstPage: 1);

      await controller.loadData();

      expect(requests.single.page, 1);
    });

    test('retry re-requests the same server page', () async {
      var fail = true;
      final requests = <PagyParams>[];
      final controller = _controller(
        GetPaginatedDataUseCase(
          FakeRepo((params) async {
            requests.add(params);
            if (fail) {
              throw DioException(
                requestOptions: RequestOptions(path: '/items'),
                type: DioExceptionType.connectionError,
              );
            }
            return _pageResponse([1, 2]);
          }),
        ),
        firstPage: 0,
      );

      await controller.loadData();
      fail = false;
      await controller.retry();

      expect(requests.map((r) => r.page), [0, 0]);
      expect(controller.state.currentPage, 1);
    });
  });
}
