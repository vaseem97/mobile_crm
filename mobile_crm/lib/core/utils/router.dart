import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/widgets/auth_wrapper.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/repair/presentation/pages/add_repair_page.dart';
import '../../features/repair/presentation/pages/repair_details_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
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
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (context, state) => const AuthWrapper(
        child: DashboardPage(),
      ),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const AuthWrapper(
        child: ProfilePage(),
      ),
    ),
    GoRoute(
      path: '/add-repair',
      name: 'add-repair',
      builder: (context, state) => const AuthWrapper(
        child: AddRepairPage(),
      ),
    ),
    GoRoute(
      path: '/repair-details/:id',
      name: 'repair-details',
      builder: (context, state) {
        final repairId = state.pathParameters['id']!;
        return AuthWrapper(
          child: RepairDetailsPage(repairId: repairId),
        );
      },
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
