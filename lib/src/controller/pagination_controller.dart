import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/pagy_config.dart';
import '../enum/pagy_enum.dart';
import '../state/helping_model.dart';
import '../models/response_parser_model.dart';
import '../services/network_api_service.dart';
import '../utils.dart';

/// A controller to manage paginated API data and local item modifications.
///
/// [T] is the type of item being paginated and managed.
///
/// Features:
/// - Handles pagination via query parameters or payload.
/// - Maintains internal state using [ValueNotifier].
/// - Supports adding, removing, and updating individual items.
/// - Allows external observers to be notified of state changes.
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
  Map<String, dynamic>? _filter;

  /// Function to parse the API response to a [PagyResponseParser].
  final PagyResponseParser Function(Map<String, dynamic> response)?
      responseMapper;

  /// Determines whether pagination is sent as query parameters or payload.
  final PaginationPayloadMode? paginationMode;

  /// The last parameters used in the API call, used for retry logic.
  Map<String, dynamic>? lastParams;

  /// Internal list holding the current items.
  final List<T> _items = [];

  /// Unmodifiable view of the current item list.
  List<T> get items => List.unmodifiable(_items);

  /// Returns the current state held by the [controller].
  PagyState<T> get state => controller.value;

  /// The type of API request being made. defaults to [PagyApiRequestType.get].
  final PagyApiRequestType requestType;

  /// Optional payload data to be sent with the request.
  /// This is applicable only for [PagyApiRequestType.post].
  /// It supports all data types that a POST request can handle.
  /// Use this to include additional data in the request body.
  final dynamic payloadData;

  /// List of observer callbacks to notify on state changes.
  final List<VoidCallback> _observers = [];

  /// Internal cancel token for API requests.
  CancelToken? _cancelToken;

