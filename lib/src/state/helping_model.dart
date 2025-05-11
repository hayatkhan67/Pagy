/// Model to hold the state of paginated data.
///
/// This class is used to represent the current state of the pagination process,
/// including loading status, current page, total pages, fetched data, and any errors.
class PagyState<T> {
  /// Indicates whether the initial data is being fetched.
  ///
  /// Set to `true` when the first page of data is loading.
  final bool isFetching;

  /// Indicates whether more data (next page) is being fetched.
  ///
  /// Set to `true` when loading subsequent pages during pagination.
  final bool isMoreFetching;

  /// The list of data items fetched so far.
  ///
  /// This contains all paginated items collected up to the current page.
  final List<T> data;

  /// The current page number in the pagination process.
  final int currentPage;

  /// The total number of pages available from the API.
  final int totalPages;

  /// An optional error message if an error occurs during fetching.
  final String? errorMessage;

  /// Creates a new [PagyState] instance.
  ///
  /// You can provide custom values for any field, or rely on defaults:
  /// - [isFetching]: Defaults to `false`
  /// - [isMoreFetching]: Defaults to `false`
  /// - [data]: Defaults to an empty list
  /// - [currentPage]: Defaults to `1`
  /// - [totalPages]: Defaults to `1`
  /// - [errorMessage]: Optional
  PagyState({
    this.isFetching = false,
    this.isMoreFetching = false,
    this.data = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.errorMessage,
  });

  /// Returns a copy of this [PagyState] with overridden values.
  ///
  /// Useful for updating specific fields while preserving others.
  PagyState<T> copyWith({
    bool? isFetching,
    bool? isMoreFetching,
    List<T>? data,
    int? currentPage,
    int? totalPages,
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
