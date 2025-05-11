import 'package:dio/dio.dart';

class ApiException {
  static String getException(DioException exception) {
    // Show backend error if available
    final serverMessage = exception.response?.data;
    if (serverMessage is Map<String, dynamic> &&
        serverMessage['message'] != null) {
      return serverMessage['message'];
    } else if (serverMessage is String) {
      return serverMessage;
    }

    switch (exception.type) {
      case DioExceptionType.connectionError:
        return '📡 Network Error: Please check your internet connection';
      case DioExceptionType.receiveTimeout:
        return '⏳ Request Timeout: Server took too long to respond';
      case DioExceptionType.connectionTimeout:
        return '🔌 Connection Timeout: Unable to connect to server';
      case DioExceptionType.badResponse:
        return '❗ Server Error: Received invalid response';
      case DioExceptionType.cancel:
        return '❌ Request Cancelled';
      default:
        return '⚠️ Something went wrong. Please try again.';
    }
  }
}
