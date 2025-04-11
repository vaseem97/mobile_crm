import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/repair_job_card.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../features/repair/data/repositories/repair_repository_impl.dart';
import '../../../../features/repair/domain/entities/repair_job.dart';

class DashboardRepairsTab extends StatefulWidget {
  // Static variables to track tab state
  static RepairStatus _selectedTab = RepairStatus.pending;
  static int _savedTabIndex = 0;

  // Static method to set the selected tab
  static void setSelectedTab(RepairStatus status) {
    _selectedTab = status;
    _savedTabIndex = status == RepairStatus.pending ? 0 : 1;
  }

  const DashboardRepairsTab({super.key});

  @override
  State<DashboardRepairsTab> createState() => _DashboardRepairsTabState();
}

class _DashboardRepairsTabState extends State<DashboardRepairsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repairRepository = getService<RepairRepositoryImpl>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: DashboardRepairsTab._savedTabIndex,
    );

    _tabController.addListener(() {
      DashboardRepairsTab._savedTabIndex = _tabController.index;
      DashboardRepairsTab._selectedTab = _tabController.index == 0
          ? RepairStatus.pending
          : RepairStatus.returned;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Returned'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRepairsList(RepairStatus.pending),
              _buildRepairsList(RepairStatus.returned),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRepairsList(RepairStatus status) {
    return StreamBuilder<List<RepairJob>>(
      stream: _repairRepository.getRepairJobsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final allRepairs = snapshot.data ?? [];
        final filteredRepairs =
            allRepairs.where((repair) => repair.status == status).toList();

        if (filteredRepairs.isEmpty) {
          return _buildEmptyState(status);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 16),
          itemCount: filteredRepairs.length,
          itemBuilder: (context, index) {
            final job = filteredRepairs[index];
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
                context.push('/edit-repair/${job.id}');
              },
              onDelete: () {
                _showDeleteConfirmation(context, job);
              },
              onStatusChange: status == RepairStatus.pending
                  ? () async {
                      final newStatus = await _showStatusUpdateDialog(context);
                      if (newStatus != null && newStatus != job.status) {
                        try {
                          // Add deliveredAt timestamp when status is changed to returned
                          final updatedJob = job.copyWith(
                            status: newStatus,
                            deliveredAt: newStatus == RepairStatus.returned
                                ? DateTime.now()
                                : job.deliveredAt,
                          );

                          await _repairRepository.updateRepairJob(updatedJob);

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
                                content: Text(
                                    'Error updating status: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    }
                  : null,
            );
          },
        );
      },
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
      case RepairStatus.returned:
        icon = Icons.delivery_dining;
        message = 'No Returned Repairs';
        description = 'No devices have been returned to customers yet.';
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
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (status == RepairStatus.pending)
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/add-repair');
                },
                icon: const Icon(Icons.add),
                label: const Text('Add New Repair'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, RepairJob job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Repair?'),
        content: Text(
            'Are you sure you want to delete the repair for ${job.deviceBrand} ${job.deviceModel}?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _repairRepository.deleteRepairJob(job.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Repair deleted successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting repair: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<RepairStatus?> _showStatusUpdateDialog(BuildContext context) async {
    return showDialog<RepairStatus>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Update Status'),
        children: [
          _StatusOption(
            status: RepairStatus.pending,
            title: 'Pending',
            description: 'Repair in progress',
          ),
          _StatusOption(
            status: RepairStatus.returned,
            title: 'Returned',
            description: 'Device returned to customer',
          ),
        ],
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
      case RepairStatus.returned:
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
