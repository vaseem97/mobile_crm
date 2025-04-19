import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

/// Utility class for connectivity-related operations
class ConnectivityUtils {
  /// Shows a standard connectivity error snackbar
  static void showConnectivityError(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Standardized error handler for connectivity exceptions
  static void handleConnectivityError(BuildContext context, Object error) {
    if (error is ConnectivityException) {
      showConnectivityError(context, error.message);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}
