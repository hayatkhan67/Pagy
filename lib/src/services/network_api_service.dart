import 'package:dio/dio.dart';

import '../config/pagy_config.dart';
import '../exceptions/exception_handling.dart';
import '../utils.dart';

class NetworkApiService {
  static final NetworkApiService instance =
      NetworkApiService._privateConstructor();

  late final Dio _dio;

  NetworkApiService._privateConstructor() {
    _dio = Dio(
      BaseOptions(
        baseUrl: PagyConfig().baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
      ),
    );

    if (PagyConfig().apiLogs) {
      _dio.interceptors.add(
        LogInterceptor(
          responseBody: true,
          requestHeader: false,
          error: true,
          requestBody: true,
          responseHeader: false,
          request: true,
          logPrint: (object) => log(object.toString()),
        ),
      );
    }
  }

  Future getApi({
    required String endPoints,
    Map<String, dynamic>? queryParameter,
    Map<String, dynamic>? payload,
    String? token,
    bool isAuthorize = false,
    CancelToken? cancelToken,
    headers,
  }) async {
    try {
      Map<String, String> apiHeaders = {
        'Accept': 'application/json',
      };
      if (headers != null) apiHeaders.addAll(headers);

      if (isAuthorize && token != null) {
        apiHeaders["Authorization"] = "Bearer $token";
      }

      final response = await _dio.get(
        endPoints,
        queryParameters: queryParameter,
        data: payload,
        options: Options(headers: apiHeaders),
        cancelToken: cancelToken,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return response.data;
      }
    } on DioException catch (e) {
      log(name: endPoints, '${e.response}');
      return apiErrors(e);
    }
  }

  Future postApi({
    required String endPoints,
    Map<String, dynamic>? queryParameter,
    dynamic data,
    String? token,
    bool isAuthorize = false,
    headers,
    CancelToken? cancelToken,
  }) async {
    try {
      Map<String, String> apiHeaders = {
        'Accept': 'application/json',
      };
      if (headers != null) apiHeaders.addAll(headers);

      if (isAuthorize && token != null) {
        apiHeaders["Authorization"] = "Bearer $token";
      }

      final response = await _dio.post(
        endPoints,
        queryParameters: queryParameter,
        data: data,
        options: Options(headers: apiHeaders),
        cancelToken: cancelToken,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return response.data;
      }
    } on DioException catch (e) {
      log(name: endPoints, '${e.response}');
      return apiErrors(e);
    }
  }

  String? apiErrors(DioException e) {
    throw ApiException.getException(e);
  }
}
