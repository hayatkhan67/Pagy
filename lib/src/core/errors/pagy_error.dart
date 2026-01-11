/// Types of errors that can occur during pagination.
enum PagyErrorType {
  /// Network connectivity issues
  network,

  /// Authentication or authorization failures (401, 403)
  unauthorized,

  /// Server errors (500, 502, 503, etc.)
  serverError,

  /// Response format doesn't match expected structure
  malformedResponse,

  /// Request timeout
  timeout,

  /// Request was cancelled
  cancelled,

  /// Unknown or unexpected error
  unknown,
}

/// Comprehensive error information for Pagy operations.
///
/// Provides error type, message, helpful suggestions, and status code
/// to help developers debug and handle errors effectively.
///
/// Example:
/// ```dart
/// if (state.error != null) {
///   final error = state.error!;
///   print('Error: ${error.message}');
///   if (error.suggestion != null) {
///     print('Suggestion: ${error.suggestion}');
///   }
/// }
/// ```
class PagyError {
  /// The type of error that occurred
  final PagyErrorType type;

  /// Human-readable error message
  final String message;

  /// Optional suggestion to help fix the error
  final String? suggestion;

  /// HTTP status code if applicable
  final int? statusCode;

  /// Original exception if available
  final dynamic originalException;

  const PagyError({
    required this.type,
    required this.message,
    this.suggestion,
    this.statusCode,
    this.originalException,
  });

  /// Creates a network error
  factory PagyError.network({String? message, dynamic exception}) {
    return PagyError(
      type: PagyErrorType.network,
      message: message ?? 'Network connection failed',
      suggestion: 'Please check your internet connection and try again',
      originalException: exception,
    );
  }

  /// Creates an unauthorized error (401, 403)
  factory PagyError.unauthorized({String? message, int? statusCode}) {
    return PagyError(
      type: PagyErrorType.unauthorized,
      message: message ?? 'Authentication required',
      suggestion: statusCode == 401
          ? 'Your session may have expired. Please log in again'
          : 'You don\'t have permission to access this resource',
      statusCode: statusCode,
    );
  }

  /// Creates a server error (5xx)
  factory PagyError.serverError({
    String? message,
    int? statusCode,
    dynamic exception,
  }) {
    return PagyError(
      type: PagyErrorType.serverError,
      message: message ?? 'Server error occurred',
      suggestion: 'The server is experiencing issues. Please try again later',
      statusCode: statusCode,
      originalException: exception,
    );
  }

  /// Creates a malformed response error
  factory PagyError.malformedResponse({String? message, String? field}) {
    return PagyError(
      type: PagyErrorType.malformedResponse,
      message: message ?? 'Response format is invalid',
      suggestion: field != null
          ? 'Expected field "$field" not found in response. '
              'Check your responseParser configuration'
          : 'Response does not match expected format. '
              'Verify your responseParser implementation',
    );
  }

  /// Creates a timeout error
  factory PagyError.timeout({String? message}) {
    return PagyError(
      type: PagyErrorType.timeout,
      message: message ?? 'Request timed out',
      suggestion:
          'The request took too long. Check your connection or try again',
    );
  }

  /// Creates a cancelled error
  factory PagyError.cancelled() {
    return const PagyError(
      type: PagyErrorType.cancelled,
      message: 'Request was cancelled',
    );
  }

  /// Creates an unknown error
  factory PagyError.unknown({String? message, dynamic exception}) {
    return PagyError(
      type: PagyErrorType.unknown,
      message: message ?? 'An unexpected error occurred',
      suggestion: 'Please try again or contact support if the issue persists',
      originalException: exception,
    );
  }

  /// Creates a PagyError from an exception
  factory PagyError.fromException(dynamic exception, {int? statusCode}) {
    if (exception.toString().toLowerCase().contains('network')) {
      return PagyError.network(exception: exception);
    }

    if (statusCode != null) {
      if (statusCode == 401 || statusCode == 403) {
        return PagyError.unauthorized(statusCode: statusCode);
      }
      if (statusCode >= 500) {
        return PagyError.serverError(
          statusCode: statusCode,
          exception: exception,
        );
      }
    }

    return PagyError.unknown(
      message: exception.toString(),
      exception: exception,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('PagyError(type: $type, message: $message');
    if (statusCode != null) buffer.write(', statusCode: $statusCode');
    if (suggestion != null) buffer.write(', suggestion: $suggestion');
    buffer.write(')');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PagyError &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          message == other.message &&
          statusCode == other.statusCode;

  @override
  int get hashCode => type.hashCode ^ message.hashCode ^ statusCode.hashCode;
}
