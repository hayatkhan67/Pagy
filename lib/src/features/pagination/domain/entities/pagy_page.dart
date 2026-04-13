/// A parsed, typed page of paginated results.
///
/// This is a domain-friendly representation that avoids transport-specific
/// types (e.g., Dio Response) and keeps pagination metadata explicit.
class PagyPage<T> {
  final List<T> items;
  final int? totalPages;
  final int? totalItems;
  final bool? hasMore;

  const PagyPage({
    required this.items,
    this.totalPages,
    this.totalItems,
    this.hasMore,
  });
}
