import 'package:dio/dio.dart';

class ApiException {
  static String getException(DioException exception) {
    // Prefer server message if available
    final serverMessage = exception.response?.data;
    if (serverMessage is Map<String, dynamic> &&
        serverMessage['message'] != null) {
      return serverMessage['message'];
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
}
