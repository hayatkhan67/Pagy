import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'
    show MasonryGridView;
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
  testWidgets('refreshing over existing items keeps them on screen',
      (tester) async {
    final gate = Completer<void>();
    var call = 0;

    final controller = _controller((params) async {
      call++;
      if (call > 1) await gate.future;
      return _pageResponse([1, 2]);
    });

    await tester.pumpWidget(_wrap(
      PagyListView<int>(
        controller: controller,
        itemBuilderWithIndex: (context, item, i) => Text('item $item'),
      ),
    ));

    await controller.loadData();
    await tester.pump();
    expect(find.text('item 1'), findsOneWidget);

    // Start a refresh but don't let it complete.
    final refreshing = controller.refresh();
    await tester.pump();

    expect(controller.state.isFetching, isTrue);
    expect(
      find.text('item 1'),
      findsOneWidget,
      reason: 'the list must stay visible while refreshing',
    );

    gate.complete();
    await refreshing;
    await tester.pump();
    expect(find.text('item 1'), findsOneWidget);
  });

  testWidgets('a first load with no data still shows the loader',
      (tester) async {
    final gate = Completer<void>();

    final controller = _controller((params) async {
      await gate.future;
      return _pageResponse([1, 2]);
    });

    await tester.pumpWidget(_wrap(
      PagyListView<int>(
        controller: controller,
        itemBuilderWithIndex: (context, item, i) => Text('item $item'),
      ),
    ));

    final loading = controller.loadData();
    await tester.pump();

    expect(find.byType(DefaultPagyLoader), findsOneWidget);

    gate.complete();
    await loading;
    await tester.pump();
    expect(find.byType(DefaultPagyLoader), findsNothing);
  });

  testWidgets('PagyGridView renders its footer as a full-width sliver',
      (tester) async {
    final gate = Completer<void>();
    var call = 0;

    final controller = _controller((params) async {
      call++;
      if (call > 1) await gate.future;
      return _pageResponse([1, 2]);
    });

    await tester.pumpWidget(_wrap(
      PagyGridView<int>(
        controller: controller,
        crossAxisCount: 2,
        itemBuilderWithIndex: (context, item, i) => Text('item $item'),
      ),
    ));

    await controller.loadData();
    await tester.pump();

    // No footer yet — the grid holds exactly the data.
    expect(find.byType(SliverToBoxAdapter), findsNothing);

    // Trigger a load-more and hold it open so the footer is on screen.
    final loadingMore = controller.loadData(refresh: false);
    await tester.pump();

    expect(controller.state.isMoreFetching, isTrue);
    expect(
      find.byType(SliverToBoxAdapter),
      findsOneWidget,
      reason: 'the footer lives outside the masonry grid',
    );

    // The footer must be wider than a single column. With crossAxisCount: 2 an
    // item spans roughly half the viewport; the footer should span all of it.
    final itemWidth = tester.getRect(find.text('item 1')).width;
    final footerWidth = tester.getRect(find.byType(DefaultPagyLoader)).width;
    final viewportWidth = tester.getRect(find.byType(CustomScrollView)).width;

    expect(
      footerWidth,
      greaterThan(itemWidth * 1.5),
      reason: 'the footer must span all columns, not sit in one cell',
    );
    expect(
      footerWidth,
      greaterThan(viewportWidth * 0.9),
      reason: 'the footer spans the viewport, less its own padding',
    );

    gate.complete();
    await loadingMore;
    await tester.pump();
    expect(find.byType(SliverToBoxAdapter), findsNothing);
  });

  testWidgets('PagyGridView still renders items and reaches its footer slot',
      (tester) async {
    final controller =
        _controller((params) async => _pageResponse([1, 2, 3, 4]));

    await tester.pumpWidget(_wrap(
      PagyGridView<int>(
        controller: controller,
        crossAxisCount: 2,
        itemBuilderWithIndex: (context, item, i) => SizedBox(
          height: 40,
          child: Text('item $item'),
        ),
      ),
    ));

    await controller.loadData();
    await tester.pump();

    expect(find.text('item 1'), findsOneWidget);
    expect(find.text('item 4'), findsOneWidget);
  });

  group('PagyGridView shimmer', () {
    testWidgets('uses MasonryGridView, not the sliver data layout',
        (tester) async {
      final gate = Completer<void>();
      final controller = _controller((params) async {
        await gate.future;
        return _pageResponse([1, 2]);
      });

      await tester.pumpWidget(_wrap(
        PagyGridView<int>(
          controller: controller,
          shimmerEffect: true,
          placeholderItemModel: 0,
          placeholderItemCount: 4,
          itemBuilderWithIndex: (context, item, i) => SizedBox(
            height: 40,
            child: Text('item $item'),
          ),
        ),
      ));

      final loading = controller.loadData();
      await tester.pump();

      expect(controller.state.isFetching, isTrue);
      expect(find.byType(MasonryGridView), findsOneWidget);
      expect(find.byType(CustomScrollView), findsNothing);

      gate.complete();
      await loading;
      await tester.pump();

      // Once data arrives, the sliver layout takes over.
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('shimmer honours a custom gridDelegate', (tester) async {
      final gate = Completer<void>();
      final controller = _controller((params) async {
        await gate.future;
        return _pageResponse([1, 2]);
      });

      await tester.pumpWidget(_wrap(
        PagyGridView<int>(
          controller: controller,
          shimmerEffect: true,
          placeholderItemModel: 0,
          placeholderItemCount: 4,
          padding: EdgeInsets.zero,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
          gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          ),
          itemBuilderWithIndex: (context, item, i) => SizedBox(
            height: 40,
            child: Text('item $item'),
          ),
        ),
      ));

      final loading = controller.loadData();
      await tester.pump();

      final grid = tester.widget<MasonryGridView>(find.byType(MasonryGridView));
      expect(
        grid.gridDelegate,
        isA<SliverSimpleGridDelegateWithFixedCrossAxisCount>()
            .having((d) => d.crossAxisCount, 'crossAxisCount', 4),
      );

      gate.complete();
      await loading;
      await tester.pump();
    });
  });

  group('PagyGridView.gridDelegate', () {
    Future<void> pumpGrid(
      WidgetTester tester,
      PagyController<int> controller, {
      SliverSimpleGridDelegate? gridDelegate,
      int crossAxisCount = 2,
    }) async {
      await tester.pumpWidget(_wrap(
        PagyGridView<int>(
          controller: controller,
          crossAxisCount: crossAxisCount,
          gridDelegate: gridDelegate,
          padding: EdgeInsets.zero,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
          itemBuilderWithIndex: (context, item, i) => SizedBox(
            height: 40,
            child: Text('item $item'),
          ),
        ),
      ));
      await controller.loadData();
      await tester.pump();
    }

    testWidgets('defaults to crossAxisCount columns when omitted',
        (tester) async {
      final controller = _controller(
        (params) async => _pageResponse([1, 2, 3, 4]),
        limit: 4,
      );

      await pumpGrid(tester, controller, crossAxisCount: 2);

      // 800px viewport, no padding or spacing -> two 400px columns.
      expect(tester.getRect(find.text('item 1')).width, closeTo(400, 0.5));
    });

    testWidgets('honours a custom crossAxisCount delegate', (tester) async {
      final controller = _controller(
        (params) async => _pageResponse([1, 2, 3, 4]),
        limit: 4,
      );

      await pumpGrid(
        tester,
        controller,
        // crossAxisCount is ignored when a delegate is supplied.
        crossAxisCount: 2,
        gridDelegate:
            const SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
        ),
      );

      expect(tester.getRect(find.text('item 1')).width, closeTo(200, 0.5));
    });

    testWidgets('honours a max-cross-axis-extent delegate', (tester) async {
      final controller = _controller(
        (params) async => _pageResponse([1, 2, 3, 4]),
        limit: 4,
      );

      await pumpGrid(
        tester,
        controller,
        gridDelegate: const SliverSimpleGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
        ),
      );

      // 800 / 180 -> 5 columns of 160px.
      expect(tester.getRect(find.text('item 1')).width, closeTo(160, 0.5));
    });

    testWidgets('the footer still spans the full width under a delegate',
        (tester) async {
      final gate = Completer<void>();
      var call = 0;
      final controller = _controller((params) async {
        call++;
        if (call > 1) await gate.future;
        return _pageResponse([1, 2]);
      });

      await pumpGrid(
        tester,
        controller,
        gridDelegate: const SliverSimpleGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
        ),
      );

      final loadingMore = controller.loadData(refresh: false);
      await tester.pump();

      final itemWidth = tester.getRect(find.text('item 1')).width;
      final footerWidth = tester.getRect(find.byType(DefaultPagyLoader)).width;
      expect(footerWidth, greaterThan(itemWidth * 2));

      gate.complete();
      await loadingMore;
      await tester.pump();
    });
  });
}
