import 'package:dio/dio.dart';

import '../../param/pagy_params.dart';
import '../repositories/pagy_repository.dart';

class GetPaginatedDataUseCase {
  final PagyRepository _repository;

  const GetPaginatedDataUseCase(this._repository);

  Future<Response> call<T>(PagyParams<T> params) async {
    return await _repository.getPaginatedData(params);
  }
}
