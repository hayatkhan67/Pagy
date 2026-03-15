import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagy/pagy.dart';

/// Simple test model
class TestItem {
  final int id;
  final String name;

  TestItem({required this.id, required this.name});

  factory TestItem.fromJson(Map<String, dynamic> json) {
    return TestItem(id: json['id'], name: json['name']);
  }

  TestItem.empty()
      : id = 0,
        name = '';
}

/// Test helper to create a controller with pre-loaded data
PagyController<TestItem> createTestController({List<TestItem>? items}) {
  final controller = PagyController<TestItem>(
    endPoint: 'test',
    requestType: PagyApiRequestType.get,
    fromMap: TestItem.fromJson,
    responseParser: (response) => PagyResponseParser(
      list: response['data'] ?? [],
      totalPages: response['totalPages'] ?? 1,
    ),
  );

  // Add items directly to the internal list and update state
  if (items != null && items.isNotEmpty) {
    controller.itemsList.addAll(items);
    controller.controller.value = PagyState<TestItem>(
      data: items,
      isFetching: false,
      isMoreFetching: false,
      currentPage: 1,
      totalPages: 1,
    );
  }

  return controller;
}

void main() {
  setUpAll(() {
    // Initialize PagyConfig for testing
    PagyConfig().initialize(
      baseUrl: 'https://test.example.com/',
      pageKey: 'page',
      limitKey: 'limit',
      enableLogs: false,
    );
  });

  group('PagyHorizontalListView', () {
    group('Dynamic Height Feature', () {
      testWidgets('renders without error in unbounded height context',
          (WidgetTester tester) async {
        final controller = createTestController(items: [
          TestItem(id: 1, name: 'Item 1'),
          TestItem(id: 2, name: 'Item 2'),
          TestItem(id: 3, name: 'Item 3'),
        ]);

        // Place in Column (unbounded height context)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const Text('Header'),
                  PagyHorizontalListView<TestItem>(
                    controller: controller,
                    itemSpacing: 10,
                    itemBuilderWithIndex: (context, item, index) {
                      return Container(
                        width: 100,
                        height: 80,
                        color: Colors.blue,
                        child: Text(item.name),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render without error
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 2'), findsOneWidget);
        expect(find.text('Item 3'), findsOneWidget);

        controller.controller.dispose();
      });

      testWidgets('uses ListView when wrapped in SizedBox with fixed height',
          (WidgetTester tester) async {
        final controller = createTestController(items: [
          TestItem(id: 1, name: 'Fixed 1'),
          TestItem(id: 2, name: 'Fixed 2'),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 200,
                child: PagyHorizontalListView<TestItem>(
                  controller: controller,
                  itemSpacing: 10,
                  itemBuilderWithIndex: (context, item, index) {
                    return Container(
                      width: 100,
                      height: 80,
                      child: Text(item.name),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render items
        expect(find.text('Fixed 1'), findsOneWidget);
        expect(find.text('Fixed 2'), findsOneWidget);

        // Should find ListView (bounded context uses ListView)
        expect(find.byType(ListView), findsOneWidget);

        controller.controller.dispose();
      });

      testWidgets('useDynamicHeight true forces Row-based layout',
          (WidgetTester tester) async {
        final controller = createTestController(items: [
          TestItem(id: 1, name: 'Dynamic 1'),
          TestItem(id: 2, name: 'Dynamic 2'),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 200, // Even with fixed height
                child: PagyHorizontalListView<TestItem>(
                  controller: controller,
                  useDynamicHeight: true, // Force dynamic height
                  itemSpacing: 10,
                  itemBuilderWithIndex: (context, item, index) {
                    return Container(
                      width: 100,
                      height: 80,
                      child: Text(item.name),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render items
        expect(find.text('Dynamic 1'), findsOneWidget);
        expect(find.text('Dynamic 2'), findsOneWidget);

        // Should use SingleChildScrollView (not ListView)
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.byType(ListView), findsNothing);

        controller.controller.dispose();
      });

      testWidgets(
          'auto-fallback uses SingleChildScrollView in unbounded context',
          (WidgetTester tester) async {
        final controller = createTestController(items: [
          TestItem(id: 1, name: 'Auto 1'),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  PagyHorizontalListView<TestItem>(
                    controller: controller,
                    // useDynamicHeight is false by default
                    itemBuilderWithIndex: (context, item, index) {
                      return Container(
                        width: 100,
                        height: 80,
                        child: Text(item.name),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should auto-fallback to SingleChildScrollView
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.text('Auto 1'), findsOneWidget);

        controller.controller.dispose();
      });

      testWidgets('itemSpacing is applied correctly in dynamic height mode',
          (WidgetTester tester) async {
        final controller = createTestController(items: [
          TestItem(id: 1, name: 'Spaced 1'),
          TestItem(id: 2, name: 'Spaced 2'),
          TestItem(id: 3, name: 'Spaced 3'),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  PagyHorizontalListView<TestItem>(
                    controller: controller,
                    useDynamicHeight: true,
                    itemSpacing: 20,
                    itemBuilderWithIndex: (context, item, index) {
                      return Container(
                        key: Key('item_$index'),
                        width: 100,
                        height: 80,
                        child: Text(item.name),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // All items should be rendered
        expect(find.text('Spaced 1'), findsOneWidget);
        expect(find.text('Spaced 2'), findsOneWidget);
        expect(find.text('Spaced 3'), findsOneWidget);

        // Verify SizedBox spacers exist (itemSpacing: 20)
        // There should be 2 spacers between 3 items
        final spacers = find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.width == 20,
        );
        expect(spacers, findsNWidgets(2));

        controller.controller.dispose();
      });

      testWidgets('custom separatorBuilder works in dynamic height mode',
          (WidgetTester tester) async {
        final controller = createTestController(items: [
          TestItem(id: 1, name: 'Sep 1'),
          TestItem(id: 2, name: 'Sep 2'),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  PagyHorizontalListView<TestItem>(
                    controller: controller,
                    useDynamicHeight: true,
                    separatorBuilder: (context, index) => Container(
                      key: const Key('custom_separator'),
                      width: 5,
                      height: 50,
                      color: Colors.red,
                    ),
                    itemBuilderWithIndex: (context, item, index) {
                      return Container(
                        width: 100,
                        height: 80,
                        child: Text(item.name),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Custom separator should be present
        expect(find.byKey(const Key('custom_separator')), findsOneWidget);

        controller.controller.dispose();
      });

      testWidgets('padding is applied in dynamic height mode',
          (WidgetTester tester) async {
        final controller = createTestController(items: [
          TestItem(id: 1, name: 'Padded 1'),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  PagyHorizontalListView<TestItem>(
                    controller: controller,
                    useDynamicHeight: true,
                    padding: const EdgeInsets.all(16),
                    itemBuilderWithIndex: (context, item, index) {
                      return Container(
                        width: 100,
                        height: 80,
                        child: Text(item.name),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should find Padding widget with our specified padding
        final paddingFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Padding && widget.padding == const EdgeInsets.all(16),
        );
        expect(paddingFinder, findsOneWidget);

        controller.controller.dispose();
      });

      testWidgets('disableScrolling works in dynamic height mode',
          (WidgetTester tester) async {
        final controller = createTestController(items: [
          TestItem(id: 1, name: 'No Scroll'),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  PagyHorizontalListView<TestItem>(
                    controller: controller,
                    useDynamicHeight: true,
                    disableScrolling: true,
                    itemBuilderWithIndex: (context, item, index) {
                      return Container(
                        width: 100,
                        height: 80,
                        child: Text(item.name),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should NOT have SingleChildScrollView when scrolling is disabled
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(find.text('No Scroll'), findsOneWidget);

        controller.controller.dispose();
      });

      testWidgets('index is correctly passed to itemBuilderWithIndex',
          (WidgetTester tester) async {
        final controller = createTestController(items: [
          TestItem(id: 1, name: 'A'),
          TestItem(id: 2, name: 'B'),
          TestItem(id: 3, name: 'C'),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  PagyHorizontalListView<TestItem>(
                    controller: controller,
                    useDynamicHeight: true,
                    itemBuilderWithIndex: (context, item, index) {
                      return Container(
                        key: Key('item_$index'),
                        width: 100,
                        height: 80,
                        child: Text('${item.name}-$index'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify index is correctly passed
        expect(find.text('A-0'), findsOneWidget);
        expect(find.text('B-1'), findsOneWidget);
        expect(find.text('C-2'), findsOneWidget);

        controller.controller.dispose();
      });
    });

    group('Scroll Direction', () {
      testWidgets('scrollDirection is Axis.horizontal',
          (WidgetTester tester) async {
        final controller = createTestController(items: [
          TestItem(id: 1, name: 'Test'),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 200,
                child: PagyHorizontalListView<TestItem>(
                  controller: controller,
                  itemBuilderWithIndex: (context, item, index) {
                    return Container(width: 100, child: Text(item.name));
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find ListView and verify scroll direction
        final listView = tester.widget<ListView>(find.byType(ListView));
        expect(listView.scrollDirection, Axis.horizontal);

        controller.controller.dispose();
      });
    });

    group('Edge Cases', () {
      testWidgets('handles single item correctly in dynamic height',
          (WidgetTester tester) async {
        final controller = createTestController(items: [
          TestItem(id: 1, name: 'Single'),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  PagyHorizontalListView<TestItem>(
                    controller: controller,
                    useDynamicHeight: true,
                    itemSpacing: 10,
                    itemBuilderWithIndex: (context, item, index) {
                      return Container(
                        width: 100,
                        height: 80,
                        child: Text(item.name),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Single item should render without separators
        expect(find.text('Single'), findsOneWidget);

        // No spacers should exist for single item
        final spacers = find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.width == 10,
        );
        expect(spacers, findsNothing);

        controller.controller.dispose();
      });

      testWidgets('works with many items in dynamic height mode',
          (WidgetTester tester) async {
        final items = List.generate(
          20,
          (index) => TestItem(id: index, name: 'Item $index'),
        );
        final controller = createTestController(items: items);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  PagyHorizontalListView<TestItem>(
                    controller: controller,
                    useDynamicHeight: true,
                    itemSpacing: 8,
                    itemBuilderWithIndex: (context, item, index) {
                      return Container(
                        width: 100,
                        height: 80,
                        child: Text(item.name),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // At least first few items should be visible
        expect(find.text('Item 0'), findsOneWidget);
        expect(find.text('Item 1'), findsOneWidget);

        controller.controller.dispose();
      });
    });
  });
}
