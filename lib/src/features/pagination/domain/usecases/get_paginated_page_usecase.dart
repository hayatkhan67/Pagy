import '../../param/pagy_page_params.dart';
import '../entities/pagy_page.dart';
import '../repositories/pagy_page_repository.dart';

class GetPaginatedPageUseCase {
  final PagyPageRepository _repository;

  const GetPaginatedPageUseCase(this._repository);

  Future<PagyPage<T>> call<T>(PagyPageParams<T> params) async {
    return await _repository.getPage(params);
  }
}
