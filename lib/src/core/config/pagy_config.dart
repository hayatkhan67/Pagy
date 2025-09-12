import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../features/pagination/domain/enums/pagy_enum.dart';
import '../services/dependency_injections.dart';
import '../utils/pagy_utils.dart';

/// Global configuration class for the Pagy package.
///
/// Use this to define defaults for API behavior, pagination keys,
/// error handling widgets, and logging across your app.
///
/// Example:
/// ```dart
/// PagyConfig().initialize(
///   baseUrl: 'https://api.example.com',
///   pageKey: 'page',
///   limitKey: 'limit',
///   apiLogs: true,
///   paginationMode: PaginationPayloadMode.queryParams,
///   errorBuilder: (msg, retry) => ErrorView(msg: msg, onRetry: retry),
///   emptyBuilder: (retry) => EmptyView(onRetry: retry),
///   loader: const Center(child: CircularProgressIndicator()),
/// );
/// ```
class PagyConfig {
  /// Singleton instance of [PagyConfig].
  static final PagyConfig _instance = PagyConfig._internal();

  /// Factory constructor to return the singleton instance.
  factory PagyConfig() => _instance;

  PagyConfig._internal();

  /// Whether [initialize] has already been called.
  bool _initialized = false;

  /// Base API URL. Used if [baseOptions] is not provided.
  String baseUrl = '';

  /// Optional Dio [BaseOptions] for more granular API configuration.
  BaseOptions? baseOptions;

  /// Key name used to represent the page number in requests.
  ///
  /// Defaults to `'page'`.
  String pageKey = 'page';

  /// Key name used to represent the page size/limit in requests.
  ///
  /// Optional, may be null depending on your API.
  String? limitKey;

  /// Scroll offset threshold (in pixels) before triggering pagination load.
  ///
  /// Defaults to `200`.
  double scrollOffset = 200;

  /// Whether to enable Pagy API logs.
  ///
  /// Defaults to `true`.
  bool apiLogs = true;

  /// Mode for sending pagination data.
  ///
  /// Can be `PaginationPayloadMode.queryParams` or
  /// `PaginationPayloadMode.payload`.
  PaginationPayloadMode paginationMode = PaginationPayloadMode.queryParams;

  /// Optional Dio [Interceptor] for customizing request/response handling.
  Interceptor? dioInterceptor;

  /// Global error widget builder.
  ///
  /// Used when no custom error UI is provided for a controller.
  Widget Function(String errorMessage, VoidCallback onRetry)?
      globalErrorBuilder;

  /// Global empty state widget builder.
  Widget Function(VoidCallback onRetry)? globalEmptyBuilder;

  /// Global loader widget.
  Widget? globalLoader;

  /// Logger for API/debug messages.
  ///
  /// Defaults to [defaultPagyLogger] but can be overridden
  /// via [initialize].
  PagyLogger logger = defaultPagyLogger;

  /// Initializes the [PagyConfig] with custom values.
  ///
  /// Must be called **once** before using any Pagy controllers.
  ///
  /// If already initialized, calling this method again has no effect.
  void initialize({
    String? baseUrl,
    BaseOptions? baseOptions,
    String pageKey = 'page',
    String? limitKey,
    double scrollOffset = 200,
    bool apiLogs = true,
    PaginationPayloadMode paginationMode = PaginationPayloadMode.queryParams,
    Widget Function(String errorMessage, VoidCallback onRetry)? errorBuilder,
    Widget Function(VoidCallback onRetry)? emptyBuilder,
    Widget? loader,
    Interceptor? interceptor,
    PagyLogger? customLogger,
  }) {
    if (_initialized) return; // prevent duplicate init

    assert(
      baseUrl == null || baseOptions == null,
      'Provide only one: baseUrl or baseOptions.',
    );
    assert(
      baseUrl != null || baseOptions != null,
      'Either baseUrl or baseOptions must be provided.',
    );

    if (baseUrl != null) {
      this.baseUrl = baseUrl;
    } else {
      this.baseOptions = baseOptions;
    }

    this.pageKey = pageKey;
    this.limitKey = limitKey;
    this.scrollOffset = scrollOffset;
    this.paginationMode = paginationMode;
    this.apiLogs = apiLogs;

    globalErrorBuilder = errorBuilder;
    globalEmptyBuilder = emptyBuilder;
    globalLoader = loader;
    dioInterceptor = interceptor;

    if (customLogger != null) {
      logger = customLogger;
    }

    _setupDependencies();
    _initialized = true;
  }

  /// Ensures Pagy has been initialized.
  ///
  /// If not, applies default values and sets up dependencies.
  void ensureInitialized() {
    if (!_initialized) {
      debugPrint('[Pagy] Default config applied');
      _setupDependencies();
      _initialized = true;
    }
  }

  /// Sets up service locator dependencies.
  void _setupDependencies() {
    setup(); // custom DI setup function
  }
}