final Map<String, dynamic>? headers;

  /// Constructor for [PagyController].
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

  /// Registers a new observer to be notified on state changes.
  void addObserver(VoidCallback observer) {
    _observers.add(observer);
  }

  /// Removes an existing observer.
  void removeObserver(VoidCallback observer) {
    _observers.remove(observer);
  }

  /// Notifies all registered observers.
  void _notifyObservers() {
    for (final observer in _observers) {
      observer();
    }
  }

  // ---------------------------------------------------------------------------
  // 🌀 Pagination logic
  // ---------------------------------------------------------------------------

  /// Loads data from the API.
  ///
  /// - [refresh] if true, fetches the first page and resets state.
  /// - [queryParameter] is merged with pagination and additional params.
  Future<void> loadData({
    bool refresh = true,
    Map<String, dynamic>? queryParameter,
    PaginationPayloadMode? paginationMode,

    /// Optional payload data to be sent with the request.
    /// This is applicable only for [PagyApiRequestType.post].
    /// It supports all data types that a POST request can handle.
    /// Use this to include additional data in the request body.
    dynamic payloadData,
  }) async {
    if (queryParameter != null) {
      _filter = queryParameter;
    } else if (queryParameter == null && refresh) {
      _filter = null;
    }

    final state = controller.value;

    if (state.isFetching || state.isMoreFetching) return;

    // ✅ Cancel any previous request
    _cancelToken?.cancel("Cancelled due to new request");
    _cancelToken = CancelToken();

    final int currentPage = refresh ? 1 : state.currentPage + 1;
    if (!refresh && currentPage > state.totalPages) return;

    controller.value = state.copyWith(
      isFetching: refresh,
      isMoreFetching: !refresh,
      errorMessage: '',
    );
    _notifyObservers();

    try {
      Map<String, dynamic> paginationParams = {
        if (PagyConfig().pageKey.isNotEmpty)
          PagyConfig().pageKey: currentPage.toString(),
        if (PagyConfig().limitKey?.isNotEmpty ?? false)
          PagyConfig().limitKey!: limit.toString(),
      };

      final Map<String, dynamic> allParams = {
        ...paginationParams,
        ...?additionalQueryParams,
        ...?queryParameter ?? _filter,
      };

      lastParams = allParams;

      final mode = paginationMode ?? PagyConfig().paginationMode;

      final dynamic response;

      if (requestType == PagyApiRequestType.post) {
        response = await NetworkApiService.instance.postApi(
          endPoints: endPoint,
          token: token,
headers:headers,
          queryParameter:
              mode == PaginationPayloadMode.queryParams ? allParams : null,
          data: mode == PaginationPayloadMode.payload
              ? {...allParams, ...?payloadData}
              : payloadData,
          isAuthorize: token != null,
          cancelToken: _cancelToken,
        );
      } else {
        response = await NetworkApiService.instance.getApi(
          endPoints: endPoint,
          token: token,
headers:headers,
          queryParameter:
              mode == PaginationPayloadMode.queryParams ? allParams : null,
          payload: mode == PaginationPayloadMode.payload ? allParams : null,
          isAuthorize: token != null,
          cancelToken: _cancelToken,
        );
      }

      if (responseMapper != null && response != null) {
        final parsed = responseMapper!(response);

        final List<T> newItems = [];
        for (int i = 0; i < parsed.list.length; i++) {
          try {
            final mappedItem = fromMap(parsed.list[i]);
            newItems.add(mappedItem);
          } catch (e, stack) {
            if (!kReleaseMode) {
              log("❌ Failed to parse item at index $i: ${parsed.list[i]}");
              log("Error: $e");
              log("Stack: $stack");
            }

            controller.value = state.copyWith(
              isFetching: false,
              isMoreFetching: false,
              errorMessage:
                  "⚠️ Parsing error on item $i. Please check your model or keys.",
            );
            _notifyObservers();
            return;
          }
        }

        if (refresh) {
          _items.clear();
        }
        _items.addAll(newItems);

        controller.value = state.copyWith(
          data: [..._items],
          currentPage: currentPage,
          totalPages: parsed.totalPages ?? 1,
          isFetching: false,
          isMoreFetching: false,
          errorMessage: '',
        );
        _notifyObservers();
      } else {
        throw Exception("⚠️ Empty or invalid response from server.");
      }
    } catch (e, stackTrace) {
      if (!kReleaseMode) {
        log("🚫 Unexpected error: $e");
        log("StackTrace: $stackTrace");
      }

      controller.value = state.copyWith(
        isFetching: false,
        isMoreFetching: false,
        errorMessage: e.toString(),
      );
      _notifyObservers();
    }
  }

  /// Retries the last failed data fetch using [lastParams].
  Future<void> retry() async {
    if (lastParams == null) return;
    controller.value = controller.value.copyWith(errorMessage: null);
    _notifyObservers();
    await loadData(refresh: controller.value.currentPage == 0);
  }

  /// Replaces the current items with [newData] and updates state.
  void updateData(List<T> newData) {
    _items
      ..clear()
      ..addAll(newData);

    controller.value = controller.value.copyWith(data: [..._items]);
    _notifyObservers();
  }

  /// Disposes the internal [ValueNotifier].
  void dispose() {
    controller.dispose();
  }

  // ---------------------------------------------------------------------------
  // 🧩 List modification helpers
  // ---------------------------------------------------------------------------

  /// Adds a single [item] to the list.
  ///
  /// - If [atStart] is true, adds to the beginning.
  void addItem(T item, {bool atStart = false}) {
    atStart ? _items.insert(0, item) : _items.add(item);

    controller.value = controller.value.copyWith(data: [..._items]);
    _notifyObservers();
  }

  /// Adds multiple [items] to the list.
  ///
  /// - If [atStart] is true, adds at the beginning.
  void addItems(List<T> items, {bool atStart = false}) {
    atStart ? _items.insertAll(0, items) : _items.addAll(items);

    controller.value = controller.value.copyWith(data: [..._items]);
    _notifyObservers();
  }

  /// Updates the item at [index] with [newItem].
  void updateItemAt(int index, T newItem) {
    if (index >= 0 && index < _items.length) {
      _items[index] = newItem;

      controller.value = controller.value.copyWith(data: [..._items]);
      _notifyObservers();
    }
  }

  /// Removes all items that satisfy the [test] condition.
  void removeWhere(bool Function(T item) test) {
    _items.removeWhere(test);

    controller.value = controller.value.copyWith(data: [..._items]);
    _notifyObservers();
  }

  /// Clears all items and resets pagination state.
  void clearItems() {
    _items.clear();

    controller.value = controller.value.copyWith(
      data: [],
      currentPage: 0,
      totalPages: 1,
    );
    _notifyObservers();
  }
}
