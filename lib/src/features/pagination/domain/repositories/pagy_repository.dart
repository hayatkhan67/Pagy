import 'package:dio/dio.dart';

import '../../param/pagy_params.dart';

abstract class PagyRepository {
  /// Get paginated data using the provided params.
  Future<Response> getPaginatedData<T>(PagyParams<T> params);
}
