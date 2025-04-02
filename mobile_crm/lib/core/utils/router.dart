import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
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
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/add-repair',
      name: 'add-repair',
      builder: (context, state) => const AddRepairPage(),
    ),
    GoRoute(
      path: '/repair-details/:id',
      name: 'repair-details',
      builder: (context, state) {
        final repairId = state.pathParameters['id']!;
        return RepairDetailsPage(repairId: repairId);
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
);
