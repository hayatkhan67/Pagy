import 'package:flutter_test/flutter_test.dart';
import 'package:pagy/pagy.dart';

void main() {
  group('PagyMetadata', () {
    test('creates with all required properties', () {
      final metadata = PagyMetadata(
        currentPage: 3,
        totalPages: 10,
        itemsPerPage: 20,
        loadedItems: 60,
      );

      expect(metadata.currentPage, 3);
      expect(metadata.totalPages, 10);
      expect(metadata.itemsPerPage, 20);
      expect(metadata.loadedItems, 60);
    });

    test('hasMore returns true when current page < total pages', () {
      final metadata = PagyMetadata(
        currentPage: 3,
        totalPages: 10,
        itemsPerPage: 20,
        loadedItems: 60,
      );

      expect(metadata.hasMore, isTrue);
    });

    test('hasMore returns false when current page >= total pages', () {
      final metadata = PagyMetadata(
        currentPage: 10,
        totalPages: 10,
        itemsPerPage: 20,
        loadedItems: 200,
      );

      expect(metadata.hasMore, isFalse);
    });

    test('hasPrevious returns true when current page > 1', () {
      final metadata = PagyMetadata(
        currentPage: 3,
        totalPages: 10,
        itemsPerPage: 20,
        loadedItems: 60,
      );

      expect(metadata.hasPrevious, isTrue);
    });

    test('hasPrevious returns false when current page is 1', () {
      final metadata = PagyMetadata(
        currentPage: 1,
        totalPages: 10,
        itemsPerPage: 20,
        loadedItems: 20,
      );

      expect(metadata.hasPrevious, isFalse);
    });

    test('isFirstPage returns true when current page is 1', () {
      final metadata = PagyMetadata(
        currentPage: 1,
        totalPages: 10,
        itemsPerPage: 20,
        loadedItems: 20,
      );

      expect(metadata.isFirstPage, isTrue);
    });

    test('isFirstPage returns false when current page is not 1', () {
      final metadata = PagyMetadata(
        currentPage: 2,
        totalPages: 10,
        itemsPerPage: 20,
        loadedItems: 40,
      );

      expect(metadata.isFirstPage, isFalse);
    });

    test('isLastPage returns true when current page equals total pages', () {
      final metadata = PagyMetadata(
        currentPage: 10,
        totalPages: 10,
        itemsPerPage: 20,
        loadedItems: 200,
      );

      expect(metadata.isLastPage, isTrue);
    });

    test('isLastPage returns false when current page < total pages', () {
      final metadata = PagyMetadata(
        currentPage: 5,
        totalPages: 10,
        itemsPerPage: 20,
        loadedItems: 100,
      );

      expect(metadata.isLastPage, isFalse);
    });

    test('progress calculates correctly', () {
      final metadata = PagyMetadata(
        currentPage: 5,
        totalPages: 10,
        itemsPerPage: 20,
        loadedItems: 100,
      );

      expect(metadata.progress, 0.5); // 5 / 10 = 0.5
    });

    test('progress handles division by zero', () {
      final metadata = PagyMetadata(
        currentPage: 0,
        totalPages: 0,
        itemsPerPage: 20,
        loadedItems: 0,
      );

      expect(metadata.progress, 0.0);
    });

    test('rangeDescription formats correctly for middle pages', () {
      final metadata = PagyMetadata(
        currentPage: 3,
        totalPages: 10,
        itemsPerPage: 20,
        loadedItems: 60,
      );

      expect(metadata.rangeDescription, 'Showing 41-100 of ~200');
    });

    test('rangeDescription formats correctly for first page', () {
      final metadata = PagyMetadata(
        currentPage: 1,
        totalPages: 10,
        itemsPerPage: 20,
        loadedItems: 20,
      );

      expect(metadata.rangeDescription, 'Showing 1-20 of ~200');
    });

    test('range Description handles empty results', () {
      final metadata = PagyMetadata(
        currentPage: 1,
        totalPages: 0,
        itemsPerPage: 20,
        loadedItems: 0,
      );

      expect(metadata.rangeDescription, 'No items');
    });

    test('progressPercentage calculates correctly', () {
      final metadata = PagyMetadata(
        currentPage: 7,
        totalPages: 10,
        itemsPerPage: 20,
        loadedItems: 140,
      );

      expect(metadata.progressPercentage, 70);
    });

    test('progressPercentage handles 100%', () {
      final metadata = PagyMetadata(
        currentPage: 10,
        totalPages: 10,
        itemsPerPage: 20,
        loadedItems: 200,
      );

      expect(metadata.progressPercentage, 100);
    });

    test('progressPercentage handles zero pages', () {
      final metadata = PagyMetadata(
        currentPage: 0,
        totalPages: 0,
        itemsPerPage: 20,
        loadedItems: 0,
      );

      expect(metadata.progressPercentage, 0);
    });
  });
}
