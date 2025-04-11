import 'package:get_it/get_it.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';
import 'storage_service.dart';
import '../../features/repair/data/repositories/repair_repository_impl.dart';
import '../../features/customer/data/repositories/customer_repository_impl.dart';

final GetIt locator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Register Firebase services
  locator
      .registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService());
  locator.registerLazySingleton<FirestoreService>(() => FirestoreService());

  // Register Supabase storage service (no need to initialize anymore)
  locator.registerLazySingleton<StorageService>(() => StorageService());

  // Register the general Supabase storage service (optional for advanced usage)

  // Repositories
  locator.registerLazySingleton<RepairRepositoryImpl>(
      () => RepairRepositoryImpl());
  locator.registerLazySingleton<CustomerRepositoryImpl>(
      () => CustomerRepositoryImpl());
}

// Helper function to easily access services
T getService<T extends Object>() {
  return locator<T>();
}
