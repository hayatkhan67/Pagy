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
  }) async {
    // Store filter state
    if (queryParameter != null) {
      filter = queryParameter;
    } else if (queryParameter == null && refresh) {
      filter = null;
    }

    final state = controller.value;
    if (state.isFetching || state.isMoreFetching) return;

    // Cancel any ongoing request
    cancelToken?.cancel("Cancelled due to new request");
    cancelToken = CancelToken();

    // Determine next page
    final num currentPage = refresh ? 1 : state.currentPage + 1;
    if (!refresh && currentPage > state.totalPages) return;

    // Update loading state
    controller.value = state.copyWith(
      isFetching: refresh,
      isMoreFetching: !refresh,
      errorMessage: '',
    );

    try {
      final mode = paginationMode ?? PagyConfig().paginationMode;

      // Build request params
      final PagyParams params = PagyParams(
        endPoint: endPoint,
        requestType: requestType,
        limit: limit,
        page: currentPage,
        additionalQueryParams: additionalQueryParams,
        payloadData: payloadData,
        token: token,
        headers: headers,
        paginationMode: mode,
        cancelToken: cancelToken,
        queryParameter: queryParameter,
        fromMap: fromMap,
      );

      // Execute API call via DI use-case
      final Response response =
          await locator.get<GetPaginatedDataUseCase>().call(params);

      // Parse and map response
      if (responseMapper != null && response.data != null) {
        final parsed = responseMapper!(response.data);

        final List<T> newItems = [];
        for (int i = 0; i < parsed.list.length; i++) {
          try {
            final mappedItem = fromMap(parsed.list[i]);
            newItems.add(mappedItem);
          } catch (e, stack) {
            if (!kReleaseMode) {
              pagyLog("❌ Failed to parse item at index $i: ${parsed.list[i]}");
              pagyLog("Error: $e");
              pagyLog("Stack: $stack");
            }
            controller.value = state.copyWith(
              isFetching: false,
              isMoreFetching: false,
              errorMessage:
                  "⚠️ Parsing error on item $i. Please check your model or keys.",
            );
            return;
          }
        }

        // Replace or append items
        if (refresh) itemsList.clear();
        itemsList.addAll(newItems);

        // Update success state
        controller.value = state.copyWith(
          data: [...itemsList],
          currentPage: currentPage,
          totalPages: parsed.totalPages ?? 1,
          isFetching: false,
          isMoreFetching: false,
          errorMessage: '',
        );
      } else {
        throw Exception("⚠️ Empty or invalid response from server.");
      }
    } catch (e, stackTrace) {
      if (!kReleaseMode) {
        pagyLog("🚫 Unexpected error: $e");
        pagyLog("StackTrace: $stackTrace");
      }
      controller.value = state.copyWith(
        isFetching: false,
        isMoreFetching: false,
        errorMessage: e.toString(),
      );
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
    controller.value = controller.value.copyWith(errorMessage: null);
    await loadData(refresh: controller.value.currentPage == 0);
  }
}
