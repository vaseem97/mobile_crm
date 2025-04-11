import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/repair_job_card.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../features/repair/data/repositories/repair_repository_impl.dart';
import '../../../../features/repair/domain/entities/repair_job.dart';
import '../pages/dashboard_page.dart';
import '../widgets/dashboard_stats_tab.dart';

class DashboardHomeTab extends StatefulWidget {
  const DashboardHomeTab({super.key});

  @override
  State<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<DashboardHomeTab> {
  final _repairRepository = getService<RepairRepositoryImpl>();
  final _authService = getService<FirebaseAuthService>();
  final _firestoreService = getService<FirestoreService>();

  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_authService.currentUser == null) return;

    try {
      // Start loading user data

      final uid = _authService.currentUser!.uid;
      final docSnapshot = await _firestoreService.getDocument(
        collectionPath: 'users',
        documentId: uid,
      );

      if (docSnapshot.exists) {
        setState(() {
          _userData = docSnapshot.data() as Map<String, dynamic>?;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RepairJob>>(
      stream: _repairRepository.getRepairJobsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 500,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading dashboard data',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Trigger widget rebuild
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Process the data
        final allRepairs = snapshot.data ?? [];

        // Get today's date
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Filter repairs by status
        final pending =
            allRepairs.where((r) => r.status == RepairStatus.pending).toList();
        final returned =
            allRepairs.where((r) => r.status == RepairStatus.returned).toList();

        // Calculate today's sales from returned repairs
        final todaySales = returned
            .where((repair) =>
                repair.deliveredAt != null &&
                repair.deliveredAt!.isAfter(today))
            .fold(0.0, (sum, repair) => sum + repair.estimatedCost);

        // Sort repairs by createdAt descending (most recent first)
        allRepairs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final recentRepairs = allRepairs.take(5).toList();

        return RefreshIndicator(
          onRefresh: () async {
            // No need to manually refresh as stream will update automatically
            return;
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(context),
                const SizedBox(height: 24),
                _buildStatisticsOverview(
                    context, pending.length, returned.length, todaySales),
                const SizedBox(height: 24),
                _buildRecentRepairsSection(context, recentRepairs),
                const SizedBox(height: 24),
                _buildQuickActionsSection(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    // Get shop name from user data
    final shopName = _userData?['shopName'] ?? 'Your Shop';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  radius: 24,
                  child: const Icon(
                    Icons.store,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, $shopName',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Have a great day!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Add New Repair',
              onPressed: () {
                context.push('/add-repair');
              },
              backgroundColor: Colors.white,
              textColor: AppColors.primary,
              leadingIcon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsOverview(BuildContext context, int pendingCount,
      int returnedCount, double todaySales) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                pendingCount.toString(),
                'Pending Repairs',
                Icons.pending_actions,
                AppColors.warning,
                () => context.push('/repairs/pending'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                returnedCount.toString(),
                'Returned',
                Icons.delivery_dining,
                AppColors.primary,
                () => context.push('/repairs/returned'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                (pendingCount + returnedCount).toString(),
                'Total Repairs',
                Icons.receipt_long,
                AppColors.info,
                () {
                  // Switch to Repairs tab
                  DashboardPage.switchToTab(1);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                '₹${todaySales.toStringAsFixed(0)}',
                'Today\'s Sales',
                Icons.payments,
                AppColors.success,
                () {
                  // Set the desired period to 'Today'
                  DashboardStatsTab.selectTodayPeriod();
                  // Switch to Stats tab
                  DashboardPage.switchToTab(2);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentRepairsSection(
      BuildContext context, List<RepairJob> recentRepairs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Repairs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {
                // Switch to Repairs tab
                DashboardPage.switchToTab(1);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        recentRepairs.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text('No repairs yet'),
                ),
              )
            : Column(
                children: recentRepairs.map((repair) {
                  Color statusColor;
                  String statusText;

                  switch (repair.status) {
                    case RepairStatus.pending:
                      statusColor = AppColors.warning;
                      statusText = 'Pending';
                      break;
                    case RepairStatus.returned:
                      statusColor = AppColors.primary;
                      statusText = 'Returned';
                      break;
                  }

                  return _buildRecentRepairItem(
                    context,
                    '${repair.deviceBrand} ${repair.deviceModel}',
                    repair.problem,
                    statusText,
                    statusColor,
                    repair.id,
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildRecentRepairItem(
    BuildContext context,
    String deviceName,
    String repairType,
    String status,
    Color statusColor,
    String repairId,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context.push('/repair-details/$repairId');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.smartphone,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      repairType,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                'Add Repair',
                Icons.add_circle_outline,
                AppColors.primary,
                () => context.push('/add-repair'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                context,
                'Generate Invoice',
                Icons.receipt_long,
                AppColors.secondary,
                () => context.push('/invoice-selection'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                'View Analytics',
                Icons.insights,
                AppColors.info,
                () {
                  // Navigate to analytics
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                context,
                'Customer List',
                Icons.people_outline,
                AppColors.success,
                () => context.push('/customer-list'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
