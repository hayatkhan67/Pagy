/// Represents parsed response data from the paginated API response.
class PagyResponseParser {
  final List<dynamic> list;
  final int? totalPages;
  final int? totalItems;
  final bool? hasMore;

  const PagyResponseParser({
    required this.list,
    required this.totalPages,
    this.totalItems,
    this.hasMore,
  });
}
