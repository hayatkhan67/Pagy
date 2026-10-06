import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagy/internal_imports.dart';
import 'package:pagy/pagy.dart';
import 'package:pagy/src/features/pagination/presentation/widgets/common/pagy_builder.dart';

/// `customShimmer` is ONE placeholder item; Pagy repeats it
/// `placeholderItemCount` times inside the view's own layout.

class FakeRepo implements PagyRepository {
  FakeRepo(this.handler);

  final Future<Response> Function(PagyParams params) handler;

  @override
  Future<Response> getPaginatedData<T>(PagyParams<T> params) => handler(params);
}

Response _page(List<int> ids, {int totalPages = 1}) => Response(
      requestOptions: RequestOptions(path: '/items'),
      statusCode: 200,
      data: {
        'data': [
          for (final id in ids) {'id': id}
        ],
        'pagination': {'totalPages': totalPages},
      },
    );

PagyController<int> _controller(
  Future<Response> Function(PagyParams params) handler,
) =>
    PagyController<int>(
      endPoint: '/items',
      fromMap: (json) => json['id'] as int,
      limit: 2,
      responseParser: PagyParsers.dataWithPagination,
      useCase: GetPaginatedDataUseCase(FakeRepo(handler)),
    );

/// The single placeholder item an app passes. Counts taps so tests can prove
/// the loading state is not interactive.
class _Skeleton extends StatelessWidget {
  const _Skeleton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: const SizedBox(width: 60, height: 40),
      );
}

List<Offset> _offsets(WidgetTester tester) => [
      for (var i = 0; i < find.byType(_Skeleton).evaluate().length; i++)
        tester.getTopLeft(find.byType(_Skeleton).at(i)),
    ];

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Starts a load that stays pending and pumps one frame of the loading state.
Future<(PagyController<int>, Completer<void>)> _loading(
  WidgetTester tester,
  Widget Function(PagyController<int> controller) view,
) async {
  final gate = Completer<void>();
  final controller = _controller((params) async {
    await gate.future;
    return _page([1, 2]);
  });
  await tester.pumpWidget(_wrap(view(controller)));
  unawaited(controller.loadData());
  await tester.pump();
  return (controller, gate);
}

Future<void> _finish(WidgetTester tester, Completer<void> gate) async {
  gate.complete();
  await tester.pump();
  await tester.pump();
}

