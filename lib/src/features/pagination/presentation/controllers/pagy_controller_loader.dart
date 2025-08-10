part of 'pagy_controller.dart';

extension PagyControllerLoader<T> on PagyController<T> {
  Future<void> loadData({
    bool refresh = true,
    Map<String, dynamic>? queryParameter,
    PaginationPayloadMode? paginationMode,
    dynamic payloadData,
  }) async {
    if (queryParameter != null) {
      filter = queryParameter;
    } else if (queryParameter == null && refresh) {
      filter = null;
    }

    final state = controller.value;
    if (state.isFetching || state.isMoreFetching) return;

    cancelToken?.cancel("Cancelled due to new request");
    cancelToken = CancelToken();

    final num currentPage = refresh ? 1 : state.currentPage + 1;
    if (!refresh && currentPage > state.totalPages) return;

    controller.value = state.copyWith(
      isFetching: refresh,
      isMoreFetching: !refresh,
      errorMessage: '',
    );

    try {
      // lastParams = allParams;
      final mode = paginationMode ?? PagyConfig().paginationMode;

      final Response? response;
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
          fromMap: fromMap);
      response = await locator.get<GetPaginatedDataUseCase>().call(params);

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

        if (refresh) itemsList.clear();
        itemsList.addAll(newItems);

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

  Future<void> retry() async {
    if (lastParams == null) return;
    controller.value = controller.value.copyWith(errorMessage: null);
    await loadData(refresh: controller.value.currentPage == 0);
  }
}
