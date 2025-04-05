import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/repair_job_card.dart';
import '../../../../features/dashboard/presentation/widgets/dashboard_repairs_tab.dart';
import '../../../../features/dashboard/presentation/pages/dashboard_page.dart';

class FilteredRepairsPage extends StatefulWidget {
  final String status;

  const FilteredRepairsPage({Key? key, required this.status}) : super(key: key);

  @override
  State<FilteredRepairsPage> createState() => _FilteredRepairsPageState();
}

class _FilteredRepairsPageState extends State<FilteredRepairsPage> {
  late RepairStatus _filterStatus;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filterStatus = _getStatusFromString(widget.status);
    DashboardRepairsTab.setSelectedTab(_filterStatus);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  RepairStatus _getStatusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return RepairStatus.pending;
      case 'inprogress':
        return RepairStatus.inProgress;
      case 'completed':
        return RepairStatus.completed;
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
      case RepairStatus.inProgress:
        return 'In Progress Repairs';
      case RepairStatus.completed:
        return 'Completed Repairs';
      case RepairStatus.delivered:
        return 'Delivered Repairs';
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
    // Generating mock data for demo purposes
    // In a real app, this would come from a repository or service
    final mockJobs = _generateMockRepairJobs(status);

    return mockJobs.isEmpty
        ? _buildEmptyState(status)
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: mockJobs.length,
            itemBuilder: (context, index) {
              final job = mockJobs[index];
              return RepairJobCard(
                id: job['id'],
                customerName: job['customerName'],
                customerPhone: job['customerPhone'],
                deviceModel: job['deviceModel'],
                problem: job['problem'],
                status: status,
                createdAt: job['createdAt'],
                estimatedCost: job['estimatedCost'],
                onView: () {
                  context.push('/repair-details/${job['id']}');
                },
                onEdit: () {
                  // Show edit dialog or navigate to edit page
                },
                onDelete: () {
                  // Show delete confirmation
                },
                onStatusChange: () {
                  _showStatusUpdateDialog(context);
                },
              );
            },
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
      case RepairStatus.inProgress:
        message = 'No repairs in progress';
        icon = Icons.build_circle;
        break;
      case RepairStatus.completed:
        message = 'No completed repairs';
        icon = Icons.check_circle;
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

  List<Map<String, dynamic>> _generateMockRepairJobs(RepairStatus status) {
    // This would normally come from a repository or service
    // We're using mock data for demonstration

    final List<Map<String, dynamic>> allJobs = [
      {
        'id': '1',
        'customerName': 'Rahul Sharma',
        'customerPhone': '9876543210',
        'deviceModel': 'iPhone 13 Pro',
        'problem': 'Broken screen, not turning on',
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
        'estimatedCost': 8500.0,
        'status': RepairStatus.pending,
      },
      {
        'id': '2',
        'customerName': 'Priya Patel',
        'customerPhone': '8765432109',
        'deviceModel': 'Samsung Galaxy S21',
        'problem': 'Battery draining too quickly',
        'createdAt': DateTime.now().subtract(const Duration(days: 3)),
        'estimatedCost': 2500.0,
        'status': RepairStatus.inProgress,
      },
      {
        'id': '3',
        'customerName': 'Vikram Singh',
        'customerPhone': '7654321098',
        'deviceModel': 'OnePlus 9 Pro',
        'problem': 'Charging port not working',
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
        'estimatedCost': 1800.0,
        'status': RepairStatus.completed,
      },
      {
        'id': '4',
        'customerName': 'Ananya Desai',
        'customerPhone': '6543210987',
        'deviceModel': 'Xiaomi Mi 11',
        'problem': 'Camera not focusing',
        'createdAt': DateTime.now().subtract(const Duration(days: 7)),
        'estimatedCost': 3000.0,
        'status': RepairStatus.delivered,
      },
      {
        'id': '5',
        'customerName': 'Sanjay Kumar',
        'customerPhone': '9876543211',
        'deviceModel': 'iPhone 12',
        'problem': 'Face ID not working',
        'createdAt': DateTime.now().subtract(const Duration(days: 4)),
        'estimatedCost': 4500.0,
        'status': RepairStatus.pending,
      },
      {
        'id': '6',
        'customerName': 'Neha Gupta',
        'customerPhone': '8765432100',
        'deviceModel': 'Google Pixel 6',
        'problem': 'Screen flickering',
        'createdAt': DateTime.now().subtract(const Duration(days: 6)),
        'estimatedCost': 5000.0,
        'status': RepairStatus.inProgress,
      },
    ];

    return allJobs.where((job) => job['status'] == status).toList();
  }

  void _showStatusUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Repair Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption(
              RepairStatus.inProgress,
              'In Progress',
              'Repair has started',
              Icons.build,
              AppColors.info,
            ),
            const SizedBox(height: 8),
            _buildStatusOption(
              RepairStatus.completed,
              'Completed',
              'Repair is complete but not delivered',
              Icons.check_circle,
              AppColors.success,
            ),
            const SizedBox(height: 8),
            _buildStatusOption(
              RepairStatus.delivered,
              'Delivered',
              'Repair is complete and device delivered',
              Icons.delivery_dining,
              AppColors.primary,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(
    RepairStatus status,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
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