void main() {
  tearDown(() => PagyConfig().reset());

  group('PagyListView', () {
    testWidgets('repeats the single customShimmer placeholderItemCount times',
        (tester) async {
      final (_, gate) = await _loading(
        tester,
        (c) => PagyListView<int>(
          controller: c,
          customShimmer: const _Skeleton(),
          placeholderItemCount: 3,
          itemBuilderWithIndex: (context, item, i) => Text('item $item'),
        ),
      );

      expect(find.byType(_Skeleton), findsNWidgets(3));
      await _finish(tester, gate);
      expect(find.byType(_Skeleton), findsNothing);
      expect(find.text('item 1'), findsOneWidget);
    });

    testWidgets('uses the list spacing between the placeholders',
        (tester) async {
      final (_, gate) = await _loading(
        tester,
        (c) => PagyListView<int>(
          controller: c,
          customShimmer: const _Skeleton(),
          placeholderItemCount: 3,
          itemSpacing: 10,
          itemBuilderWithIndex: (context, item, i) => Text('item $item'),
        ),
      );

      final tops = _offsets(tester).map((o) => o.dy).toList();
      // 40px item + 10px spacing.
      expect(tops[1] - tops[0], 50);
      expect(tops[2] - tops[1], 50);
      await _finish(tester, gate);
    });

    testWidgets('uses the list padding', (tester) async {
      final (_, gate) = await _loading(
        tester,
        (c) => PagyListView<int>(
          controller: c,
          customShimmer: const _Skeleton(),
          placeholderItemCount: 2,
          padding: const EdgeInsets.only(left: 24, top: 8),
          itemBuilderWithIndex: (context, item, i) => Text('item $item'),
        ),
      );

      final first = tester.getTopLeft(find.byType(_Skeleton).first);
      expect(first.dx, 24);
      await _finish(tester, gate);
    });

    testWidgets('the loading state is not interactive', (tester) async {
      var taps = 0;
      final (_, gate) = await _loading(
        tester,
        (c) => PagyListView<int>(
          controller: c,
          customShimmer: _Skeleton(onTap: () => taps++),
          placeholderItemCount: 2,
          itemBuilderWithIndex: (context, item, i) => Text('item $item'),
        ),
      );

      await tester.tap(find.byType(_Skeleton).first);
      expect(taps, 0);
      await _finish(tester, gate);
    });

    testWidgets('customShimmer wins over shimmerBuilder', (tester) async {
      final (_, gate) = await _loading(
        tester,
        (c) => PagyListView<int>(
          controller: c,
          customShimmer: const _Skeleton(),
          shimmerBuilder: (context) => const Text('whole placeholder'),
          placeholderItemCount: 2,
          itemBuilderWithIndex: (context, item, i) => Text('item $item'),
        ),
      );

      expect(find.byType(_Skeleton), findsNWidgets(2));
      expect(find.text('whole placeholder'), findsNothing);
      await _finish(tester, gate);
    });

    testWidgets('shimmerBuilder still builds the whole placeholder',
        (tester) async {
      final (_, gate) = await _loading(
        tester,
        (c) => PagyListView<int>(
          controller: c,
          shimmerBuilder: (context) => const Text('whole placeholder'),
          placeholderItemCount: 3,
          itemBuilderWithIndex: (context, item, i) => Text('item $item'),
        ),
      );

      expect(find.text('whole placeholder'), findsOneWidget);
      await _finish(tester, gate);
    });

    testWidgets('the same single item is the next-page footer', (tester) async {
      final gate = Completer<void>();
      var calls = 0;
      final controller = _controller((params) async {
        calls++;
        if (calls == 2) await gate.future; // hold the second page
        return _page([calls * 10 + 1, calls * 10 + 2], totalPages: 2);
      });

      await tester.pumpWidget(_wrap(
        PagyListView<int>(
          controller: controller,
          customShimmer: const _Skeleton(),
          placeholderItemCount: 5,
          itemBuilderWithIndex: (context, item, i) => Text('item $item'),
        ),
      ));
      await controller.loadData();
      await tester.pump();
      expect(find.byType(_Skeleton), findsNothing);

      unawaited(controller.loadMore());
      await tester.pump();

      // One footer placeholder, not placeholderItemCount of them.
      expect(find.byType(_Skeleton), findsOneWidget);
      expect(find.text('item 11'), findsOneWidget);
      await _finish(tester, gate);
      expect(find.byType(_Skeleton), findsNothing);
    });
  });

  group('PagyHorizontalListView', () {
    testWidgets('repeats the placeholder along the scroll axis',
        (tester) async {
      final (_, gate) = await _loading(
        tester,
        (c) => SizedBox(
          height: 100,
          child: PagyHorizontalListView<int>(
            controller: c,
            customShimmer: const _Skeleton(),
            placeholderItemCount: 3,
            itemSpacing: 8,
            itemBuilderWithIndex: (context, item, i) => Text('item $item'),
          ),
        ),
      );

      expect(find.byType(_Skeleton), findsNWidgets(3));
      final lefts = _offsets(tester).map((o) => o.dx).toList();
      // 60px item + 8px spacing.
      expect(lefts[1] - lefts[0], 68);
      expect(lefts[2] - lefts[1], 68);
      await _finish(tester, gate);
    });
  });

  group('PagyGridView', () {
    testWidgets('repeats the placeholder in the grid', (tester) async {
      final (_, gate) = await _loading(
        tester,
        (c) => PagyGridView<int>(
          controller: c,
          crossAxisCount: 2,
          customShimmer: const _Skeleton(),
          placeholderItemCount: 4,
          itemBuilderWithIndex: (context, item, i) => Text('item $item'),
        ),
      );

      expect(find.byType(_Skeleton), findsNWidgets(4));
      // Two columns: items 0 and 1 share a row.
      final dys = _offsets(tester).map((o) => o.dy).toList();
      expect(dys[0], dys[1]);
      expect(dys[2], greaterThan(dys[0]));
      await _finish(tester, gate);
    });
  });

  group('PagyBuilder (standalone)', () {
    testWidgets('repeats customShimmer through its own layoutBuilder',
        (tester) async {
      final gate = Completer<void>();
      final controller = _controller((params) async {
        await gate.future;
        return _page([1, 2]);
      });

      await tester.pumpWidget(_wrap(
        PagyBuilder<int>(
          controller: controller,
          customShimmer: const _Skeleton(),
          placeholderItemCount: 3,
          itemBuilder: (context, item, i) => Text('item $item'),
          layoutBuilder: (ctx, state, count, itemBuilder, footer) =>
              ListView.builder(itemCount: count, itemBuilder: itemBuilder),
        ),
      ));
      unawaited(controller.loadData());
      await tester.pump();

      expect(find.byType(_Skeleton), findsNWidgets(3));
      await _finish(tester, gate);
      expect(find.text('item 1'), findsOneWidget);
    });
  });

  group('search shows the loading state', () {
    testWidgets('a new search drops the old rows and shows the placeholders',
        (tester) async {
      final searchGate = Completer<void>();
      final controller = _controller((params) async {
        if (params.queryParameter != null) await searchGate.future;
        return _page(params.queryParameter == null ? [1, 2] : [9]);
      });

      await tester.pumpWidget(_wrap(
        PagyListView<int>(
          controller: controller,
          customShimmer: const _Skeleton(),
          placeholderItemCount: 3,
          itemBuilderWithIndex: (context, item, i) => Text('item $item'),
        ),
      ));
      await controller.loadData();
      await tester.pump();
      expect(find.text('item 1'), findsOneWidget);

      unawaited(controller.search('x'));
      await tester.pump();
      // Old rows gone, three placeholders shown.
      expect(find.text('item 1'), findsNothing);
      expect(find.byType(_Skeleton), findsNWidgets(3));

      await _finish(tester, searchGate);
      expect(find.byType(_Skeleton), findsNothing);
      expect(find.text('item 9'), findsOneWidget);
    });
  });
}
