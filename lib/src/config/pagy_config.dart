import '../enum/pagy_enum.dart';

/// Global configuration class for Pagy package.
///
/// Use [PagyConfig.initialize] at the start of your app to set global settings
/// for API pagination. You can retrieve the singleton instance using `PagyConfig()`.
///
/// Example:
/// ```dart
/// PagyConfig().initialize(
///   baseUrl: 'https://api.example.com',
///   pageKey: 'pageNumber',
///   limitKey: 'limit',
///   scrollOffset: 150,
///   apiLogs: true,
///   paginationMode: PaginationMode.queryParams,
/// );
/// ```
class PagyConfig {
  /// Singleton instance of [PagyConfig].
  static final PagyConfig _instance = PagyConfig._internal();

  /// Returns the singleton instance of [PagyConfig].
  ///
  /// This factory constructor ensures that only one instance of [PagyConfig]
  /// is used throughout the app.
  factory PagyConfig() => _instance;

  /// Private constructor for internal singleton implementation.
  PagyConfig._internal();

  /// The base URL used in all API calls for pagination.
  ///
  /// This should be set using [initialize] before calling any API-related method.
  String baseUrl = '';

  /// The key used for the page number in API requests.
  ///
  /// Default is `'page'`. Change it if your API expects a different key like `'pageNumber'`.
  String pageKey = 'page';

  /// Optional key used to indicate the number of items per page.
  ///
  /// Useful if your API accepts a `limit`, `per_page`, or similar parameter.
  String? limitKey;

  /// The scroll distance (in pixels) from the bottom of the list that triggers loading the next page.
  ///
  /// Default is `200`. This allows for prefetching data before reaching the end.
  double scrollOffset = 200;

  /// Enables or disables logging of API requests and responses.
  ///
  /// Default is `true`. Set to `false` to silence log output.
  bool apiLogs = true;

  /// Defines how pagination parameters are sent: via query parameters or payload.
  ///
  /// Default is [PaginationPayloadMode.queryParams].
  PaginationPayloadMode paginationMode = PaginationPayloadMode.queryParams;

  /// Initializes the global Pagy configuration.
  ///
  /// Call this method once at the beginning of your app (e.g., in `main()` or before API usage).
  ///
  /// Parameters:
  /// - [baseUrl]: The base URL for all paginated API calls.
  /// - [pageKey]: The key to be used for pagination page number (default is `'page'`).
  /// - [limitKey]: Optional key for items per page (e.g., `'limit'`, `'per_page'`).
  /// - [scrollOffset]: Distance from the bottom of the list to trigger loading (default is `200`).
  /// - [apiLogs]: Enable or disable logging for debugging (default is `true`).
  /// - [paginationMode]: Choose between query parameters or payload mode for sending pagination data.
  void initialize({
    required String baseUrl,
    String pageKey = 'page',
    String? limitKey,
    double scrollOffset = 200,
    bool apiLogs = true,
    PaginationPayloadMode paginationMode = PaginationPayloadMode.queryParams,
  }) {
    this.baseUrl = baseUrl;
    this.pageKey = pageKey;
    this.limitKey = limitKey;
    this.scrollOffset = scrollOffset;
    this.paginationMode = paginationMode;
    this.apiLogs = apiLogs;
  }
}
