import 'package:flutter_test/flutter_test.dart';
import 'package:pagy/pagy.dart';

void main() {
  group('PagyParsers', () {
    test('dataWithPagination - parses standard response', () {
      final response = {
        'data': [
          {'id': 1, 'name': 'Item 1'},
          {'id': 2, 'name': 'Item 2'},
        ],
        'pagination': {'totalPages': 5}
      };

      final result = PagyParsers.dataWithPagination(response);

      expect(result.list, hasLength(2));
      expect(result.list[0]['id'], 1);
      expect(result.totalPages, 5);
    });

    test('dataWithPagination - handles missing pagination', () {
      final response = {
        'data': [
          {'id': 1}
        ]
      };

      final result = PagyParsers.dataWithPagination(response);

      expect(result.list, hasLength(1));
      expect(result.totalPages, isNull);
    });

    test('itemsWithTotal - parses items and total_pages', () {
      final response = {
        'items': [
          {'id': 1},
          {'id': 2},
          {'id': 3}
        ],
        'total_pages': 10
      };

      final result = PagyParsers.itemsWithTotal(response);

      expect(result.list, hasLength(3));
      expect(result.totalPages, 10);
    });

    test('resultsWithCount - parses results and page_count', () {
      final response = {
        'results': [
          {'id': 1},
          {'id': 2}
        ],
        'page_count': 7
      };

      final result = PagyParsers.resultsWithCount(response);

      expect(result.list, hasLength(2));
      expect(result.totalPages, 7);
    });

    test('simpleList - parses data and total', () {
      final response = {
        'data': [
          {'id': 1},
          {'id': 2},
          {'id': 3},
          {'id': 4}
        ],
        'total': 20
      };

      final result = PagyParsers.simpleList(response);

      expect(result.list, hasLength(4));
      expect(result.totalPages, 20);
    });

    test('dataWithMeta - parses data and meta.total_pages', () {
      final response = {
        'data': [
          {'id': 1}
        ],
        'meta': {'total_pages': 3}
      };

      final result = PagyParsers.dataWithMeta(response);

      expect(result.list, hasLength(1));
      expect(result.totalPages, 3);
    });

    test('customKey - uses custom keys for parsing', () {
      final response = {
        'users': [
          {'id': 1, 'name': 'John'},
          {'id': 2, 'name': 'Jane'}
        ],
        'totalPages': 8 // Flat key instead of nested
      };

      final result = PagyParsers.customKey(
        response,
        itemKey: 'users',
        totalKey: 'totalPages',
      );

      expect(result.list, hasLength(2));
      expect(result.totalPages, 8);
    });

    test('laravel - parses Laravel pagination format', () {
      final response = {
        'data': [
          {'id': 1},
          {'id': 2}
        ],
        'last_page': 12
      };

      final result = PagyParsers.laravel(response);

      expect(result.list, hasLength(2));
      expect(result.totalPages, 12);
    });

    test('django - calculates pages from count and itemsPerPage', () {
      final response = {
        'results': [
          {'id': 1},
          {'id': 2}
        ],
        'count': 100
      };

      final result = PagyParsers.django(response, itemsPerPage: 20);

      expect(result.list, hasLength(2));
      expect(result.totalPages, 5); // 100 / 20 = 5
    });

    test('django - rounds up for partial pages', () {
      final response = {
        'results': [
          {'id': 1}
        ],
        'count': 95
      };

      final result = PagyParsers.django(response, itemsPerPage: 20);

      expect(result.totalPages, 5); // 95 / 20 = 4.75, rounds up to 5
    });

    test('django - handles zero count', () {
      final response = {'results': [], 'count': 0};

      final result = PagyParsers.django(response, itemsPerPage: 20);

      expect(result.list, isEmpty);
      expect(result.totalPages, 0);
    });
  });
}
