part of 'pagy_controller.dart';

extension PagyControllerLoader<T> on PagyController<T> {
  Future<void> loadData({
    bool refresh = true,
    Map<String, dynamic>? queryParameter,
    PaginationPayloadMode? paginationMode,
    dynamic payloadData,
  }) async {
    pagyLog(
        "🚀 loadData called with refresh: $refresh, queryParameter: $queryParameter");

    // Store filter state
    if (queryParameter != null) {
      filter = queryParameter;
    } else if (queryParameter == null && refresh) {
      filter = null;
    }

    final state = controller.value;

    // REMOVED: The problematic early return that was preventing cancellation
    // if (state.isFetching || state.isMoreFetching) return;

    // Determine next page
    final num currentPage = refresh ? 1 : state.currentPage + 1;
    if (!refresh && currentPage > state.totalPages) {
      pagyLog("📄 No more pages to load");
      return;
    }

    // Always cancel existing request first (MOVED BEFORE state check)
    if (cancelToken != null) {
      pagyLog("❌ Cancelling existing request");
      cancelToken!.cancel("New request initiated");
    } else {
      pagyLog("✅ No existing request to cancel");
    }

    // Create new cancel token
    final currentRequestToken = CancelToken();
    cancelToken = currentRequestToken;
    pagyLog("🔄 Created new cancel token: ${currentRequestToken.hashCode}");

    // Update loading state (always update, even if we were already fetching)
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
        cancelToken: currentRequestToken,
        queryParameter: queryParameter,
        fromMap: fromMap,
      );

      pagyLog("🌐 Making API call with token: ${currentRequestToken.hashCode}");

      // Execute API call via DI use-case
      final Response response =
          await locator.get<GetPaginatedDataUseCase>().call(params);

      pagyLog(
          "✅ API call completed with token: ${currentRequestToken.hashCode}");

      // Check if request was cancelled during execution
      if (currentRequestToken.isCancelled) {
        pagyLog(
            "🛑 Token ${currentRequestToken.hashCode} was cancelled during execution");
        return;
      }

      // Check if this is still the active request
      if (cancelToken != currentRequestToken) {
        pagyLog(
            "🛑 Token ${currentRequestToken.hashCode} is no longer active, current: ${cancelToken?.hashCode}");
        return;
      }

      pagyLog(
          "🎯 Processing response for token: ${currentRequestToken.hashCode}");

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
            }

            // Only update state if this request is still active
            if (cancelToken == currentRequestToken &&
                !currentRequestToken.isCancelled) {
              controller.value = state.copyWith(
                isFetching: false,
                isMoreFetching: false,
                errorMessage:
                    "⚠️ Parsing error on item $i. Please check your model or keys.",
              );
            }
            return;
          }
        }

        // Final check before updating state
        if (cancelToken == currentRequestToken &&
            !currentRequestToken.isCancelled) {
          pagyLog(
              "📝 Updating state with ${newItems.length} items for token: ${currentRequestToken.hashCode}");

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
          pagyLog(
              "🛑 Skipping state update - token ${currentRequestToken.hashCode} is no longer active");
        }
      } else {
        throw Exception("⚠️ Empty or invalid response from server.");
      }
    } catch (e, stackTrace) {
      pagyLog("💥 Exception caught: $e");

      // Handle cancellation
      if (e is DioException && CancelToken.isCancel(e)) {
        pagyLog(
            "🛑 DioException - Request was cancelled: ${currentRequestToken.hashCode}");
        return;
      }

      // Handle other errors - but only if request is still active
      if (cancelToken == currentRequestToken &&
          !currentRequestToken.isCancelled) {
        pagyLog(
            "🚫 Updating error state for token: ${currentRequestToken.hashCode}");
        if (!kReleaseMode) {
          pagyLog("🚫 Unexpected error: $e");
        }
        controller.value = state.copyWith(
          isFetching: false,
          isMoreFetching: false,
          errorMessage: e.toString(),
        );
      } else {
        pagyLog(
            "🛑 Ignoring error for cancelled token: ${currentRequestToken.hashCode}");
      }
    }
  }

  Future<void> retry() async {
    if (lastParams == null) return;
    controller.value = controller.value.copyWith(errorMessage: null);
    await loadData(refresh: controller.value.currentPage == 0);
  }
}
