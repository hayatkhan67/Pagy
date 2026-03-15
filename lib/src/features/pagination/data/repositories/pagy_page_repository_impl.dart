import '../../../../core/errors/pagy_error.dart';
import '../../domain/entities/pagy_page.dart';
import '../../domain/repositories/pagy_page_repository.dart';
import '../../param/pagy_page_params.dart';
import '../../param/pagy_params.dart';
import '../datasources/pagy_remote_datasource.dart';

class PagyPageRepositoryImpl implements PagyPageRepository {
  final PagyRemoteDataSource _remote;

  PagyPageRepositoryImpl(this._remote);

  @override
  Future<PagyPage<T>> getPage<T>(PagyPageParams<T> params) async {
    final response = await _remote.getPaginatedData(
      PagyParams(
        endPoint: params.endPoint,
        requestType: params.requestType,
        page: params.page,
        limit: params.limit,
        queryParameter: params.queryParameter,
        additionalQueryParams: params.additionalQueryParams,
        payloadData: params.payloadData,
        token: params.token,
        headers: params.headers,
        cancelToken: params.cancelToken,
        paginationMode: params.paginationMode,
        fromMap: params.fromMap,
      ),
    );

    if (response.data == null || response.data is! Map<String, dynamic>) {
      throw PagyError.malformedResponse(
        message: 'Response format is invalid',
      );
    }

    final parsed = params.responseParser(response.data as Map<String, dynamic>);
    final parsedList = parsed.list;

    if (parsedList is! List) {
      throw PagyError.malformedResponse(
        message: 'Expected list in response parser output',
      );
    }

    final List<T> items = [];
    for (int i = 0; i < parsedList.length; i++) {
      try {
        items.add(params.fromMap(parsedList[i] as Map<String, dynamic>));
      } catch (e) {
        throw PagyError.malformedResponse(
          message:
              'Parsing error on item $i. Please check your model or keys.',
        );
      }
    }

    return PagyPage<T>(
      items: items,
      totalPages: parsed.totalPages,
    );
  }
}
