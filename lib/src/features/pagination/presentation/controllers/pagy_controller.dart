import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pagy/internal_imports.dart';

import '../../../../../pagy.dart';
import '../../../../core/services/dependency_injections.dart';
import '../../../../core/services/request_guard.dart';
import '../../param/pagy_params.dart';

part 'pagy_controller_loader.dart';
part 'pagy_controller_helpers.dart';

/// {@template pagy_controller}
/// A controller that manages paginated API data and local item modifications.
///
/// `PagyController` is responsible for:
/// - Fetching data from an API endpoint with pagination
/// - Managing internal state via [PagyState]
/// - Retrying failed requests with cached parameters
/// - Allowing local updates to the item list without re-fetching
///
/// ### Key Responsibilities:
/// - Holds the list of items and exposes them as read-only
/// - Stores pagination, filter, and query parameters
/// - Handles cancellation of requests
/// - Integrates with `PagyBuilder`, `PagyListView`, and `PagyGridView`
///
/// ### Example Usage:
/// ```dart
/// final controller = PagyController<User>(
///   endPoint: '/users',
///   fromMap: (json) => User.fromJson(json),
///   responseMapper: (response) => PagyResponseParser.fromJson(response),
///   limit: 20,
/// );
///
/// // Trigger load
/// controller.loadData();
/// ```
/// {@endtemplate}
class PagyController<T> {
  // ---------------------------------------------------------------------------
  // Core Properties
  // ---------------------------------------------------------------------------

  /// Holds the API pagination state and notifies listeners on updates.
  ///
  /// Used by [PagyObserver], and other widgets to rebuild
  /// when data, loading, or error state changes.
  final ValueNotifier<PagyState<T>> controller;

  /// The API endpoint used for fetching paginated data.
  ///
  /// Example: `'/users'`, `'/products/list'`.
  final String endPoint;

  /// Converts raw JSON response into a model object of type [T].
  ///
  /// Example:
  /// ```dart
  /// fromMap: (json) => User.fromJson(json)
  /// ```
  final T Function(Map<String, dynamic>) fromMap;

  /// Optional token to include in API request headers (e.g., Bearer token).
  final String? token;

  /// Extra query parameters appended to pagination params.
  ///
  /// Example: `{ 'sort': 'latest', 'category': 'books' }`
  final Map<String, dynamic>? additionalQueryParams;

  /// Number of items to fetch per page (default: `4`).
  final int limit;

  /// Internal filter object for persisting last applied filters.
  ///
  /// Updated when [loadData] is called with new filter parameters.
  Map<String, dynamic>? filter;

  /// Function to parse API response into a [PagyResponseParser].
  ///
  /// Typically extracts `items` and `total` count from the raw API response.
  final PagyResponseParser Function(Map<String, dynamic> response)?
      responseMapper;

  /// Determines whether pagination params are sent as query or payload.
  ///
  /// Controlled by [PaginationPayloadMode] (e.g., query vs body).
  final PaginationPayloadMode? paginationMode;

  /// Last used request parameters, stored for retry functionality.
  Map<String, dynamic>? lastParams;

  /// Internal storage of fetched items.
  ///
  /// Use [items] for a read-only view.
  final List<T> itemsList = [];

  /// Read-only, unmodifiable view of the current items list.
  List<T> get items => List.unmodifiable(itemsList);

  /// Current pagination state exposed from [controller].
  ///
  /// Example usage:
  /// ```dart
  /// if (state.isFetching) showLoader();
  /// ```
  PagyState<T> get state => controller.value;

  /// Defines the HTTP method used for requests.
  ///
  /// Supported types: GET, POST, PUT, DELETE (via [PagyApiRequestType]).
  final PagyApiRequestType requestType;

  /// Optional static payload data included in API requests.
  ///
  /// Useful for POST or PUT requests.
  final dynamic payloadData;

  /// Internal cancel token to abort API requests in-flight.
  ///
  /// Helps prevent duplicate requests or memory leaks.
  CancelToken? cancelToken;

  /// Optional custom headers for API requests.
  ///
  /// Example: `{ 'Authorization': 'Bearer <token>' }`
  final dynamic headers;

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  /// Creates a [PagyController] for managing paginated data from an API.
  ///
  /// Automatically initializes [PagyConfig] to ensure dependency injection
  /// and defaults are ready.
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
  }) : controller = ValueNotifier<PagyState<T>>(PagyState<T>()) {
    // Ensure global config and dependencies are initialized lazily.
    PagyConfig().ensureInitialized();
  }
}
