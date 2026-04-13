part of 'pagy_controller.dart';

/// {@template pagy_controller_loader}
/// Extension on [PagyController] that adds API loading and retry functionality.
///
/// Handles:
/// - Refreshing data (reset to page `1`)
/// - Loading additional pages (infinite scroll)
/// - Request cancellation to prevent race conditions
/// - Safe JSON parsing with error handling
/// - Retry mechanism on failure
///
/// Used internally by `PagyListView` / `PagyGridView`, but can also be called
/// manually for custom flows.
/// {@endtemplate}
extension PagyControllerLoader<T> on PagyController<T> {
  /// Loads paginated data from the API.
  ///
  /// - When [refresh] is `true` (default), the list is cleared and starts
  ///   again from page 1.
  /// - When [refresh] is `false`, the next page of data is fetched and appended.
  ///
  /// Automatically updates [controller] state:
  /// - `isFetching` while refreshing
  /// - `isMoreFetching` while loading additional pages
  /// - `errorMessage` on failure
  ///
  /// ### Parameters:
  /// - [refresh]: Whether to refresh the list (default: `true`).
  /// - [queryParameter]: Custom filters or query params.
  /// - [paginationMode]: Override global [PaginationPayloadMode].
  /// - [payloadData]: Extra payload for POST/PUT requests.
  /// - [pageOverride]: Force a specific page number (used for retry).
  /// - [preserveFiltersOnRefresh]: Keep existing filters when refreshing.
  ///
  /// ### Example:
  /// ```dart
  /// await controller.loadData(refresh: true);
  /// await controller.loadData(refresh: false); // Load next page
  /// ```
  Future<void> loadData({
    bool refresh = true,
    Map<String, dynamic>? queryParameter,
    PaginationPayloadMode? paginationMode,
    dynamic payloadData,
    num? pageOverride,
    bool? preserveFiltersOnRefresh,
  }) async {
    final shouldPreserveFilters = preserveFiltersOnRefresh ??
        PagyConfig().preserveFiltersOnRefresh;

    // Store filter state
    if (queryParameter != null) {
      filter = queryParameter;
    } else if (queryParameter == null && refresh && !shouldPreserveFilters) {
      filter = null;
    }

    final state = controller.value;

    // Check pagination bounds for non-refresh requests
    final num currentPage =
        pageOverride ?? (refresh ? 1 : state.currentPage + 1);
    if (!refresh && currentPage > state.totalPages) return;

    // Cancel any existing request and create new token
    cancelToken?.cancel("New request initiated");
    final currentRequestToken = CancelToken();
    cancelToken = currentRequestToken;

    // Update loading state
    controller.value = state.copyWith(
      isFetching: refresh,
      isMoreFetching: !refresh,
      errorMessage: '',
      clearError: true,
    );

    try {
      final mode =
          paginationMode ?? _effectivePayloadMode ?? PagyConfig().payloadMode;

      final effectiveQueryParameter = queryParameter ?? filter;
      final effectivePayload = payloadData ?? this.payloadData;

      // Store last request parameters for retry
      lastParams = {
        'refresh': refresh,
        'page': currentPage,
        'queryParameter': effectiveQueryParameter,
        'paginationMode': mode,
        'payloadData': effectivePayload,
      };

      if (_usePageUseCase) {
        if (_effectiveResponseParser == null) {
          throw Exception(
            'responseParser is required when using the page use case.',
          );
        }

        final PagyPageParams<T> pageParams = PagyPageParams<T>(
          endPoint: endPoint,
          requestType: requestType,
          limit: limit,
          page: currentPage,
          additionalQueryParams: _effectiveQuery,
          payloadData: effectivePayload,
          token: token,
          headers: headers,
          paginationMode: mode,
          cancelToken: currentRequestToken,
          queryParameter: effectiveQueryParameter,
          responseParser: _effectiveResponseParser!,
          fromMap: fromMap,
        );

        final PagyPage<T> page =
            await _effectivePageUseCase.call(pageParams);

        // Verify request is still active
        if (currentRequestToken.isCancelled ||
            cancelToken != currentRequestToken) {
          return;
        }

        if (refresh) itemsList.clear();
        itemsList.addAll(page.items);

        final int resolvedTotalPages = _resolveTotalPages(
          totalPages: page.totalPages,
          totalItems: page.totalItems,
          hasMore: page.hasMore,
          currentPage: currentPage.toInt(),
          pageSize: limit,
          newItemsCount: page.items.length,
          assumeHasMore:
              PagyConfig().assumeHasMoreWhenTotalPagesNull,
        );

        controller.value = state.copyWith(
          data: [...itemsList],
          currentPage: currentPage,
          totalPages: resolvedTotalPages,
          isFetching: false,
          isMoreFetching: false,
          errorMessage: '',
          clearError: true,
        );
        return;
      }

      // Build request params (legacy path)
      final PagyParams params = PagyParams(
        endPoint: endPoint,
        requestType: requestType,
        limit: limit,
        page: currentPage,
        additionalQueryParams: _effectiveQuery,
        payloadData: effectivePayload,
        token: token,
        headers: headers,
        paginationMode: mode,
        cancelToken: currentRequestToken,
        queryParameter: effectiveQueryParameter,
        fromMap: fromMap,
      );

      // Execute API call
      final Response response = await _effectiveUseCase.call(params);

      // Verify request is still active
      if (currentRequestToken.isCancelled ||
          cancelToken != currentRequestToken) {
        return;
      }

      // Parse response
      if (_effectiveResponseParser != null && response.data != null) {
        final parsed = _effectiveResponseParser!(response.data);
        final List<T> newItems = [];

        // Map items with error handling
        for (int i = 0; i < parsed.list.length; i++) {
          try {
            newItems.add(fromMap(parsed.list[i]));
          } catch (e, stackTrace) {
            if (!kReleaseMode) {
              pagyLog("Failed to parse item at index $i: $e\n$stackTrace");
            }

            // Only update state if request is still active
            if (cancelToken == currentRequestToken &&
                !currentRequestToken.isCancelled) {
              final parseError = PagyError.malformedResponse(
                message:
                    "Parsing error on item $i. Please check your model or keys.",
                stackTrace: stackTrace,
              );
              controller.value = state.copyWith(
                isFetching: false,
                isMoreFetching: false,
                error: parseError,
                errorMessage: parseError.message,
              );
            }
            return;
          }
        }

        // Final validation and state update
        if (cancelToken == currentRequestToken &&
            !currentRequestToken.isCancelled) {
          if (refresh) itemsList.clear();
          itemsList.addAll(newItems);

          final int resolvedTotalPages = _resolveTotalPages(
            totalPages: parsed.totalPages,
            totalItems: parsed.totalItems,
            hasMore: parsed.hasMore,
            currentPage: currentPage.toInt(),
            pageSize: limit,
            newItemsCount: newItems.length,
            assumeHasMore:
                PagyConfig().assumeHasMoreWhenTotalPagesNull,
          );

          controller.value = state.copyWith(
            data: [...itemsList],
            currentPage: currentPage,
            totalPages: resolvedTotalPages,
            isFetching: false,
            isMoreFetching: false,
            errorMessage: '',
            clearError: true,
          );
        }
      } else {
        throw Exception("Empty or invalid response from server.");
      }
    } catch (e, stackTrace) {
      // Handle cancellation
      if (e is DioException && CancelToken.isCancel(e)) {
        return;
      }

      // Handle other errors only if request is still active
      if (cancelToken == currentRequestToken &&
          !currentRequestToken.isCancelled) {
        if (!kReleaseMode) {
          pagyLog(
            "API error: $e \n$stackTrace",
          );
        }
        final pagyError = _toPagyError(e, stackTrace);
        controller.value = state.copyWith(
          isFetching: false,
          isMoreFetching: false,
          error: pagyError,
          errorMessage: pagyError.message,
        );
      }
    }
  }

