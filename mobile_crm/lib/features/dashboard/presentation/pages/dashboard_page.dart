import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/dashboard_home_tab.dart';
import '../widgets/dashboard_stats_tab.dart';
import '../widgets/dashboard_profile_tab.dart';
import '../../presentation/widgets/dashboard_repairs_tab.dart';

// Global key to access the dashboard state
final GlobalKey<_DashboardPageState> dashboardKey =
    GlobalKey<_DashboardPageState>();

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  // Static method to switch tabs
  static void switchToTab(int index) {
    final state = dashboardKey.currentState;
    if (state != null) {
      state.switchTab(index);
    }
  }

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;

  final List<Widget> _tabs = [
    const DashboardHomeTab(),
    const DashboardRepairsTab(),
    const DashboardStatsTab(),
    const DashboardProfileTab(),
  ];

  final List<String> _tabTitles = [
    'Dashboard',
    'Repairs',
    'Statistics',
    'Profile',
  ];

  // Public method to switch tabs
  void switchTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tabTitles[_currentIndex]),
          actions: [
            if (_currentIndex == 1) // Only show add button in Repairs tab
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  context.push('/add-repair');
                },
              ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                // TODO: Show notifications
              },
            ),
          ],
        ),
        body: _tabs[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textLight,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.build_outlined),
                activeIcon: Icon(Icons.build),
                label: 'Repairs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: 'Stats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
        floatingActionButton: _currentIndex == 1
            ? FloatingActionButton.extended(
                onPressed: () {
                  context.push('/add-repair');
                },
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add),
                label: const Text('New Repair'),
              )
            : null,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_lastBackPressTime == null ||
        DateTime.now().difference(_lastBackPressTime!) >
            const Duration(seconds: 2)) {
      // First time back button is pressed or more than 2 seconds since last press
      _lastBackPressTime = DateTime.now();

      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exit App'),
          content: const Text('Are you sure you want to exit the app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Exit'),
            ),
          ],
        ),
      );

      return shouldPop ?? false;
    }

    // If back button is pressed twice quickly (within 2 seconds), exit without confirmation
    return true;
  }
}
