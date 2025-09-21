import '../../features/pagination/domain/entities/pagy_state.dart';

int calculatePagyItemCount<T>(
  PagyState<T> state,
  int? itemShowLimit,
) {
  final base = state.data.length;
  final hasMore = state.isMoreFetching ? 1 : 0;

  if (itemShowLimit != null && itemShowLimit > 0) {
    return base < itemShowLimit ? base + hasMore : itemShowLimit;
  }
  return base + hasMore;
}
