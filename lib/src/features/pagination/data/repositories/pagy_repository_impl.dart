import 'package:dio/dio.dart';

import '../../../../../pagy.dart';
import '../../param/pagy_params.dart';
import '../datasources/pagy_remote_datasource.dart';

class PagyRepositoryImpl implements PagyRepository {
  final PagyRemoteDataSource _remote;

  PagyRepositoryImpl(this._remote);

  @override
  Future<Response> getPaginatedData<T>(PagyParams<T> params) async {
    final response = await _remote.getPaginatedData(params);

    return response;
  }
}
