import 'package:dio/dio.dart';

import '../../../../core/config/pagy_config.dart';
import '../../../../core/exceptions/exception_handling.dart';
import '../../../../core/utils/pagy_utils.dart';

class NetworkApiService {
  static final NetworkApiService instance = NetworkApiService._internal();

  late final Dio _dio;

  NetworkApiService._internal() {
    _dio = Dio(
      PagyConfig().baseOptions ??
          BaseOptions(
            baseUrl: PagyConfig().baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            contentType: 'application/json',
          ),
    );

    // Enable API logging if configured
    if (PagyConfig().apiLogs) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestBody: true,
          requestHeader: false,
          responseBody: true,
          responseHeader: false,
          error: true,
          logPrint: (object) => pagyLog(object.toString()),
        ),
      );
    }

    // Custom global interceptor if provided
    final interceptor = PagyConfig().dioInterceptor;
    if (interceptor != null) {
      _dio.interceptors.add(interceptor);
    }
  }

  /// Unified API request handler (supports GET & POST)
  Future<Response> request({
    required String endPoint,
    required String method, // 'GET' or 'POST'
    Map<String, dynamic>? queryParameters,
    dynamic body,
    String? token,
    bool isAuthorize = false,
    Map<String, String>? extraHeaders,
    CancelToken? cancelToken,
  }) async {
    try {
      final headers = _buildHeaders(
        token: token,
        isAuthorize: isAuthorize,
        extraHeaders: extraHeaders,
      );

      final response = await _dio.request(
        endPoint,
        queryParameters: queryParameters,
        data: body,
        options: Options(
          method: method.toUpperCase(),
          headers: headers,
        ),
        cancelToken: cancelToken,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return response;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
        );
      }
    } on DioException catch (e) {
      pagyLog('${e.response}', name: endPoint);
      return _handleApiError(e);
    } catch (e) {
      pagyLog('Unexpected error in $method request: $e', name: endPoint);
      rethrow;
    }
  }

  /// Builds default + extra headers
  Map<String, String> _buildHeaders({
    String? token,
    bool isAuthorize = false,
    Map<String, String>? extraHeaders,
  }) {
    final headers = <String, String>{'Accept': 'application/json'};

    if (isAuthorize && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  /// Converts DioException to app-specific exception
  dynamic _handleApiError(DioException e) {
    // Special case: no host specified (baseUrl missing or invalid)
    if (e.error is ArgumentError &&
        e.error.toString().contains('No host specified')) {
      throw '⚠️ API not configured properly. Please set a valid baseUrl.';
    }

    throw ApiException.getException(e);
  }
}
