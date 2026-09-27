import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagy/internal_imports.dart';
import 'package:pagy/pagy.dart';
import 'package:pagy/src/features/pagination/presentation/widgets/common/pagy_builder.dart';

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

PagyController<int> _controller(
  Future<Response> Function(PagyParams params) handler, {
  int limit = 2,
}) {
  return PagyController<int>(
    endPoint: '/items',
    fromMap: (json) => json['id'] as int,
    limit: limit,
    responseParser: PagyParsers.dataWithPagination,
    useCase: GetPaginatedDataUseCase(FakeRepo(handler)),
  );
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  tearDown(() {
    PagyConfig().reset();
  });

  group('PagyListView custom shimmer', () {
    testWidgets('renders customShimmer widget during initial loading',
        (tester) async {
      final gate = Completer<void>();
      final controller = _controller((params) async {
        await gate.future;
        return _pageResponse([1, 2]);
      });

      await tester.pumpWidget(_wrap(
        PagyListView<int>(
          controller: controller,
          customShimmer: const KeyedSubtree(
            key: Key('custom-list-shimmer'),
            child: Text('Custom List Shimmer'),
          ),
          itemBuilderWithIndex: (context, item, i) => Text('item $item'),
        ),
      ));

      final loading = controller.loadData();
      await tester.pump();

      expect(find.byKey(const Key('custom-list-shimmer')), findsOneWidget);
      expect(find.text('Custom List Shimmer'), findsOneWidget);

      gate.complete();
      await loading;
      await tester.pump();

      expect(find.byKey(const Key('custom-list-shimmer')), findsNothing);
      expect(find.text('item 1'), findsOneWidget);
    });

    testWidgets('renders shimmerBuilder during initial loading',
        (tester) async {
      final gate = Completer<void>();
      final controller = _controller((params) async {
        await gate.future;
        return _pageResponse([1, 2]);
      });

      await tester.pumpWidget(_wrap(
        PagyListView<int>(
          controller: controller,
          shimmerBuilder: (context) => const Text('Builder Shimmer'),
          itemBuilderWithIndex: (context, item, i) => Text('item $item'),
        ),
      ));

      final loading = controller.loadData();
      await tester.pump();

      expect(find.text('Builder Shimmer'), findsOneWidget);

      gate.complete();
      await loading;
      await tester.pump();

      expect(find.text('Builder Shimmer'), findsNothing);
      expect(find.text('item 1'), findsOneWidget);
    });
  });

  group('PagyGridView custom shimmer', () {
    testWidgets('renders customShimmer widget during initial loading',
        (tester) async {
      final gate = Completer<void>();
      final controller = _controller((params) async {
        await gate.future;
        return _pageResponse([1, 2]);
      });

      await tester.pumpWidget(_wrap(
        PagyGridView<int>(
          controller: controller,
          customShimmer: const KeyedSubtree(
            key: Key('custom-grid-shimmer'),
            child: Text('Custom Grid Shimmer'),
          ),
          itemBuilderWithIndex: (context, item, i) => Text('item $item'),
        ),
      ));

      final loading = controller.loadData();
      await tester.pump();

      expect(find.byKey(const Key('custom-grid-shimmer')), findsOneWidget);
      expect(find.text('Custom Grid Shimmer'), findsOneWidget);

      gate.complete();
      await loading;
      await tester.pump();

      expect(find.byKey(const Key('custom-grid-shimmer')), findsNothing);
      expect(find.text('item 1'), findsOneWidget);
    });

    testWidgets('renders shimmerBuilder during initial loading',
        (tester) async {
      final gate = Completer<void>();
      final controller = _controller((params) async {
        await gate.future;
        return _pageResponse([1, 2]);
      });

      await tester.pumpWidget(_wrap(
        PagyGridView<int>(
          controller: controller,
          shimmerBuilder: (context) => const Text('Grid Shimmer Builder'),
          itemBuilderWithIndex: (context, item, i) => Text('item $item'),
        ),
      ));

      final loading = controller.loadData();
      await tester.pump();

      expect(find.text('Grid Shimmer Builder'), findsOneWidget);

      gate.complete();
      await loading;
      await tester.pump();

      expect(find.text('Grid Shimmer Builder'), findsNothing);
      expect(find.text('item 1'), findsOneWidget);
    });
  });

  group('PagyHorizontalListView custom shimmer', () {
    testWidgets('renders customShimmer widget during initial loading',
        (tester) async {
      final gate = Completer<void>();
      final controller = _controller((params) async {
        await gate.future;
        return _pageResponse([1, 2]);
      });

      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 100,
          child: PagyHorizontalListView<int>(
            controller: controller,
            customShimmer: const Text('Custom Horizontal Shimmer'),
            itemBuilderWithIndex: (context, item, i) => Text('item $item'),
          ),
        ),
      ));

      final loading = controller.loadData();
      await tester.pump();

      expect(find.text('Custom Horizontal Shimmer'), findsOneWidget);

      gate.complete();
      await loading;
      await tester.pump();

      expect(find.text('Custom Horizontal Shimmer'), findsNothing);
      expect(find.text('item 1'), findsOneWidget);
    });
  });

  group('PagyConfig global shimmer', () {
    testWidgets('renders PagyConfig global shimmer via customShimmer parameter',
        (tester) async {
      PagyConfig().initialize(
        baseUrl: 'https://api.example.com/',
        customShimmer: const Text('Global Custom Shimmer'),
      );

      final gate = Completer<void>();
      final controller = _controller((params) async {
        await gate.future;
        return _pageResponse([1, 2]);
      });

      await tester.pumpWidget(_wrap(
        PagyListView<int>(
          controller: controller,
          customShimmer: PagyConfig().globalShimmer,
          itemBuilderWithIndex: (context, item, i) => Text('item $item'),
        ),
      ));

      final loading = controller.loadData();
      await tester.pump();

      expect(find.text('Global Custom Shimmer'), findsOneWidget);

      gate.complete();
      await loading;
      await tester.pump();

      expect(find.text('Global Custom Shimmer'), findsNothing);
      expect(find.text('item 1'), findsOneWidget);
    });

    testWidgets('local customShimmer overrides PagyConfig global shimmer',
        (tester) async {
      PagyConfig().initialize(
        baseUrl: 'https://api.example.com/',
        customShimmer: const Text('Global Custom Shimmer'),
      );

      final gate = Completer<void>();
      final controller = _controller((params) async {
        await gate.future;
        return _pageResponse([1, 2]);
      });

      await tester.pumpWidget(_wrap(
        PagyListView<int>(
          controller: controller,
          customShimmer: const Text('Local Shimmer Override'),
          itemBuilderWithIndex: (context, item, i) => Text('item $item'),
        ),
      ));

      final loading = controller.loadData();
      await tester.pump();

      expect(find.text('Local Shimmer Override'), findsOneWidget);
      expect(find.text('Global Custom Shimmer'), findsNothing);

      gate.complete();
      await loading;
      await tester.pump();

      expect(find.text('Local Shimmer Override'), findsNothing);
      expect(find.text('item 1'), findsOneWidget);
    });
  });
}
