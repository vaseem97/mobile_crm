import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/repair_job_card.dart';
import '../../../../features/dashboard/presentation/widgets/dashboard_repairs_tab.dart';
import '../../../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../features/repair/data/repositories/repair_repository_impl.dart';
import '../../../../features/repair/domain/entities/repair_job.dart';

class FilteredRepairsPage extends StatefulWidget {
  final String status;

  const FilteredRepairsPage({Key? key, required this.status}) : super(key: key);

  @override
  State<FilteredRepairsPage> createState() => _FilteredRepairsPageState();
}

class _FilteredRepairsPageState extends State<FilteredRepairsPage> {
  late RepairStatus _filterStatus;
  final _searchController = TextEditingController();
  final _repairRepository = getService<RepairRepositoryImpl>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _filterStatus = _getStatusFromRoute(widget.status);
    DashboardRepairsTab.setSelectedTab(_filterStatus);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  RepairStatus _getStatusFromRoute(String route) {
    switch (route) {
      case 'pending':
        return RepairStatus.pending;
      case 'delivered':
        return RepairStatus.delivered;
      default:
        return RepairStatus.pending;
    }
  }

  String _getStatusTitle(RepairStatus status) {
    switch (status) {
      case RepairStatus.pending:
        return 'Pending Repairs';
      case RepairStatus.delivered:
        return 'Delivered Repairs';
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

  Color _getStatusColor(RepairStatus status) {
    switch (status) {
      case RepairStatus.pending:
        return AppColors.warning;
      case RepairStatus.delivered:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getStatusTitle(_filterStatus)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Use pop to go back to previous screen instead of going to dashboard
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildRepairsList(_filterStatus),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/add-repair');
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('New Repair'),
      ),
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
    String message;
    IconData icon;

    switch (status) {
      case RepairStatus.pending:
        message = 'No pending repairs';
        icon = Icons.inbox;
        break;
      case RepairStatus.delivered:
        message = 'No delivered repairs';
        icon = Icons.delivery_dining;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textLight,
                ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {
              context.push('/add-repair');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Repair'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Future<RepairStatus?> _showStatusUpdateDialog(BuildContext context) {
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
