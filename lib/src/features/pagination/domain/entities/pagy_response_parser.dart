/// Represents parsed response data from the paginated API response.
class PagyResponseParser {
  final List<dynamic> list;
  final int? totalPages;

  const PagyResponseParser({
    required this.list,
    required this.totalPages,
  });
}
