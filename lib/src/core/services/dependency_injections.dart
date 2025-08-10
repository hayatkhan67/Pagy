import 'package:pagy/pagy.dart';

import '../../features/pagination/data/datasources/pagy_remote_datasource.dart';
import 'service_locator.dart';

final locator = SimpleServiceLocator();

void setup() {
  locator.register<NetworkApiService>(NetworkApiService.instance);
  locator.register<PagyRemoteDataSource>(
      PagyRemoteDataSource(locator.get<NetworkApiService>()));
  locator.register<PagyRepositoryImpl>(
      PagyRepositoryImpl(locator.get<PagyRemoteDataSource>()));
  locator.register<PagyRepository>(locator.get<PagyRepositoryImpl>());
  locator.register<GetPaginatedDataUseCase>(
      GetPaginatedDataUseCase(locator.get<PagyRepository>()));
}
