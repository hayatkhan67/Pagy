import '../../features/pagination/domain/entities/pagy_response_parser.dart';

/// Built-in response parsers for common API response structures.
///
/// These parsers eliminate boilerplate code for standard pagination patterns.
/// Use them directly or as examples for creating custom parsers.
///
/// Example:
/// ```dart
/// PagyController(
///   endPoint: '/users',
///   responseParser: PagyParsers.dataWithPagination,
///   // ...
/// );
/// ```
class PagyParsers {
  PagyParsers._(); // Private constructor to prevent instantiation

  /// Parser for responses with structure:
  /// ```json
  /// {
  ///   "data": [...],
  ///   "pagination": {
  ///     "totalPages": 10
  ///   }
  /// }
  /// ```
  ///
  /// This is one of the most common API pagination patterns.
  static PagyResponseParser dataWithPagination(Map<String, dynamic> response) {
    return PagyResponseParser(
      list: response['data'] ?? [],
      totalPages: response['pagination']?['totalPages'] as int?,
    );
  }

  /// Parser for responses with structure:
  /// ```json
  /// {
  ///   "items": [...],
  ///   "total_pages": 10
  /// }
  /// ```
  ///
  /// Common in REST APIs using snake_case naming.
  static PagyResponseParser itemsWithTotal(Map<String, dynamic> response) {
    return PagyResponseParser(
      list: response['items'] ?? [],
      totalPages: response['total_pages'] as int?,
    );
  }

  /// Parser for responses with structure:
  /// ```json
  /// {
  ///   "results": [...],
  ///   "page_count": 10
  /// }
  /// ```
  ///
  /// Used by some popular APIs like GitHub, GitLab.
  static PagyResponseParser resultsWithCount(Map<String, dynamic> response) {
    return PagyResponseParser(
      list: response['results'] ?? [],
      totalPages: response['page_count'] as int?,
    );
  }

  /// Parser for simple responses with structure:
  /// ```json
  /// {
  ///   "data": [...],
  ///   "total": 10
  /// }
  /// ```
  ///
  /// Where `total` represents total page count.
  static PagyResponseParser simpleList(Map<String, dynamic> response) {
    return PagyResponseParser(
      list: response['data'] ?? [],
      totalPages: response['total'] as int?,
    );
  }

  /// Parser for responses with nested pagination metadata:
  /// ```json
  /// {
  ///   "data": [...],
  ///   "meta": {
  ///     "total_pages": 10
  ///   }
  /// }
  /// ```
  ///
  /// Common in JSON:API compliant responses.
  static PagyResponseParser dataWithMeta(Map<String, dynamic> response) {
    return PagyResponseParser(
      list: response['data'] ?? [],
      totalPages: response['meta']?['total_pages'] as int?,
    );
  }

  /// Parser for responses where items are at root level:
  /// ```json
  /// {
  ///   "users": [...],
  ///   "totalPages": 10
  /// }
  /// ```
  ///
  /// Use this as a template for custom key names.
  ///
  /// Example:
  /// ```dart
  /// responseParser: (response) => PagyParsers.customKey(
  ///   response,
  ///   itemKey: 'users',
  ///   totalKey: 'totalPages',
  /// )
  /// ```
  static PagyResponseParser customKey(
    Map<String, dynamic> response, {
    required String itemKey,
    String totalKey = 'totalPages',
  }) {
    return PagyResponseParser(
      list: response[itemKey] ?? [],
      totalPages: response[totalKey] as int?,
    );
  }

  /// Parser for Laravel-style pagination responses:
  /// ```json
  /// {
  ///   "data": [...],
  ///   "last_page": 10,
  ///   "current_page": 1,
  ///   "per_page": 15
  /// }
  /// ```
  static PagyResponseParser laravel(Map<String, dynamic> response) {
    return PagyResponseParser(
      list: response['data'] ?? [],
      totalPages: response['last_page'] as int?,
    );
  }

  /// Parser for Django REST Framework pagination:
  /// ```json
  /// {
  ///   "results": [...],
  ///   "count": 100,
  ///   "next": "url",
  ///   "previous": "url"
  /// }
  /// ```
  ///
  /// Note: Calculates total pages from count and page size.
  /// You need to provide the limit to calculate total pages.
  static PagyResponseParser django(
    Map<String, dynamic> response, {
    int itemsPerPage = 10,
  }) {
    final count = response['count'] as int?;
    final totalPages = count != null ? (count / itemsPerPage).ceil() : null;

    return PagyResponseParser(
      list: response['results'] ?? [],
      totalPages: totalPages,
    );
  }
}
