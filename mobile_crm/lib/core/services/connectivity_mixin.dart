import 'connectivity_service.dart';
import 'service_locator.dart';

/// Mixin that adds connectivity awareness to repositories
mixin ConnectivityAware {
  /// Get the connectivity service instance
  final ConnectivityService _connectivityService =
      getService<ConnectivityService>();

  /// Executes an operation only if there is connectivity
  /// Throws ConnectivityException if there is no internet connection
  Future<T> executeWithConnectivity<T>(Future<T> Function() operation) {
    return _connectivityService.performWithConnectivity(operation);
  }
}
