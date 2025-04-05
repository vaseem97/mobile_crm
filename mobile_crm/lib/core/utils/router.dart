import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/widgets/auth_wrapper.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/repair/presentation/pages/add_repair_page.dart';
import '../../features/repair/presentation/pages/repair_details_page.dart';
import '../../features/repair/presentation/pages/filtered_repairs_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  debugLogDiagnostics: true, // Enable logging for debugging
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const AuthWrapper(
        requireAuth: false,
        child: LoginPage(),
      ),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const AuthWrapper(
        requireAuth: false,
        child: SignupPage(),
      ),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return AuthWrapper(
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'dashboard',
          builder: (context, state) => DashboardPage(key: dashboardKey),
          routes: [
            GoRoute(
              path: 'profile',
              name: 'profile',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const ProfilePage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
              ),
            ),
            GoRoute(
              path: 'add-repair',
              name: 'add-repair',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const AddRepairPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
              ),
            ),
            GoRoute(
              path: 'repair-details/:id',
              name: 'repair-details',
              pageBuilder: (context, state) {
                final repairId = state.pathParameters['id']!;
                return CustomTransitionPage(
                  key: state.pageKey,
                  child: RepairDetailsPage(repairId: repairId),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                );
              },
            ),
            GoRoute(
              path: 'repairs/:status',
              name: 'filtered-repairs',
              pageBuilder: (context, state) {
                final status = state.pathParameters['status']!;
                return CustomTransitionPage(
                  key: state.pageKey,
                  child: FilteredRepairsPage(status: status),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        'Page ${state.path} not found',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    ),
  ),
  // Redirect logic - check if user is authenticated
  redirect: (context, state) {
    // Add global redirects here if needed
    return null;
  },
);
