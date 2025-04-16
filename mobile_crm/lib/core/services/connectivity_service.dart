import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  // Stream controller for connectivity status
  final _connectivityStreamController =
      StreamController<ConnectivityStatus>.broadcast();

  // Stream for UI components to listen to
  Stream<ConnectivityStatus> get statusStream =>
      _connectivityStreamController.stream;

  // Current status
  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  ConnectivityStatus get currentStatus => _currentStatus;

  ConnectivityService() {
    // Initialize
    _initConnectivity();

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
  }

  // Initialize connectivity
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      // For connectivity_plus 6.x, result is now a list
      _handleConnectivityChange(result);
    } catch (e) {
      debugPrint('Connectivity initialization error: $e');
      _updateStatus(ConnectivityStatus.offline);
    }
  }

  // Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) async {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      _updateStatus(ConnectivityStatus.offline);
      return;
    }

    // Perform active internet check
    final hasActiveInternet = await _checkActiveInternetConnection();
    _updateStatus(hasActiveInternet
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline);
  }

  // Update status and notify listeners
  void _updateStatus(ConnectivityStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _connectivityStreamController.add(status);
    }
  }

  // Actively check for internet connectivity by making a small request
  Future<bool> _checkActiveInternetConnection() async {
    try {
      // Try to connect to a reliable host
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));

      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (e) {
      debugPrint('Active connectivity check error: $e');
      return false;
    }
  }

  // Check active connection on demand
  Future<bool> checkConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.isEmpty ||
        connectivityResult.contains(ConnectivityResult.none)) {
      _updateStatus(ConnectivityStatus.offline);
      return false;
    }

    final hasActiveInternet = await _checkActiveInternetConnection();
    _updateStatus(hasActiveInternet
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline);
    return hasActiveInternet;
  }

  // Dispose resources
  void dispose() {
    _connectivityStreamController.close();
  }
}

// Enum to represent connectivity status
enum ConnectivityStatus { online, offline, unknown }
