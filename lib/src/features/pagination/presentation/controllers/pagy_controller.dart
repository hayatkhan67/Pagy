import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pagy/src/core/services/dependency_injections.dart';
import 'package:pagy/src/core/utils/pagy_utils.dart';
import 'package:pagy/src/features/pagination/param/pagy_params.dart';

import '../../../../../pagy.dart';
part 'pagy_controller_loader.dart';
part 'pagy_controller_helpers.dart';

/// A controller to manage paginated API data and local item modifications.
class PagyController<T> {
  /// API pagination state notifier.
  final ValueNotifier<PagyState<T>> controller;

  /// The API endpoint for data retrieval.
  final String endPoint;

  /// Function to map JSON response to model [T].
  final T Function(Map<String, dynamic>) fromMap;

  /// Optional auth token to be sent with requests.
  final String? token;

  /// Optional query parameters to be merged with pagination params.
  final Map<String, dynamic>? additionalQueryParams;

  /// The number of items per page.
  final int limit;

  /// Internal filter used to store the last applied filters.
  Map<String, dynamic>? filter;

  /// Function to parse the API response to a [PagyResponseParser].
  final PagyResponseParser Function(Map<String, dynamic> response)?
      responseMapper;

  /// Determines whether pagination is sent as query parameters or payload.
  final PaginationPayloadMode? paginationMode;

  /// The last parameters used in the API call, used for retry logic.
  Map<String, dynamic>? lastParams;

  /// Internal list holding the current items.
  final List<T> itemsList = [];

  /// Unmodifiable view of the current item list.
  List<T> get items => List.unmodifiable(itemsList);

  /// Returns the current state held by the [controller].
  PagyState<T> get state => controller.value;

  /// The type of API request being made.
  final PagyApiRequestType requestType;

  /// Optional payload data to be sent with the request.
  final dynamic payloadData;

  /// Internal cancel token for API requests.
  CancelToken? cancelToken;

  /// Optional custom headers.
  final dynamic headers;

  PagyController({
    required this.endPoint,
    required this.fromMap,
    required this.responseMapper,
    this.token,
    this.additionalQueryParams,
    this.limit = 4,
    this.paginationMode,
    this.payloadData,
    this.headers,
    this.requestType = PagyApiRequestType.get,
  }) : controller = ValueNotifier<PagyState<T>>(PagyState<T>());
}
