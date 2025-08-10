import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../features/pagination/domain/enums/pagy_enum.dart';
import '../services/dependency_injections.dart';

class PagyConfig {
  static final PagyConfig _instance = PagyConfig._internal();
  factory PagyConfig() => _instance;
  PagyConfig._internal();

  String baseUrl = '';
  BaseOptions? baseOptions;
  String pageKey = 'page';
  String? limitKey;
  double scrollOffset = 200;
  bool apiLogs = true;
  PaginationPayloadMode paginationMode = PaginationPayloadMode.queryParams;
  Interceptor? dioInterceptor;

  /// Global widget overrides
  Widget Function(String errorMessage, VoidCallback onRetry)?
      globalErrorBuilder;
  Widget Function(VoidCallback onRetry)? globalEmptyBuilder;
  Widget? globalLoader;

  void initialize({
    String? baseUrl,
    BaseOptions? baseOptions,
    String pageKey = 'page',
    String? limitKey,
    double scrollOffset = 200,
    bool apiLogs = true,
    PaginationPayloadMode paginationMode = PaginationPayloadMode.queryParams,

    // Optional widget overrides
    Widget Function(String errorMessage, VoidCallback onRetry)? errorBuilder,
    Widget Function(VoidCallback onRetry)? emptyBuilder,
    Widget? loader,

    // Custom Dio Interceptor
    Interceptor? interceptor,
  }) {
    // Assert rule: only one of baseUrl or baseOptions can be used
    assert(
      baseUrl == null || baseOptions == null,
      'You cannot provide both baseUrl and baseOptions. Provide only one.',
    );

    // Also ensure at least one is provided
    assert(
      baseUrl != null || baseOptions != null,
      'You must provide either baseUrl or baseOptions.',
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
    setup();
  }
}
