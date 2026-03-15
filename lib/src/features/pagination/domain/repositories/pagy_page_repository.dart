import '../../param/pagy_page_params.dart';
import '../entities/pagy_page.dart';

/// Domain-facing repository that returns parsed, typed pagination results.
abstract class PagyPageRepository {
  Future<PagyPage<T>> getPage<T>(PagyPageParams<T> params);
}
