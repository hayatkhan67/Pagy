import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagy/pagy.dart';
import 'package:pagy/src/core/exceptions/exception_handling.dart';

DioException _dio(
  DioExceptionType type, {
  int? statusCode,
  dynamic data,
  String? message,
}) {
  final options = RequestOptions(path: '/items');
  return DioException(
    requestOptions: options,
    type: type,
    message: message,
    response: statusCode == null && data == null
        ? null
        : Response(
            requestOptions: options,
            statusCode: statusCode,
            data: data,
          ),
  );
}

void main() {
  group('ApiException.getException', () {
    test('prefers a string server message', () {
      final result = ApiException.getException(
        _dio(DioExceptionType.badResponse,
            statusCode: 422, data: {'message': 'Email already taken'}),
      );

      expect(result, 'Email already taken');
    });

    test('falls back when server message is a map', () {
      // Regression: this used to throw a TypeError inside the error handler.
      final result = ApiException.getException(
        _dio(DioExceptionType.badResponse, statusCode: 500, data: {
          'message': {'en': 'Server exploded'}
        }),
      );

      expect(result, contains('Server Error'));
    });

    test('falls back when server message is a number', () {
      final result = ApiException.getException(
        _dio(DioExceptionType.connectionError, data: {'message': 123}),
      );

      expect(result, contains('Network Error'));
    });

    test('falls back when server message is an empty string', () {
      final result = ApiException.getException(
        _dio(DioExceptionType.receiveTimeout, data: {'message': ''}),
      );

      expect(result, contains('Request Timeout'));
    });

    test('accepts a plain string response body', () {
      final result = ApiException.getException(
        _dio(DioExceptionType.badResponse, statusCode: 400, data: 'Bad input'),
      );

      expect(result, 'Bad input');
    });
  });

  group('ApiException.toPagyError', () {
    final cases = <String, ({DioException exception, PagyErrorType type})>{
      'connectionError -> network': (
        exception: _dio(DioExceptionType.connectionError),
        type: PagyErrorType.network,
      ),
      'connectionTimeout -> timeout': (
        exception: _dio(DioExceptionType.connectionTimeout),
        type: PagyErrorType.timeout,
      ),
      'sendTimeout -> timeout': (
        exception: _dio(DioExceptionType.sendTimeout),
        type: PagyErrorType.timeout,
      ),
      'receiveTimeout -> timeout': (
        exception: _dio(DioExceptionType.receiveTimeout),
        type: PagyErrorType.timeout,
      ),
      'cancel -> cancelled': (
        exception: _dio(DioExceptionType.cancel),
        type: PagyErrorType.cancelled,
      ),
      'badResponse 401 -> unauthorized': (
        exception: _dio(DioExceptionType.badResponse, statusCode: 401),
        type: PagyErrorType.unauthorized,
      ),
      'badResponse 403 -> unauthorized': (
        exception: _dio(DioExceptionType.badResponse, statusCode: 403),
        type: PagyErrorType.unauthorized,
      ),
      'badResponse 500 -> serverError': (
        exception: _dio(DioExceptionType.badResponse, statusCode: 500),
        type: PagyErrorType.serverError,
      ),
      'badResponse 503 -> serverError': (
        exception: _dio(DioExceptionType.badResponse, statusCode: 503),
        type: PagyErrorType.serverError,
      ),
      'badResponse 404 -> unknown': (
        exception: _dio(DioExceptionType.badResponse, statusCode: 404),
        type: PagyErrorType.unknown,
      ),
      'unknown -> unknown': (
        exception: _dio(DioExceptionType.unknown, message: 'socket died'),
        type: PagyErrorType.unknown,
      ),
    };

    cases.forEach((name, testCase) {
      test('maps $name', () {
        final error = ApiException.toPagyError(testCase.exception);
        expect(error.type, testCase.type);
      });
    });

    test('preserves the HTTP status code', () {
      final error = ApiException.toPagyError(
        _dio(DioExceptionType.badResponse, statusCode: 404),
      );

      // fromDioException alone drops the status code on the unknown branch.
      expect(error.statusCode, 404);
    });

    test('preserves the server-supplied message', () {
      final error = ApiException.toPagyError(
        _dio(DioExceptionType.badResponse,
            statusCode: 500, data: {'message': 'Database unavailable'}),
      );

      expect(error.type, PagyErrorType.serverError);
      expect(error.message, 'Database unavailable');
      expect(error.statusCode, 500);
    });

    test('keeps the original exception for debugging', () {
      final exception = _dio(DioExceptionType.connectionError);
      final error = ApiException.toPagyError(exception);

      expect(error.originalException, same(exception));
    });

    test('supplies a suggestion for typed errors', () {
      final error = ApiException.toPagyError(
        _dio(DioExceptionType.badResponse, statusCode: 401),
      );

      expect(error.suggestion, isNotNull);
    });
  });
}
