import 'package:dio/dio.dart';

import '../../../../../internal_imports.dart';
import '../../param/pagy_params.dart';

class PagyRepositoryImpl implements PagyRepository {
  final PagyRemoteDataSource _remote;

  PagyRepositoryImpl(this._remote);

  @override
  Future<Response> getPaginatedData<T>(PagyParams<T> params) async {
    final response = await _remote.getPaginatedData(params);

    return response;
  }
}
