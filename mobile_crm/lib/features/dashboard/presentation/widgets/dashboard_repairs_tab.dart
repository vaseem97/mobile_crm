import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/repair_job_card.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../features/repair/data/repositories/repair_repository_impl.dart';
import '../../../../features/repair/domain/entities/repair_job.dart';

class DashboardRepairsTab extends StatefulWidget {
  const DashboardRepairsTab({Key? key}) : super(key: key);

  // Static method to set the selected tab
  static void setSelectedTab(RepairStatus status) {
    _DashboardRepairsTabState.navigateToTab(status);
  }

  @override
  State<DashboardRepairsTab> createState() => _DashboardRepairsTabState();
}

class _DashboardRepairsTabState extends State<DashboardRepairsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _repairRepository = getService<RepairRepositoryImpl>();
  bool _isLoading = false;
  String? _errorMessage;

  // This variable is used to track and restore the tab state
  static int savedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: savedTabIndex);
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      savedTabIndex = _tabController.index;
    }
  }

  // Custom method to navigate to a specific tab
  static void navigateToTab(RepairStatus status) {
    switch (status) {
      case RepairStatus.pending:
        savedTabIndex = 0;
        break;
      case RepairStatus.delivered:
        savedTabIndex = 1;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterTabs(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRepairsList(RepairStatus.pending),
              _buildRepairsList(RepairStatus.delivered),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search repairs, customers or devices...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              // Show advanced filters dialog
            },
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'Delivered'),
        ],
      ),
    );
  }

  Widget _buildRepairsList(RepairStatus status) {
    return FutureBuilder<List<RepairJob>>(
      future: _repairRepository.getRepairJobsByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
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
                  'Error loading repairs',
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
                    setState(() {});
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final repairs = snapshot.data ?? [];

        if (repairs.isEmpty) {
          return _buildEmptyState(status);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: repairs.length,
          itemBuilder: (context, index) {
            final job = repairs[index];
            return RepairJobCard(
              id: job.id,
              customerName: job.customerName,
              customerPhone: job.customerPhone,
              deviceModel: '${job.deviceBrand} ${job.deviceModel}',
              problem: job.problem,
              status: job.status,
              createdAt: job.createdAt,
              estimatedCost: job.estimatedCost,
              onView: () {
                context.push('/repair-details/${job.id}');
              },
              onEdit: () {
                // Show edit dialog or navigate to edit page
              },
              onDelete: () async {
                final shouldDelete = await _showDeleteConfirmation(context);
                if (shouldDelete == true) {
                  try {
                    await _repairRepository.deleteRepairJob(job.id);
                    setState(() {}); // Refresh the list
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Repair job deleted successfully'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Error deleting repair: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              onStatusChange: () async {
                final newStatus = await _showStatusUpdateDialog(context);
                if (newStatus != null && newStatus != job.status) {
                  try {
                    await _repairRepository.updateRepairJob(
                      job.copyWith(status: newStatus),
                    );
                    setState(() {}); // Refresh the list
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Status updated successfully'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Error updating status: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            );
          },
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Repair Job'),
        content: const Text(
          'Are you sure you want to delete this repair job? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(RepairStatus status) {
    IconData icon;
    String message;
    String description;

    switch (status) {
      case RepairStatus.pending:
        icon = Icons.pending_actions;
        message = 'No Pending Repairs';
        description = 'All repairs have been started or completed.';
        break;
      case RepairStatus.delivered:
        icon = Icons.delivery_dining;
        message = 'No Delivered Repairs';
        description = 'No devices have been delivered to customers yet.';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/add-repair');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Repair'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<RepairStatus?> _showStatusUpdateDialog(BuildContext context) async {
    return showDialog<RepairStatus>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Repair Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusOption(
              status: RepairStatus.pending,
              title: 'Pending',
              description: 'Repair has not started',
            ),
            _StatusOption(
              status: RepairStatus.delivered,
              title: 'Delivered',
              description: 'Device returned to customer',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final RepairStatus status;
  final String title;
  final String description;

  const _StatusOption({
    required this.status,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case RepairStatus.pending:
        color = AppColors.warning;
        icon = Icons.pending_actions;
        break;
      case RepairStatus.delivered:
        color = AppColors.primary;
        icon = Icons.delivery_dining;
        break;
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).pop(status);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
