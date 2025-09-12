import '../../presentation/controllers/pagy_controller.dart';

/// Holds the current pagination state for Pagy.
///
/// `PagyState` is an immutable data holder that represents
/// the complete state of a paginated list at any given time.
/// It is used internally by [PagyController] but can also be
/// accessed externally for building UI based on pagination status.
///
/// ### Properties:
/// - [isFetching]: Indicates if the initial data is being loaded.
/// - [isMoreFetching]: Indicates if additional pages are being loaded.
/// - [data]: The list of items currently loaded.
/// - [currentPage]: The current page number.
/// - [totalPages]: The total number of pages available.
/// - [errorMessage]: Any error message from the last request (if any).
///
/// ### Example:
/// ```dart
/// if (state.isFetching) {
///   return const CircularProgressIndicator();
/// }
/// if (state.errorMessage != null) {
///   return Text('Error: ${state.errorMessage}');
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
/// Typically, you won’t create a `PagyState` directly. Instead,
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

  /// The error message (if any) from the last fetch.
  ///
  /// Will be `null` if there is no error.
  final String? errorMessage;

  /// Creates a new [PagyState] instance.
  ///
  /// Typically, you won’t need to use this directly—
  /// the controller will handle state creation.
  PagyState({
    this.isFetching = false,
    this.isMoreFetching = false,
    this.data = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.errorMessage,
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
