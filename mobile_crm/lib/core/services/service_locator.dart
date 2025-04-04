import 'package:get_it/get_it.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';
import 'storage_service.dart';

final GetIt locator = GetIt.instance;

void setupServiceLocator() {
  // Register Firebase services
  locator
      .registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService());
  locator.registerLazySingleton<FirestoreService>(() => FirestoreService());
  locator.registerLazySingleton<FirebaseStorageService>(
      () => FirebaseStorageService());
}

// Helper function to easily access services
T getService<T extends Object>() {
  return locator<T>();
}
