import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/service_locator.dart';

/// A widget that checks the authentication state and redirects accordingly.
/// If user is not authenticated, they're redirected to the login page.
/// Otherwise, the child widget is displayed.
class AuthWrapper extends StatefulWidget {
  final Widget child;
  final bool requireAuth;

  const AuthWrapper({
    Key? key,
    required this.child,
    this.requireAuth = true,
  }) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FirebaseAuthService _authService = getService<FirebaseAuthService>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Check if we're still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final isAuthenticated = snapshot.hasData;

        // If authentication is required but user is not authenticated, redirect to login
        if (widget.requireAuth && !isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          // Show loading screen while redirecting
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is authenticated but on a page that requires no auth (like login),
        // redirect to home page
        if (!widget.requireAuth && isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/');
          });
          // Show loading screen while redirecting
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Otherwise, show the intended child widget
        return widget.child;
      },
    );
  }
}
