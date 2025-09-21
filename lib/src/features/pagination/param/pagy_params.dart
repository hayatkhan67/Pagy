import 'package:dio/dio.dart';

import '../domain/enums/pagy_enum.dart';

class PagyParams<T> {
  final String endPoint;
  final PagyApiRequestType requestType;
  final num? page;
  final num? limit;
  final Map<String, dynamic>? queryParameter;
  final Map<String, dynamic>? additionalQueryParams;
  final dynamic payloadData;
  final String? token;
  final Map<String, String>? headers;
  final CancelToken? cancelToken;
  final PaginationPayloadMode? paginationMode;
  final T Function(Map<String, dynamic>) fromMap;

  PagyParams({
    required this.endPoint,
    required this.requestType,
    this.page,
    this.limit,
    this.queryParameter,
    this.additionalQueryParams,
    this.payloadData,
    this.token,
    this.headers,
    this.cancelToken,
    this.paginationMode,
    required this.fromMap,
  });
}
