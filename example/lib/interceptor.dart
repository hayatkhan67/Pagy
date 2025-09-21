import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

class DioInterceptor extends Interceptor {
  final Function onTokenBlacklisted;

  DioInterceptor({required this.onTokenBlacklisted});

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.statusCode == 401 ||
        response.data['message'] == 'No such User found - Access denied') {
      onTokenBlacklisted();
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 ||
        err.response?.data['message'] == 'No such User found - Access denied') {
      onTokenBlacklisted();
    }
    super.onError(err, handler);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    super.onRequest(options, handler);
    debugPrint("Request::::::${options.uri}");
    debugPrint("Method::::::${options.method}");
    debugPrint("Headers::::::${options.headers}");
    debugPrint("QueryParams:::::::${options.queryParameters}");
    debugPrint("Body::::::${options.data}");
  }
}
