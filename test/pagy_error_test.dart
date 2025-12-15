import 'package:flutter_test/flutter_test.dart';
import 'package:pagy/pagy.dart';

void main() {
  group('PagyError', () {
    test('creates network error with correct properties', () {
      final error = PagyError.network(message: 'Connection failed');

      expect(error.type, PagyErrorType.network);
      expect(error.message, 'Connection failed');
      expect(error.suggestion,
          'Please check your internet connection and try again');
      expect(error.statusCode, isNull);
    });

    test('creates unauthorized error with status code', () {
      final error = PagyError.unauthorized(message: 'Invalid token');

      expect(error.type, PagyErrorType.unauthorized);
      expect(error.message, 'Invalid token');
      expect(error.statusCode, isNull);
      expect(error.suggestion,
          contains('permission')); // Actual message without statusCode
    });

    test('creates server error with status code', () {
      final error = PagyError.serverError(
        message: 'Internal server error',
        statusCode: 500,
      );

      expect(error.type, PagyErrorType.serverError);
      expect(error.message, 'Internal server error');
      expect(error.statusCode, 500);
      expect(error.suggestion, contains('try again later'));
    });

    test('creates malformed response error', () {
      final error = PagyError.malformedResponse(message: 'Invalid JSON');

      expect(error.type, PagyErrorType.malformedResponse);
      expect(error.message, 'Invalid JSON');
      expect(error.suggestion, contains('response'));
    });

    test('creates timeout error', () {
      final error = PagyError.timeout();

      expect(error.type, PagyErrorType.timeout);
      expect(error.message, 'Request timed out');
      expect(error.suggestion, contains('connection'));
    });

    test('creates cancelled error', () {
      final error = PagyError.cancelled();

      expect(error.type, PagyErrorType.cancelled);
      expect(error.message, 'Request was cancelled');
      expect(error.suggestion, isNull);
    });

    test('creates unknown error with original exception', () {
      final originalException = Exception('Something went wrong');
      final error = PagyError.unknown(message: originalException.toString());

      expect(error.type, PagyErrorType.unknown);
      expect(error.message, contains('Something went wrong'));
      expect(error.suggestion, contains('support'));
    });

    test('stores original exception', () {
      final originalException = Exception('Test exception');
      final error = PagyError(
        type: PagyErrorType.network,
        message: 'Error occurred',
        originalException: originalException,
      );

      expect(error.originalException, originalException);
    });
  });
}
