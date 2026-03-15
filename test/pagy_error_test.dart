import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagy/src/core/errors/pagy_error.dart';

void main() {
  group('PagyError Tests', () {
    test('PagyError should store stackTrace correctly', () {
      final stackTrace = StackTrace.current;
      final error = PagyError.unknown(
        message: 'Test error',
        stackTrace: stackTrace,
      );

      expect(error.stackTrace, equals(stackTrace));
    });

    test('PagyError.toString should include truncated stackTrace', () {
      final stackTrace = StackTrace.fromString('line 1\nline 2\nline 3\nline 4\nline 5\nline 6');
      final error = PagyError.unknown(
        message: 'Test error',
        stackTrace: stackTrace,
      );

      final str = error.toString();
      expect(str, contains('StackTrace:'));
      expect(str, contains('line 1'));
      expect(str, contains('line 5'));
      expect(str, isNot(contains('line 6'))); // Truncated after 5 lines
    });

    test('PagyError.fromException should capture stackTrace', () {
      final stackTrace = StackTrace.current;
      final exception = Exception('Nested error');
      
      final error = PagyError.fromException(
        exception,
        stackTrace: stackTrace,
      );

      expect(error.stackTrace, equals(stackTrace));
      expect(error.originalException, equals(exception));
    });

    test('PagyError.fromDioException should map stackTrace', () {
      final stackTrace = StackTrace.current;
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/'),
        stackTrace: stackTrace,
        message: 'Network timeout',
        type: DioExceptionType.connectionTimeout,
      );

      final error = PagyError.fromDioException(dioException);

      expect(error.stackTrace, equals(stackTrace));
      expect(error.type, equals(PagyErrorType.timeout));
    });

    test('PagyError.copyWith should preserve or update stackTrace', () {
      final trace1 = StackTrace.fromString('trace 1');
      final trace2 = StackTrace.fromString('trace 2');
      
      final error = PagyError.unknown(message: 'err', stackTrace: trace1);
      
      expect(error.copyWith(message: 'new').stackTrace, equals(trace1));
      expect(error.copyWith(stackTrace: trace2).stackTrace, equals(trace2));
    });
  });
}
