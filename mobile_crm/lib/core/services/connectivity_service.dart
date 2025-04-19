import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _connectionChecker =
      InternetConnectionChecker();

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

    // Also listen to the internet connection checker's status updates
    _connectionChecker.onStatusChange.listen((status) {
      _updateStatusFromInternetChecker(status);
    });
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

  // Update status based on InternetConnectionChecker
  void _updateStatusFromInternetChecker(InternetConnectionStatus status) {
    final isConnected = status == InternetConnectionStatus.connected;
    _updateStatus(
        isConnected ? ConnectivityStatus.online : ConnectivityStatus.offline);
  }

  // Update status and notify listeners
  void _updateStatus(ConnectivityStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _connectivityStreamController.add(status);
    }
  }

  // Actively check for internet connectivity using the internet checker
  Future<bool> _checkActiveInternetConnection() async {
    try {
      return await _connectionChecker.hasConnection;
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

    final hasActiveInternet = await _connectionChecker.hasConnection;
    _updateStatus(hasActiveInternet
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline);
    return hasActiveInternet;
  }

  // Configure the internet connection checker
  void configureConnectionChecker({
    Duration? checkInterval,
    Duration? timeout,
    List<AddressCheckOptions>? addresses,
  }) {
    if (addresses != null && addresses.isNotEmpty) {
      // The addresses can be set directly
      _connectionChecker.addresses = addresses;
    }

    // For interval and timeout, we need to create a new instance with these parameters
    // since they are final in the original implementation
    if (checkInterval != null || timeout != null) {
      debugPrint(
          'Note: checkInterval and timeout cannot be changed after initialization in the current version of internet_connection_checker.');
      // You would need to recreate the checker if these need to be changed
    }
  }

  // Wrapper method to check connectivity before performing an operation
  Future<T> performWithConnectivity<T>(
    Future<T> Function() operation, {
    Function(String)? onNoConnectivity,
  }) async {
    final hasConnection = await checkConnection();

    if (!hasConnection) {
      final message = 'No internet connection available';
      if (onNoConnectivity != null) {
        onNoConnectivity(message);
      }
      throw ConnectivityException(message);
    }

    return operation();
  }

  // Dispose resources
  void dispose() {
    _connectivityStreamController.close();
  }
}

// Enum to represent connectivity status
enum ConnectivityStatus { online, offline, unknown }

// Custom exception for connectivity issues
class ConnectivityException implements Exception {
  final String message;
  ConnectivityException(this.message);

  @override
  String toString() => message;
}
