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
}
