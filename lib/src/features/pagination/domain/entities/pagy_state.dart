/// Holds the current pagination state for Pagy.
class PagyState<T> {
  final bool isFetching;
  final bool isMoreFetching;
  final List<T> data;
  final num currentPage;
  final num totalPages;
  final String? errorMessage;

  PagyState({
    this.isFetching = false,
    this.isMoreFetching = false,
    this.data = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.errorMessage,
  });

  PagyState<T> copyWith({
    bool? isFetching,
    bool? isMoreFetching,
    List<T>? data,
    num? currentPage,
    num? totalPages,
    String? errorMessage,
  }) {
    return PagyState<T>(
      isFetching: isFetching ?? this.isFetching,
      isMoreFetching: isMoreFetching ?? this.isMoreFetching,
      data: data ?? this.data,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
