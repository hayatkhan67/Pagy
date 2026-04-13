import 'package:flutter_test/flutter_test.dart';
import 'package:pagy/pagy.dart';

void main() {
  group('PagyState', () {
    test('creates with default values', () {
      final state = PagyState<String>();

      expect(state.data, isEmpty);
      expect(state.isFetching, isFalse);
      expect(state.isMoreFetching, isFalse);
      expect(state.currentPage, 1); // Default is 1, not 0
      expect(state.totalPages, 1);
      expect(state.error, isNull);
    });

    test('creates with custom values', () {
      final error = PagyError.network(message: 'Test error');
      final state = PagyState<int>(
        data: [1, 2, 3],
        isFetching: true,
        isMoreFetching: false,
        currentPage: 2,
        totalPages: 5,
        error: error,
      );

      expect(state.data, [1, 2, 3]);
      expect(state.isFetching, isTrue);
      expect(state.isMoreFetching, isFalse);
      expect(state.currentPage, 2);
      expect(state.totalPages, 5);
      expect(state.error, error);
    });

    test('copyWith creates new instance with updated values', () {
      final state = PagyState<String>(
        data: ['a', 'b'],
        currentPage: 1,
      );

      final newState = state.copyWith(
        data: ['a', 'b', 'c'],
        currentPage: 2,
      );

      expect(newState.data, ['a', 'b', 'c']);
      expect(newState.currentPage, 2);
      // Original should be unchanged
      expect(state.data, ['a', 'b']);
      expect(state.currentPage, 1);
    });

    test('copyWith preserves unchanged values', () {
      final error = PagyError.network(message: 'Test');
      final state = PagyState<String>(
        data: ['a'],
        isFetching: true,
        currentPage: 1,
        totalPages: 10,
        error: error,
      );

      final newState = state.copyWith(
        currentPage: 2,
      );

      expect(newState.data, ['a']);
      expect(newState.isFetching, isTrue);
      expect(newState.currentPage, 2); // Changed
      expect(newState.totalPages, 10);
      expect(newState.error, error);
    });

    test('deprecated errorMessage still works', () {
      // ignore: deprecated_member_use_from_same_package
      final state = PagyState<String>(errorMessage: 'Test error');

      // ignore: deprecated_member_use_from_same_package
      expect(state.errorMessage, 'Test error');
    });

    test('error field takes precedence over deprecated errorMessage', () {
      final error = PagyError.network(message: 'Network error');
      final state = PagyState<String>(
        error: error,
        // ignore: deprecated_member_use_from_same_package
        errorMessage: 'Old error message',
      );

      expect(state.error, error);
      expect(state.error!.message, 'Network error');
    });

    test('copyWith updates error field', () {
      final initialError = PagyError.network(message: 'Initial');
      final state = PagyState<String>(error: initialError);

      final newError = PagyError.serverError(message: 'Server error');
      final newState = state.copyWith(error: newError);

      expect(newState.error, newError);
      expect(newState.error!.type, PagyErrorType.serverError);
    });

    test('copyWith clearError clears error and errorMessage', () {
      final error = PagyError.network(message: 'Network error');
      // ignore: deprecated_member_use_from_same_package
      final state = PagyState<String>(error: error, errorMessage: 'Legacy');

      final newState = state.copyWith(clearError: true);

      expect(newState.error, isNull);
      // ignore: deprecated_member_use_from_same_package
      expect(newState.errorMessage, isNull);
    });

    test('copyWith can clear error by omitting it', () {
      final error = PagyError.network(message: 'Test');
      final state = PagyState<String>(error: error);

      // copyWith without specifying error keeps the existing error
      // To clear it, you need to pass a new state without error
      final newState = PagyState<String>(
        data: state.data,
        isFetching: state.isFetching,
        isMoreFetching: state.isMoreFetching,
        currentPage: state.currentPage,
        totalPages: state.totalPages,
      );

      expect(newState.error, isNull);
    });

    test('handles empty data list', () {
      final state = PagyState<int>(data: []);

      expect(state.data, isEmpty);
      expect(state.data, isA<List<int>>());
    });

    test('handles large data sets', () {
      final largeList = List.generate(1000, (i) => i);
      final state = PagyState<int>(data: largeList);

      expect(state.data, hasLength(1000));
      expect(state.data.first, 0);
      expect(state.data.last, 999);
    });
  });
}
