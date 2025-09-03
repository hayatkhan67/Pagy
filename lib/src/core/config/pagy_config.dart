import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../features/pagination/domain/enums/pagy_enum.dart';
import '../services/dependency_injections.dart';

class PagyConfig {
  static final PagyConfig _instance = PagyConfig._internal();
  factory PagyConfig() => _instance;
  PagyConfig._internal();

  bool _initialized = false;

  String baseUrl = '';
  BaseOptions? baseOptions;
  String pageKey = 'page';
  String? limitKey;
  double scrollOffset = 200;
  bool apiLogs = true;
  PaginationPayloadMode paginationMode = PaginationPayloadMode.queryParams;
  Interceptor? dioInterceptor;

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
    Widget Function(String errorMessage, VoidCallback onRetry)? errorBuilder,
    Widget Function(VoidCallback onRetry)? emptyBuilder,
    Widget? loader,
    Interceptor? interceptor,
  }) {
    if (_initialized) return; // avoid multiple hits

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

    _setupDependencies();
    _initialized = true;
  }

  void ensureInitialized() {
    if (!_initialized) {
      debugPrint('[Pagy] Default config applied');
      _setupDependencies();
      _initialized = true;
    }
  }

  void _setupDependencies() {
    setup(); // service locator registrations
  }
}
