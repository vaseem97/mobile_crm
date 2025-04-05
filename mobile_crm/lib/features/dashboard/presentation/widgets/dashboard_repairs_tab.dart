import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/repair_job_card.dart';

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

  // This variable is used to track and restore the tab state
  static int savedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 4, vsync: this, initialIndex: savedTabIndex);
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
      case RepairStatus.inProgress:
        savedTabIndex = 1;
        break;
      case RepairStatus.completed:
        savedTabIndex = 2;
        break;
      case RepairStatus.delivered:
        savedTabIndex = 3;
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
              _buildRepairsList(RepairStatus.inProgress),
              _buildRepairsList(RepairStatus.completed),
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
          Tab(text: 'In Progress'),
          Tab(text: 'Completed'),
          Tab(text: 'Delivered'),
        ],
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
            size: 72,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textLight,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'All your ${status.name} repairs will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textLight,
                ),
          ),
          const SizedBox(height: 24),
          if (status == RepairStatus.pending)
            ElevatedButton.icon(
              onPressed: () {
                context.push('/add-repair');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Repair'),
            ),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Repair Status'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusOption(
              status: RepairStatus.inProgress,
              title: 'In Progress',
              description: 'Repair has started',
            ),
            _StatusOption(
              status: RepairStatus.completed,
              title: 'Completed',
              description: 'Repair is complete but not delivered',
            ),
            _StatusOption(
              status: RepairStatus.delivered,
              title: 'Delivered',
              description: 'Repair is complete and device delivered',
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

  List<Map<String, dynamic>> _generateMockRepairJobs(RepairStatus status) {
    final now = DateTime.now();

    // Different number of items based on status for demo purposes
    switch (status) {
      case RepairStatus.pending:
        return [
          {
            'id': 'REP001',
            'customerName': 'Rahul Sharma',
            'customerPhone': '9876543210',
            'deviceModel': 'iPhone 13',
            'problem': 'Broken Screen',
            'estimatedCost': 7500.0,
            'createdAt': now.subtract(const Duration(days: 1)),
          },
          {
            'id': 'REP002',
            'customerName': 'Priya Singh',
            'customerPhone': '8765432109',
            'deviceModel': 'Samsung S22',
            'problem': 'Battery Replacement',
            'estimatedCost': 2500.0,
            'createdAt': now.subtract(const Duration(days: 2)),
          },
          {
            'id': 'REP003',
            'customerName': 'Ajay Kumar',
            'customerPhone': '7654321098',
            'deviceModel': 'OnePlus 10T',
            'problem': 'Charging Port Repair',
            'estimatedCost': 1500.0,
            'createdAt': now.subtract(const Duration(days: 2)),
          },
        ];
      case RepairStatus.inProgress:
        return [
          {
            'id': 'REP004',
            'customerName': 'Neha Verma',
            'customerPhone': '9765432108',
            'deviceModel': 'Xiaomi 12',
            'problem': 'Speaker Not Working',
            'estimatedCost': 1200.0,
            'createdAt': now.subtract(const Duration(days: 3)),
          },
          {
            'id': 'REP005',
            'customerName': 'Vikram Patel',
            'customerPhone': '8654321097',
            'deviceModel': 'Realme GT',
            'problem': 'Software Issues',
            'estimatedCost': 800.0,
            'createdAt': now.subtract(const Duration(days: 4)),
          },
        ];
      case RepairStatus.completed:
        return [
          {
            'id': 'REP006',
            'customerName': 'Ananya Desai',
            'customerPhone': '7543210986',
            'deviceModel': 'Vivo V23',
            'problem': 'Camera Repair',
            'estimatedCost': 2000.0,
            'createdAt': now.subtract(const Duration(days: 5)),
          },
        ];
      case RepairStatus.delivered:
        return [
          {
            'id': 'REP007',
            'customerName': 'Rohan Joshi',
            'customerPhone': '9654321098',
            'deviceModel': 'Oppo Reno',
            'problem': 'Water Damage',
            'estimatedCost': 3500.0,
            'createdAt': now.subtract(const Duration(days: 10)),
          },
          {
            'id': 'REP008',
            'customerName': 'Meera Kapoor',
            'customerPhone': '8543210987',
            'deviceModel': 'Nokia X30',
            'problem': 'Screen Replacement',
            'estimatedCost': 5000.0,
            'createdAt': now.subtract(const Duration(days: 12)),
          },
        ];
    }
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
      case RepairStatus.inProgress:
        color = AppColors.info;
        icon = Icons.build;
        break;
      case RepairStatus.completed:
        color = AppColors.success;
        icon = Icons.check_circle;
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
