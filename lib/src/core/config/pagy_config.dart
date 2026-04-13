import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../features/pagination/domain/enums/pagy_enum.dart';
import '../../features/pagination/data/datasources/network_api_service.dart';
import '../services/dependency_injections.dart';
import '../errors/pagy_error.dart';
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

  /// Whether refresh calls should preserve existing filters by default.
  ///
  /// Defaults to `false` to preserve previous behavior.
  bool preserveFiltersOnRefresh = true;

  /// Whether to assume more pages exist when totalPages is missing.
  ///
  /// When enabled and totalPages/hasMore/totalItems are not provided,
  /// Pagy will keep paginating until an empty page is returned.
  ///
  /// Defaults to `false` to preserve previous behavior.
  bool assumeHasMoreWhenTotalPagesNull = false;

  /// Whether to enable Pagy API logs.
  ///
  /// **Deprecated:** Use [enableLogs] instead for clarity.
  ///
  /// Defaults to `true`.
  @Deprecated('Use enableLogs instead. Will be removed in v2.0.0')
  bool apiLogs = true;

  /// Whether to enable logging for debugging.
  ///
  /// Defaults to `true`.
  bool enableLogs = true;

  /// Mode for sending pagination data.
  ///
  /// **Deprecated:** Use [payloadMode] instead for consistency.
  ///
  /// Can be `PaginationPayloadMode.queryParams` or
  /// `PaginationPayloadMode.payload`.
  @Deprecated('Use payloadMode instead. Will be removed in v2.0.0')
  PaginationPayloadMode paginationMode = PaginationPayloadMode.queryParams;

  /// Mode for sending pagination parameters (query string or request body).
  ///
  /// Can be `PaginationPayloadMode.queryParams` or
  /// `PaginationPayloadMode.payload`.
  PaginationPayloadMode payloadMode = PaginationPayloadMode.queryParams;

  /// Optional Dio [Interceptor] for customizing request/response handling.
  Interceptor? dioInterceptor;

  /// Global error widget builder.
  ///
  /// Used when no custom error UI is provided for a controller.
  Widget Function(PagyError error, VoidCallback onRetry)?
      globalErrorBuilder;

  /// Global empty state widget builder.
  Widget Function(VoidCallback onRetry)? globalEmptyBuilder;

  /// Global empty state message.
  ///
  /// Used when no custom empty state builder is provided.
  /// Defaults to `'No data available'`.
  String globalEmptyMessage = 'No data available';

  /// Global empty state icon.
  ///
  /// Displayed above the message. If `null`, no icon is shown.
  IconData? globalEmptyIcon;

  /// Global setting for showing retry button on empty state.
  ///
  /// Defaults to `true`.
  bool globalShowEmptyRetryButton = true;

  /// Global setting for enabling RefreshIndicator on empty state.
  ///
  /// When `true`, empty state is wrapped in a RefreshIndicator.
  /// Defaults to `false`.
  bool globalEnableRefreshOnEmpty = false;

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
    bool? preserveFiltersOnRefresh,
    bool? assumeHasMoreWhenTotalPagesNull,
    @Deprecated('Use enableLogs instead') bool? apiLogs,
    bool? enableLogs,
    @Deprecated('Use payloadMode instead')
    PaginationPayloadMode? paginationMode,
    PaginationPayloadMode? payloadMode,
    Widget Function(PagyError error, VoidCallback onRetry)? errorBuilder,
    Widget Function(VoidCallback onRetry)? emptyBuilder,
    String? emptyMessage,
    IconData? emptyIcon,
    bool? showEmptyRetryButton,
    bool? enableRefreshOnEmpty,
    Widget? loader,
    Interceptor? interceptor,
    PagyLogger? customLogger,
  }) {
    if (_initialized) return; // prevent duplicate init

    // Runtime validation (asserts are stripped in release)
    if (baseUrl != null && baseOptions != null) {
      throw ArgumentError(
        'Provide only one: baseUrl or baseOptions. '
        'You cannot specify both at the same time.',
      );
    }
    if (baseUrl == null && baseOptions == null) {
      throw ArgumentError(
        'Either baseUrl or baseOptions must be provided. '
        'Pagy needs an API endpoint to function.',
      );
    }

    // Validation assertions
    assert(
      baseUrl == null || baseOptions == null,
      '❌ Provide only one: baseUrl or baseOptions.\n'
      'You cannot specify both at the same time.',
    );
    assert(
      baseUrl != null || baseOptions != null,
      '❌ Either baseUrl or baseOptions must be provided.\n'
      'Pagy needs an API endpoint to function.',
    );

    // Validate baseUrl if provided
    if (baseUrl != null) {
      assert(
        baseUrl.startsWith('http://') || baseUrl.startsWith('https://'),
        '❌ baseUrl must start with http:// or https://\n'
        'Got: "$baseUrl"\n'
        'Example: "https://api.example.com/"',
      );

      // Warn about missing trailing slash
      if (!baseUrl.endsWith('/')) {
        logger(
          '⚠️  baseUrl should typically end with / for proper endpoint concatenation\n'
          'Current: "$baseUrl"\n'
          'Recommended: "$baseUrl/"\n'
          'This may cause issues if your endpoints don\' start with /',
          name: 'Pagy Warning',
        );
      }

      this.baseUrl = baseUrl;
    } else {
      this.baseOptions = baseOptions;
    }

    // Validate scrollOffset
    assert(
      scrollOffset > 0,
      '❌ scrollOffset must be greater than 0\n'
      'Got: $scrollOffset\n'
      'Typical values are between 100-300 pixels',
    );

    this.pageKey = pageKey;
    this.limitKey = limitKey;
    this.scrollOffset = scrollOffset;
    if (preserveFiltersOnRefresh != null) {
      this.preserveFiltersOnRefresh = preserveFiltersOnRefresh;
    }
    if (assumeHasMoreWhenTotalPagesNull != null) {
      this.assumeHasMoreWhenTotalPagesNull = assumeHasMoreWhenTotalPagesNull;
    }

    // Handle both old and new parameters
    // ignore: deprecated_member_use_from_same_package
    this.payloadMode =
        payloadMode ?? paginationMode ?? PaginationPayloadMode.queryParams;
    // ignore: deprecated_member_use_from_same_package
    this.paginationMode =
        this.payloadMode; // Keep in sync for backward compatibility

    // ignore: deprecated_member_use_from_same_package
    this.enableLogs = enableLogs ?? apiLogs ?? true;
    // ignore: deprecated_member_use_from_same_package
    this.apiLogs = this.enableLogs; // Keep in sync for backward compatibility

    globalErrorBuilder = errorBuilder;
    globalEmptyBuilder = emptyBuilder;
    if (emptyMessage != null) globalEmptyMessage = emptyMessage;
    globalEmptyIcon = emptyIcon;
    if (showEmptyRetryButton != null) {
      globalShowEmptyRetryButton = showEmptyRetryButton;
    }
    if (enableRefreshOnEmpty != null) {
      globalEnableRefreshOnEmpty = enableRefreshOnEmpty;
    }
    globalLoader = loader;
    dioInterceptor = interceptor;

    if (customLogger != null) {
      logger = customLogger;
    }

    // Rebuild network client with latest config (handles early initialization).
    NetworkApiService.instance.refreshConfig();

    _setupDependencies();
    _initialized = true;

    // Log successful initialization
    if (this.enableLogs) {
      logger(
        '✅ Pagy initialized successfully\n'
        'Base URL: ${this.baseUrl.isNotEmpty ? this.baseUrl : "(using BaseOptions)"}\n'
        'Page Key: $pageKey\n'
        'Limit Key: ${limitKey ?? "(not set)"}\n'
        'Payload Mode: ${this.payloadMode}',
        name: 'Pagy Init',
      );
    }
  }

  /// Ensures Pagy has been initialized.
  ///
  /// If not, applies default values and sets up dependencies.
  void ensureInitialized({bool allowUnconfigured = true}) {
    if (_initialized) return;

    _setupDependencies();

    // If config is missing, do not lock initialization.
    if (baseUrl.isEmpty && baseOptions == null) {
      if (!allowUnconfigured) {
        throw StateError(
          'Pagy is not configured. Call PagyConfig().initialize(...) before use.',
        );
      }
      debugPrint('[Pagy] Default config applied (unconfigured)');
      return;
    }

    _initialized = true;
  }

  /// Sets up service locator dependencies.
  void _setupDependencies() {
    setup(); // custom DI setup function
  }
}
