import '../../../internal_imports.dart';
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

  locator.register<PagyPageRepositoryImpl>(
      PagyPageRepositoryImpl(locator.get<PagyRemoteDataSource>()));
  locator.register<PagyPageRepository>(locator.get<PagyPageRepositoryImpl>());
  locator.register<GetPaginatedPageUseCase>(
      GetPaginatedPageUseCase(locator.get<PagyPageRepository>()));
}
