/// Metadata about the current pagination state.
///
/// Provides easy access to pagination information for building UI elements
/// like page indicators, progress bars, or "Page X of Y" displays.
///
/// Example:
/// ```dart
/// final metadata = controller.metadata;
///
/// Text('Page ${metadata.currentPage} of ${metadata.totalPages}');
/// LinearProgressIndicator(value: metadata.progress);
/// IconButton(
///   onPressed: metadata.hasMore ? controller.loadMore : null,
///   icon: Icon(Icons.arrow_forward),
/// );
/// ```
class PagyMetadata {
  /// Current page number (1-indexed)
  final int currentPage;

  /// Total number of pages available
  final int totalPages;

  /// Number of items per page
  final int itemsPerPage;

  /// Number of items currently loaded
  final int loadedItems;

  const PagyMetadata({
    required this.currentPage,
    required this.totalPages,
    required this.itemsPerPage,
    required this.loadedItems,
  });

  /// Whether there are more pages to load
  bool get hasMore => currentPage < totalPages;

  /// Whether there are previous pages
  bool get hasPrevious => currentPage > 1;

  /// Estimated total number of items across all pages
  ///
  /// Note: This is an estimate based on `totalPages * itemsPerPage`.
  /// The actual total might differ if the last page is partial.
  int get estimatedTotalItems => totalPages * itemsPerPage;

  /// Loading progress as a value between 0.0 and 1.0
  ///
  /// Useful for progress indicators.
  double get progress {
    if (totalPages == 0) return 0.0;
    return currentPage / totalPages;
  }

  /// Percentage of pages loaded (0-100)
  int get progressPercentage => (progress * 100).round();

  /// Whether the user is on the first page
  bool get isFirstPage => currentPage == 1;

  /// Whether the user is on the last page
  bool get isLastPage => currentPage >= totalPages;

  /// Range of pages for pagination UI (e.g., "Showing 1-20 of ~100")
  String get rangeDescription {
    if (loadedItems == 0) return 'No items';

    final start = ((currentPage - 1) * itemsPerPage) + 1;
    final end = start + loadedItems - 1;

    return 'Showing $start-$end of ~$estimatedTotalItems';
  }

  @override
  String toString() {
    return 'PagyMetadata('
        'currentPage: $currentPage, '
        'totalPages: $totalPages, '
        'itemsPerPage: $itemsPerPage, '
        'loadedItems: $loadedItems, '
        'hasMore: $hasMore)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PagyMetadata &&
          runtimeType == other.runtimeType &&
          currentPage == other.currentPage &&
          totalPages == other.totalPages &&
          itemsPerPage == other.itemsPerPage &&
          loadedItems == other.loadedItems;

  @override
  int get hashCode =>
      currentPage.hashCode ^
      totalPages.hashCode ^
      itemsPerPage.hashCode ^
      loadedItems.hashCode;
}
