import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../features/repair/data/repositories/repair_repository_impl.dart';
import '../../../../features/repair/domain/entities/repair_job.dart';
import '../../../../core/widgets/repair_job_card.dart';
import '../pages/dashboard_page.dart';

class DashboardHomeTab extends StatefulWidget {
  const DashboardHomeTab({Key? key}) : super(key: key);

  @override
  State<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<DashboardHomeTab> {
  final _repairRepository = getService<RepairRepositoryImpl>();
  bool _isLoading = true;
  String? _errorMessage;

  // Dashboard statistics
  int _pendingCount = 0;
  int _inProgressCount = 0;
  int _completedCount = 0;
  double _todaySales = 0;
  List<RepairJob> _recentRepairs = [];
  List<RepairJob> _recentDeliveries = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final pending =
          await _repairRepository.getRepairJobsByStatus(RepairStatus.pending);

      final delivered =
          await _repairRepository.getRepairJobsByStatus(RepairStatus.delivered);

      // Get today's date
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Sort repairs by createdAt descending (most recent first)
      final allRepairs = [...pending, ...delivered];
      allRepairs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Recent deliveries - in the last 7 days
      final recentDeliveries = allRepairs.where((repair) {
        return repair.status == RepairStatus.delivered &&
            repair.deliveredAt != null &&
            repair.deliveredAt!
                .isAfter(today.subtract(const Duration(days: 7)));
      }).toList();

      if (mounted) {
        setState(() {
          _pendingCount = pending.length;
          _inProgressCount = 0;
          _completedCount = 0;
          _todaySales = 0;
          _recentRepairs = allRepairs.take(5).toList();
          _recentDeliveries = recentDeliveries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const SizedBox(
                height: 500,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : _errorMessage != null
                ? SizedBox(
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
                            _errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeCard(context),
                      const SizedBox(height: 24),
                      _buildStatisticsOverview(context),
                      const SizedBox(height: 24),
                      _buildRecentRepairsSection(context),
                      const SizedBox(height: 24),
                      _buildQuickActionsSection(context),
                    ],
                  ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
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
                    Icons.person,
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
                        'Welcome back, Shop Owner',
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

  Widget _buildStatisticsOverview(BuildContext context) {
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
                _pendingCount.toString(),
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
                _inProgressCount.toString(),
                'In Progress',
                Icons.build,
                AppColors.info,
                () => context.push('/repairs/inprogress'),
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
                _completedCount.toString(),
                'Completed',
                Icons.check_circle,
                AppColors.success,
                () => context.push('/repairs/completed'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                '₹${_todaySales.toStringAsFixed(0)}',
                'Today\'s Sales',
                Icons.payments,
                AppColors.primary,
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
    String title,
    IconData icon,
    Color color, [
    VoidCallback? onTap,
  ]) {
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
                title,
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

  Widget _buildRecentRepairsSection(BuildContext context) {
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
                // Navigate to repairs tab (index 1)
                DashboardPage.switchToTab(1);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _recentRepairs.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No repairs found. Add your first repair job!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              )
            : Column(
                children: _recentRepairs.map((repair) {
                  Color statusColor;
                  String statusText;

                  switch (repair.status) {
                    case RepairStatus.pending:
                      statusColor = AppColors.warning;
                      statusText = 'Pending';
                      break;
                    case RepairStatus.delivered:
                      statusColor = AppColors.primary;
                      statusText = 'Delivered';
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
                () {
                  // Navigate to invoice generation
                },
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
                () {
                  // Navigate to customer list
                },
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

  Color _getStatusColor(RepairStatus status) {
    switch (status) {
      case RepairStatus.pending:
        return AppColors.warning;
      case RepairStatus.delivered:
        return AppColors.primary;
    }
  }

  IconData _getStatusIcon(RepairStatus status) {
    switch (status) {
      case RepairStatus.pending:
        return Icons.pending_actions;
      case RepairStatus.delivered:
        return Icons.delivery_dining;
    }
  }
}
