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
      if (cfg.pageKey.isNotEmpty && params.page != null)
        cfg.pageKey: params.page,
      if ((cfg.limitKey?.isNotEmpty ?? false) && params.limit != null)
        cfg.limitKey!: params.limit,
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
      final additionalQuery = {...?params.additionalQueryParams};
      if (params.payloadData == null) {
        body = {...paginationParams, ...mergedQuery};
        queryParameters = additionalQuery;
      } else if (params.payloadData is Map) {
        body = {...paginationParams, ...mergedQuery, ...params.payloadData};
        queryParameters = additionalQuery;
      } else {
        // If payload isn't a Map, keep it intact and send pagination via query.
        body = params.payloadData;
        queryParameters = {
          ...additionalQuery,
          ...paginationParams,
          ...mergedQuery,
        };
      }
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
