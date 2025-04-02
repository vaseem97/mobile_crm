import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/repair_job_card.dart';

class RepairDetailsPage extends StatefulWidget {
  final String repairId;

  const RepairDetailsPage({
    Key? key,
    required this.repairId,
  }) : super(key: key);

  @override
  State<RepairDetailsPage> createState() => _RepairDetailsPageState();
}

class _RepairDetailsPageState extends State<RepairDetailsPage> {
  bool _isLoading = true;
  late Map<String, dynamic> _repairJob;
  RepairStatus _status = RepairStatus.pending;

  @override
  void initState() {
    super.initState();
    _loadRepairJob();
  }

  Future<void> _loadRepairJob() async {
    // Mock loading delay
    await Future.delayed(const Duration(milliseconds: 800));

    // In a real app, fetch data from Firestore
    // For now, create mock data based on the ID
    setState(() {
      _repairJob = _getMockRepairJob(widget.repairId);
      _status = _getStatusFromString(_repairJob['status']);
      _isLoading = false;
    });
  }

  Map<String, dynamic> _getMockRepairJob(String id) {
    // Mock data for demonstration
    return {
      'id': id,
      'customerName': 'Rahul Sharma',
      'customerPhone': '9876543210',
      'customerEmail': 'rahul.sharma@example.com',
      'deviceModel': 'iPhone 13 Pro',
      'deviceBrand': 'Apple',
      'deviceColor': 'Graphite',
      'devicePassword': '1234',
      'deviceImei': '123456789012345',
      'problem':
          'Screen shattered after dropping the phone. Touch is not working properly.',
      'diagnosis': 'Front screen assembly needs replacement.',
      'partsToReplace': ['Screen Assembly', 'Battery'],
      'estimatedCost': 8500.0,
      'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'pending',
      'notes': 'Customer needs the device by end of week for work purposes.',
      'imageUrls': [],
    };
  }

  RepairStatus _getStatusFromString(String status) {
    switch (status) {
      case 'pending':
        return RepairStatus.pending;
      case 'inProgress':
        return RepairStatus.inProgress;
      case 'completed':
        return RepairStatus.completed;
      case 'delivered':
        return RepairStatus.delivered;
      default:
        return RepairStatus.pending;
    }
  }

  void _updateStatus(RepairStatus newStatus) {
    // In a real app, update status in Firestore
    setState(() {
      _status = newStatus;
      _repairJob['status'] = newStatus.name;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status updated to ${_getStatusText(newStatus)}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  String _getStatusText(RepairStatus status) {
    switch (status) {
      case RepairStatus.pending:
        return 'Pending';
      case RepairStatus.inProgress:
        return 'In Progress';
      case RepairStatus.completed:
        return 'Completed';
      case RepairStatus.delivered:
        return 'Delivered';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair Details'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Navigate to edit page
              },
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showMoreOptions(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildDeviceInfoCard(),
                  const SizedBox(height: 16),
                  _buildCustomerInfoCard(),
                  const SizedBox(height: 16),
                  _buildRepairDetailsCard(),
                  const SizedBox(height: 24),
                  if (_status != RepairStatus.delivered)
                    CustomButton(
                      text: 'Update Status',
                      onPressed: () {
                        _showStatusUpdateDialog();
                      },
                      leadingIcon: Icons.update,
                    ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Generate Invoice',
                    onPressed: () {
                      // Generate invoice functionality
                    },
                    leadingIcon: Icons.receipt_long,
                    isOutlined: true,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;

    switch (_status) {
      case RepairStatus.pending:
        statusColor = AppColors.warning;
        statusIcon = Icons.pending_actions;
        break;
      case RepairStatus.inProgress:
        statusColor = AppColors.info;
        statusIcon = Icons.build;
        break;
      case RepairStatus.completed:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case RepairStatus.delivered:
        statusColor = AppColors.primary;
        statusIcon = Icons.delivery_dining;
        break;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  radius: 24,
                  child: Icon(
                    statusIcon,
                    size: 24,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repair #${_repairJob['id']}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created on ${DateFormat('dd MMM yyyy, h:mm a').format(_repairJob['createdAt'])}',
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(_status),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(
                  'Estimated',
                  '₹${_repairJob['estimatedCost'].toStringAsFixed(0)}',
                  Icons.payments,
                ),
                _buildInfoChip(
                  'Expected',
                  '1-2 days',
                  Icons.schedule,
                ),
                _buildInfoChip(
                  'Warranty',
                  '30 days',
                  Icons.verified_user,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.textSecondary,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildDeviceInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.phone_android,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Device Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Device',
                '${_repairJob['deviceBrand']} ${_repairJob['deviceModel']}'),
            const SizedBox(height: 8),
            _buildInfoRow('Color', _repairJob['deviceColor']),
            const SizedBox(height: 8),
            _buildInfoRow('Password', _repairJob['devicePassword']),
            const SizedBox(height: 8),
            _buildInfoRow('IMEI', _repairJob['deviceImei']),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.person,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Customer Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.phone,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: () {
                    // Call customer
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.message,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: () {
                    // Message customer
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', _repairJob['customerName']),
            const SizedBox(height: 8),
            _buildInfoRow('Phone', _repairJob['customerPhone']),
            const SizedBox(height: 8),
            _buildInfoRow('Email', _repairJob['customerEmail']),
          ],
        ),
      ),
    );
  }

  Widget _buildRepairDetailsCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.build,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Repair Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Problem'),
            Text(
              _repairJob['problem'],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Diagnosis'),
            Text(
              _repairJob['diagnosis'],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Parts to Replace'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  (_repairJob['partsToReplace'] as List).map<Widget>((part) {
                return Chip(
                  label: Text(part),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  labelStyle: TextStyle(color: AppColors.primary),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (_repairJob['notes'] != null &&
                _repairJob['notes'].isNotEmpty) ...[
              _buildSectionTitle('Additional Notes'),
              Text(
                _repairJob['notes'],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  void _showStatusUpdateDialog() {
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
        Navigator.of(context).pop();
        _updateStatus(status);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Print Receipt'),
              onTap: () {
                Navigator.pop(context);
                // Print receipt functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Details'),
              onTap: () {
                Navigator.pop(context);
                // Share functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text(
                'Delete Repair',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Repair'),
        content: const Text(
            'Are you sure you want to delete this repair job? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Delete repair job
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
