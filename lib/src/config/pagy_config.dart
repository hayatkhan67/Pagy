import 'package:flutter/material.dart';
import '../enum/pagy_enum.dart';

class PagyConfig {
  static final PagyConfig _instance = PagyConfig._internal();
  factory PagyConfig() => _instance;
  PagyConfig._internal();

  String baseUrl = '';
  String pageKey = 'page';
  String? limitKey;
  double scrollOffset = 200;
  bool apiLogs = true;
  PaginationPayloadMode paginationMode = PaginationPayloadMode.queryParams;

  /// Global widget overrides
  Widget Function(String errorMessage, VoidCallback onRetry)?
      globalErrorBuilder;
  Widget Function(VoidCallback onRetry)? globalEmptyBuilder;
  Widget? globalLoader;

  void initialize({
    required String baseUrl,
    String pageKey = 'page',
    String? limitKey,
    double scrollOffset = 200,
    bool apiLogs = true,
    PaginationPayloadMode paginationMode = PaginationPayloadMode.queryParams,

    /// Optional widget overrides (new)
    Widget Function(String errorMessage, VoidCallback onRetry)? errorBuilder,
    Widget Function(VoidCallback onRetry)? emptyBuilder,
    Widget? loader,
  }) {
    this.baseUrl = baseUrl;
    this.pageKey = pageKey;
    this.limitKey = limitKey;
    this.scrollOffset = scrollOffset;
    this.paginationMode = paginationMode;
    this.apiLogs = apiLogs;

    // Assign global widgets if provided
    globalErrorBuilder = errorBuilder;
    globalEmptyBuilder = emptyBuilder;
    globalLoader = loader;
  }
}
