import 'package:dio/dio.dart';

import '../../../../core/config/pagy_config.dart';
import '../../domain/enums/pagy_enum.dart';
import '../../param/pagy_params.dart';
import 'network_api_service.dart';

class PagyRemoteDataSource {
  final NetworkApiService _networkService;

  PagyRemoteDataSource(this._networkService);

  Future<Response> getPaginatedData<T>(PagyParams<T> params) async {
    final cfg = PagyConfig();

    final paginationParams = {
      if (cfg.pageKey.isNotEmpty) cfg.pageKey: params.page,
      if (cfg.limitKey?.isNotEmpty ?? false) cfg.limitKey!: params.limit,
    };

    final mergedQuery = {
      ...?params.additionalQueryParams,
      ...?params.queryParameter,
    };

    Map<String, dynamic>? queryParameters;
    dynamic body;

    final mode = params.paginationMode ?? cfg.paginationMode;
    if (mode == PaginationPayloadMode.queryParams) {
      queryParameters = {...paginationParams, ...mergedQuery};
      body = params.requestType == PagyApiRequestType.post
          ? params.payloadData
          : null;
    } else {
      if (params.payloadData is Map) {
        body = {...paginationParams, ...mergedQuery, ...params.payloadData};
      } else {
        body = {
          ...paginationParams,
          ...mergedQuery,
          ...params.payloadData,
        };
      }
      queryParameters = {...?params.additionalQueryParams};
    }

    final Response apiResponse;
    try {
      apiResponse = await _networkService.request(
        endPoint: params.endPoint,
        method: params.requestType.name,
        queryParameters: queryParameters,
        body: body,
        token: params.token,
        isAuthorize: params.token != null,
        extraHeaders: params.headers,
        cancelToken: params.cancelToken,
      );
      return apiResponse;
    } catch (_) {
      rethrow;
    }
  }
}
