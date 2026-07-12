import 'package:dio/dio.dart';

import '../errors/pagy_error.dart';

class ApiException {
  static String getException(DioException exception) {
    // Prefer server message if available
    final serverMessage = exception.response?.data;
    if (serverMessage is Map<String, dynamic>) {
      final message = serverMessage['message'];
      if (message is String && message.isNotEmpty) return message;
    } else if (serverMessage is String && serverMessage.isNotEmpty) {
      return serverMessage;
    }

    switch (exception.type) {
      case DioExceptionType.connectionError:
        return '📡 Network Error: Please check your internet connection.';
      case DioExceptionType.receiveTimeout:
        return '⏳ Request Timeout: The server took too long to respond.';
      case DioExceptionType.connectionTimeout:
        return '🔌 Connection Timeout: Unable to connect to the server.';
      case DioExceptionType.badResponse:
        return '❗ Server Error: Invalid or unexpected response.';
      case DioExceptionType.cancel:
        return '❌ Request Cancelled.';
      default:
        // fallback for unknown or null types
        return (exception.message?.isNotEmpty ?? false)
            ? '⚠️ ${exception.message}'
            : '⚠️ Something went wrong. Please try again.';
    }
  }

  /// Converts a [DioException] into a typed [PagyError], preserving the
  /// server-supplied message and HTTP status code.
  ///
  /// [PagyError.fromDioException] classifies the error type but falls back to
  /// `exception.toString()` for the message and drops the status code on its
  /// unknown branch, so both are reapplied here.
  static PagyError toPagyError(DioException exception,
      {StackTrace? stackTrace}) {
    return PagyError.fromDioException(exception, stackTrace: stackTrace)
        .copyWith(
      message: getException(exception),
      statusCode: exception.response?.statusCode,
      originalException: exception,
    );
  }
}