  /// Retries the last failed request if parameters exist.
  ///
  /// Restores [errorMessage] to `null` before retrying.
  ///
  /// ### Example:
  /// ```dart
  /// await controller.retry();
  /// ```
  Future<void> retry() async {
    if (lastParams == null) return;

    final params = lastParams!;
    final refresh = params['refresh'] as bool? ?? true;
    final page = params['page'] as num?;
    final queryParameter =
        params['queryParameter'] as Map<String, dynamic>?;
    final paginationMode = params['paginationMode'] as PaginationPayloadMode?;
    final payloadData = params['payloadData'];

    controller.value = controller.value.copyWith(
      errorMessage: '',
      clearError: true,
    );
    await loadData(
      refresh: refresh,
      queryParameter: queryParameter,
      paginationMode: paginationMode,
      payloadData: payloadData,
      pageOverride: page,
    );
  }
}

int _resolveTotalPages({
  required int currentPage,
  required int pageSize,
  required int newItemsCount,
  required bool assumeHasMore,
  int? totalPages,
  int? totalItems,
  bool? hasMore,
}) {
  if (totalPages != null) return totalPages;
  if (totalItems != null && pageSize > 0) {
    return (totalItems / pageSize).ceil();
  }
  if (hasMore != null) {
    return hasMore ? currentPage + 1 : currentPage;
  }
  if (assumeHasMore) {
    return newItemsCount == 0 ? currentPage : currentPage + 1;
  }
  return currentPage;
}

PagyError _toPagyError(Object e, [StackTrace? stackTrace]) {
  if (e is PagyError) {
    return stackTrace != null ? e.copyWith(stackTrace: stackTrace) : e;
  }
  if (e is DioException) {
    return PagyError.fromDioException(
      e,
      stackTrace: stackTrace,
    );
  }
  if (e is String) {
    return PagyError.unknown(message: e, stackTrace: stackTrace);
  }
  return PagyError.unknown(
    message: e.toString(),
    exception: e,
    stackTrace: stackTrace,
  );
}
