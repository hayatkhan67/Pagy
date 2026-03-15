import '../../../../core/errors/pagy_error.dart';

/// Holds the current pagination state for Pagy.
///
/// `PagyState` is an immutable data holder that represents
/// the complete state of a paginated list at any given time.
  /// It is used internally by the pagination controller but can also be
/// accessed externally for building UI based on pagination status.
///
/// ### Properties:
/// - [isFetching]: Indicates if the initial data is being loaded.
/// - [isMoreFetching]: Indicates if additional pages are being loaded.
/// - [data]: The list of items currently loaded.
/// - [currentPage]: The current page number.
/// - [totalPages]: The total number of pages available.
/// - [error]: Detailed error information (recommended).
/// - [errorMessage]: Simple error message (deprecated, use [error] instead).
///
/// ### Example:
/// ```dart
/// if (state.isFetching) {
///   return const CircularProgressIndicator();
/// }
/// if (state.error != null) {
///   return ErrorWidget(
///     message: state.error!.message,
///     suggestion: state.error!.suggestion,
///     onRetry: controller.retry,
///   );
/// }
/// return ListView.builder(
///   itemCount: state.data.length,
///   itemBuilder: (context, index) {
///     final item = state.data[index];
///     return Text(item.toString());
///   },
/// );
/// ```
///
/// Typically, you won't create a `PagyState` directly. Instead,
/// it is managed by `PagyController` and exposed through its state
/// stream or notifier.
class PagyState<T> {
  /// Whether the initial page is being fetched.
  final bool isFetching;

  /// Whether additional pages (load more) are being fetched.
  final bool isMoreFetching;

  /// The list of paginated items currently loaded.
  final List<T> data;

  /// The current page number in pagination.
  ///
  /// Defaults to `1`.
  final num currentPage;

  /// The total number of available pages.
  ///
  /// Defaults to `1`.
  final num totalPages;

  /// Detailed error information from the last fetch.
  ///
  /// Contains error type, message, suggestions, and status code.
  /// Use this for better error handling and user feedback.
  final PagyError? error;

  /// Simple error message from the last fetch.
  ///
  /// **Deprecated:** Use [error] instead for more detailed error information.
  @Deprecated('Use error.message instead. Will be removed in v2.0.0')
  final String? errorMessage;

  /// Creates a new [PagyState] instance.
  ///
  /// Typically, you won't need to use this directly—
  /// the controller will handle state creation.
  PagyState({
    this.isFetching = false,
    this.isMoreFetching = false,
    this.data = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.error,
    @Deprecated('Use error instead') this.errorMessage,
  });

  /// Returns a new [PagyState] with updated values.
  ///
  /// This is used to maintain immutability while updating
  /// only specific properties of the state.
  PagyState<T> copyWith({
    bool? isFetching,
    bool? isMoreFetching,
    List<T>? data,
    num? currentPage,
    num? totalPages,
    PagyError? error,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PagyState<T>(
      isFetching: isFetching ?? this.isFetching,
      isMoreFetching: isMoreFetching ?? this.isMoreFetching,
      data: data ?? this.data,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      error: clearError ? null : (error ?? this.error),
      // ignore: deprecated_member_use_from_same_package
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
