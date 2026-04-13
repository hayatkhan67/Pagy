import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pagy/internal_imports.dart';

import '../../../../../pagy.dart';
import '../../../../core/services/dependency_injections.dart';

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
  /// **Deprecated:** Use [query] instead for better clarity.
  ///
  /// Example: `{ 'sort': 'latest', 'category': 'books' }`
  @Deprecated('Use query instead. Will be removed in v2.0.0')
  final Map<String, dynamic>? additionalQueryParams;

  /// Query parameters to append to API requests.
  ///
  /// Example: `{ 'sort': 'latest', 'category': 'books' }`
  final Map<String, dynamic>? query;

  /// Number of items to fetch per page (default: `4`).
  final int limit;

  /// Internal filter object for persisting last applied filters.
  ///
  /// Updated when [loadData] is called with new filter parameters.
  Map<String, dynamic>? filter;

  /// Function to parse API response into a [PagyResponseParser].
  ///
  /// **Deprecated:** Use [responseParser] instead for better clarity.
  ///
  /// Typically extracts `items` and `total` count from the raw API response.
  @Deprecated('Use responseParser instead. Will be removed in v2.0.0')
  final PagyResponseParser Function(Map<String, dynamic> response)?
      responseMapper;

  /// Function to parse API response into a [PagyResponseParser].
  ///
  /// Extracts the list of items and pagination metadata from API response.
  ///
  /// Example:
  /// ```dart
  /// responseParser: PagyParsers.dataWithPagination,
  /// // or custom:
  /// responseParser: (response) => PagyResponseParser(
  ///   list: response['items'],
  ///   totalPages: response['total_pages'],
  /// ),
  /// ```
  final PagyResponseParser Function(Map<String, dynamic> response)?
      responseParser;

  /// Determines whether pagination params are sent as query or payload.
  ///
  /// **Deprecated:** Use [payloadMode] instead for consistency.
  ///
  /// Controlled by [PaginationPayloadMode] (e.g., query vs body).
  @Deprecated('Use payloadMode instead. Will be removed in v2.0.0')
  final PaginationPayloadMode? paginationMode;

  /// Mode for sending pagination parameters (query string or request body).
  ///
  /// Controlled by [PaginationPayloadMode].
  final PaginationPayloadMode? payloadMode;

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

  /// Optional use case override (improves testability).
  final GetPaginatedDataUseCase? _useCase;

  /// Optional page use case override (Clean Architecture pathway).
  final GetPaginatedPageUseCase? _pageUseCase;

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
    @Deprecated('Use responseParser instead') this.responseMapper,
    this.responseParser,
    this.token,
    @Deprecated('Use query instead') this.additionalQueryParams,
    this.query,
    this.limit = 4,
    @Deprecated('Use payloadMode instead') this.paginationMode,
    this.payloadMode,
    this.payloadData,
    this.headers,
    this.requestType = PagyApiRequestType.get,
    GetPaginatedDataUseCase? useCase,
    GetPaginatedPageUseCase? pageUseCase,
  })  : controller = ValueNotifier<PagyState<T>>(PagyState<T>()),
        _useCase = useCase,
        _pageUseCase = pageUseCase {
    // Ensure both old and new parameters work
    assert(
      responseMapper != null || responseParser != null,
      'Either responseMapper or responseParser must be provided',
    );
    // Ensure global config and dependencies are initialized lazily.
    PagyConfig().ensureInitialized();
  }

  // ---------------------------------------------------------------------------
  // Convenience Methods
  // ---------------------------------------------------------------------------

  /// Clears current data and reloads from page 1.
  ///
  /// Useful for pull-to-refresh functionality.
  /// Use [preserveFilters] to keep existing filters on refresh.
  ///
  /// Example:
  /// ```dart
  /// RefreshIndicator(
  ///   onRefresh: () async {
  ///     await controller.refresh();
  ///   },
  ///   child: PagyListView(...),
  /// )
  /// ```
  Future<void> refresh({bool? preserveFilters}) async {
    itemsList.clear();
    await loadData(preserveFiltersOnRefresh: preserveFilters);
  }

  /// Applies filters and reloads data from page 1.
  ///
  /// Example:
  /// ```dart
  /// controller.applyFilters({'category': 'electronics', 'price_max': 500});
  /// ```
  Future<void> applyFilters(Map<String, dynamic> filters) async {
    itemsList.clear();
    await loadData(queryParameter: filters);
  }

  /// Performs a search with the given query.
  ///
  /// [searchKey] is the parameter name your API expects (default: 'q').
  ///
  /// Example:
  /// ```dart
  /// controller.search('laptop', searchKey: 'query');
  /// ```
  Future<void> search(String query, {String searchKey = 'q'}) async {
    itemsList.clear();
    await loadData(queryParameter: {searchKey: query});
  }

  /// Clears all currently applied filters and query parameters.
  ///
  /// When [refresh] is true (default), it reloads from page 1 with no filters.
  Future<void> clearFilters({bool refresh = true}) async {
    filter = null;
    if (refresh) {
      itemsList.clear();
      await loadData(preserveFiltersOnRefresh: false);
    }
  }

  /// Explicitly loads the next page of data.
  ///
  /// Normally called automatically on scroll, but can be triggered manually.
  Future<void> loadMore() async {
    if (state.currentPage < state.totalPages && !state.isMoreFetching) {
      await loadData(refresh: false);
    }
  }

  // ---------------------------------------------------------------------------
  // Metadata Getter
  // ---------------------------------------------------------------------------

  /// Returns pagination metadata for UI display.
  ///
  /// Example:
  /// ```dart
  /// Text('Page ${controller.metadata.currentPage} of ${controller.metadata.totalPages}');
  /// LinearProgressIndicator(value: controller.metadata.progress);
  /// ```
  PagyMetadata get metadata => PagyMetadata(
        currentPage: state.currentPage.toInt(),
        totalPages: state.totalPages.toInt(),
        itemsPerPage: limit,
        loadedItems: itemsList.length,
      );

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------

  /// Gets the effective response parser (supports both old and new parameters)
  PagyResponseParser Function(Map<String, dynamic>)?
      get _effectiveResponseParser =>
          // ignore: deprecated_member_use_from_same_package
          responseParser ?? responseMapper;

  /// Gets the effective query parameters (supports both old and new parameters)
  Map<String, dynamic>? get _effectiveQuery =>
      // ignore: deprecated_member_use_from_same_package
      query ?? additionalQueryParams;

  /// Gets the effective payload mode (supports both old and new parameters)
  PaginationPayloadMode? get _effectivePayloadMode =>
      // ignore: deprecated_member_use_from_same_package
      payloadMode ?? paginationMode;

  /// Gets the effective use case (supports dependency injection override).
  GetPaginatedDataUseCase get _effectiveUseCase =>
      _useCase ?? locator.get<GetPaginatedDataUseCase>();

  /// Whether the Clean Architecture page use case is enabled.
  bool get _usePageUseCase => _pageUseCase != null;

  /// Gets the effective page use case (supports dependency injection override).
  GetPaginatedPageUseCase get _effectivePageUseCase =>
      _pageUseCase ?? locator.get<GetPaginatedPageUseCase>();
}
