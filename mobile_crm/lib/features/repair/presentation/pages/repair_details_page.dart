import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/repair_job_card.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../features/repair/data/repositories/repair_repository_impl.dart';
import '../../../../features/repair/domain/entities/repair_job.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final _repairRepository = getService<RepairRepositoryImpl>();
  RepairJob? _repairJob;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRepairJob();
  }

  Future<void> _loadRepairJob() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repair = await _repairRepository.getRepairJobById(widget.repairId);

      if (mounted) {
        setState(() {
          _repairJob = repair;
          _isLoading = false;
        });
      }

      if (repair == null && mounted) {
        setState(() {
          _errorMessage = 'Repair job not found';
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

  Future<void> _updateStatus(RepairStatus newStatus) async {
    if (_repairJob == null) return;

    try {
      final updatedRepair = _repairJob!.copyWith(
        status: newStatus,
        deliveredAt: newStatus == RepairStatus.delivered
            ? DateTime.now()
            : _repairJob!.deliveredAt,
      );
      await _repairRepository.updateRepairJob(updatedRepair);

      if (mounted) {
        setState(() {
          _repairJob = updatedRepair;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${_getStatusText(newStatus)}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getStatusText(RepairStatus status) {
    switch (status) {
      case RepairStatus.pending:
        return 'Pending Repair';
      case RepairStatus.delivered:
        return 'Device Delivered';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair Details'),
        actions: [
          if (!_isLoading && _repairJob != null)
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
          : _errorMessage != null
              ? _buildErrorState()
              : _repairJob == null
                  ? _buildNotFoundState()
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRepairCard(),
          const SizedBox(height: 16),
          _buildRepairIssueCard(),
          const SizedBox(height: 16),
          _buildPaymentInfoCard(),
          const SizedBox(height: 16),
          _buildDeviceInfoCard(),
          const SizedBox(height: 16),
          _buildPasswordCard(),
          const SizedBox(height: 16),
          _buildCustomerInfoCard(),
          const SizedBox(height: 16),
          if (_repairJob!.imageUrls != null &&
              _repairJob!.imageUrls!.isNotEmpty)
            _buildDeviceImagesSection(),
          if (_repairJob!.imageUrls != null &&
              _repairJob!.imageUrls!.isNotEmpty)
            const SizedBox(height: 16),
          if (_repairJob!.status != RepairStatus.delivered)
            CustomButton(
              text: 'Mark as Delivered',
              onPressed: () {
                _showDeliveryConfirmationDialog();
              },
              leadingIcon: Icons.check_circle,
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
    );
  }

  Widget _buildRepairCard() {
    Color statusColor;
    IconData statusIcon;

    switch (_repairJob!.status) {
      case RepairStatus.pending:
        statusColor = AppColors.warning;
        statusIcon = Icons.pending_actions;
        break;
      case RepairStatus.delivered:
        statusColor = AppColors.primary;
        statusIcon = Icons.delivery_dining;
        break;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build_circle, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Repair #${_repairJob!.id}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(_repairJob!.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.smartphone,
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_repairJob!.deviceBrand} ${_repairJob!.deviceModel}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${DateFormat('dd MMM yyyy, h:mm a').format(_repairJob!.createdAt)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (_repairJob!.status == RepairStatus.delivered &&
                          _repairJob!.deliveredAt != null)
                        Text(
                          'Delivered: ${DateFormat('dd MMM yyyy, h:mm a').format(_repairJob!.deliveredAt!)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepairIssueCard() {
    if (_repairJob == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Repair Issues',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Text(
                _repairJob!.problem,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_repairJob!.partsToReplace.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Parts to Replace:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _repairJob!.partsToReplace.map((part) {
                  return Chip(
                    label: Text(part),
                    backgroundColor: Colors.grey.shade200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    labelStyle: TextStyle(fontSize: 12),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    if (_repairJob == null) return const SizedBox.shrink();

    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final bool hasAdvance = _repairJob!.advanceAmount > 0;
    final double balanceAmount =
        _repairJob!.estimatedCost - _repairJob!.advanceAmount;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Payment Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Cost:',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    formatter.format(_repairJob!.estimatedCost),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (hasAdvance) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Advance:',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            formatter.format(_repairJob!.advanceAmount),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Balance:',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            formatter.format(balanceAmount),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: balanceAmount > 0
                                  ? Colors.orange.shade700
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (_repairJob!.notes != null && _repairJob!.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  _repairJob!.notes!,
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    if (_repairJob == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smartphone, color: AppColors.primary),
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
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Brand',
                    _repairJob!.deviceBrand,
                    Icons.phone_android,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    'Model',
                    _repairJob!.deviceModel,
                    Icons.devices,
                  ),
                ),
              ],
            ),
            if (_repairJob!.deviceColor.isNotEmpty ||
                _repairJob!.deviceImei.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_repairJob!.deviceColor.isNotEmpty)
                    Expanded(
                      child: _buildInfoItem(
                        'Color',
                        _repairJob!.deviceColor,
                        Icons.color_lens,
                      ),
                    ),
                  if (_repairJob!.deviceColor.isNotEmpty &&
                      _repairJob!.deviceImei.isNotEmpty)
                    const SizedBox(width: 16),
                  if (_repairJob!.deviceImei.isNotEmpty)
                    Expanded(
                      child: _buildInfoItem(
                        'IMEI',
                        _repairJob!.deviceImei,
                        Icons.numbers,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade700),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
    if (_repairJob == null || _repairJob!.devicePassword.isEmpty)
      return const SizedBox.shrink();

    final bool isPattern = _repairJob!.devicePassword.contains('→');

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPattern ? Icons.pattern : Icons.password,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Device Unlock',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    _showPasswordDialog(
                        isPattern: isPattern,
                        password: _repairJob!.devicePassword);
                  },
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text('View', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size(0, 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    isPattern ? Icons.pattern : Icons.password,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '••••••••',
                      style: TextStyle(
                        fontSize: 15,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click the "View" button to see the device unlock pattern/password',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPasswordDialog(
      {required bool isPattern, required String password}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPattern ? 'Device Pattern' : 'Device Password'),
        content: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPattern) ...[
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      password,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    password,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                isPattern ? 'Pattern: $password' : 'Password: $password',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    if (_repairJob == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Customer Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContactInfo(
                        'Name',
                        _repairJob!.customerName,
                        Icons.person_outline,
                      ),
                      const SizedBox(height: 8),
                      _buildContactInfo(
                        'Phone',
                        _repairJob!.customerPhone,
                        Icons.phone,
                        hasAction: true,
                        action: () async {
                          final Uri phoneUri = Uri(
                              scheme: 'tel', path: _repairJob!.customerPhone);
                          if (await canLaunchUrl(phoneUri)) {
                            await launchUrl(phoneUri);
                          }
                        },
                        actionIcon: Icons.call,
                      ),
                      if (_repairJob!.customerEmail.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildContactInfo(
                          'Email',
                          _repairJob!.customerEmail,
                          Icons.email,
                          hasAction: true,
                          action: () async {
                            final Uri emailUri = Uri(
                              scheme: 'mailto',
                              path: _repairJob!.customerEmail,
                            );
                            if (await canLaunchUrl(emailUri)) {
                              await launchUrl(emailUri);
                            }
                          },
                          actionIcon: Icons.mail_outline,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(
    String label,
    String value,
    IconData icon, {
    bool hasAction = false,
    VoidCallback? action,
    IconData? actionIcon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (hasAction && action != null && actionIcon != null)
          IconButton(
            icon: Icon(actionIcon, color: AppColors.primary),
            onPressed: action,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildDeviceImagesSection() {
    if (_repairJob == null ||
        _repairJob!.imageUrls == null ||
        _repairJob!.imageUrls!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Device Photos (${_repairJob!.imageUrls!.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_repairJob!.imageUrls!.length == 1)
              GestureDetector(
                onTap: () {
                  _showFullSizeImage(_repairJob!.imageUrls![0]);
                },
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _repairJob!.imageUrls![0],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImageErrorWidget();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildImageLoadingWidget(loadingProgress);
                      },
                    ),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: _repairJob!.imageUrls!.length > 4
                    ? 4
                    : _repairJob!.imageUrls!.length,
                itemBuilder: (context, index) {
                  final bool hasMore =
                      _repairJob!.imageUrls!.length > 4 && index == 3;
                  return GestureDetector(
                    onTap: () {
                      _showFullSizeImage(_repairJob!.imageUrls![index]);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              _repairJob!.imageUrls![index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildImageErrorWidget();
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return _buildImageLoadingWidget(
                                    loadingProgress);
                              },
                            ),
                            if (hasMore)
                              Container(
                                color: Colors.black.withOpacity(0.7),
                                child: Center(
                                  child: Text(
                                    '+${_repairJob!.imageUrls!.length - 3}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _showAllImages();
              },
              child: Text(
                'View All Images',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageErrorWidget() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
      ),
    );
  }

  Widget _buildImageLoadingWidget(ImageChunkEvent loadingProgress) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  }

  void _showAllImages() {
    if (_repairJob == null ||
        _repairJob!.imageUrls == null ||
        _repairJob!.imageUrls!.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title:
                  Text('All Device Images (${_repairJob!.imageUrls!.length})'),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _repairJob!.imageUrls!.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showFullSizeImage(_repairJob!.imageUrls![index]);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _repairJob!.imageUrls![index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImageErrorWidget();
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildImageLoadingWidget(loadingProgress);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullSizeImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Device Image'),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(
                  imageUrl,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeliveryConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Device Delivery'),
          content: const Text(
              'Are you sure you want to mark this repair as completed and delivered to the customer?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateStatus(RepairStatus.delivered);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  String _formatStatus(RepairStatus status) {
    switch (status) {
      case RepairStatus.pending:
        return 'Pending';
      case RepairStatus.delivered:
        return 'Delivered';
    }
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Print Repair Ticket'),
              onTap: () {
                Navigator.pop(context);
                // Print functionality
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
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Repair Job',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    if (_repairJob == null) return;

    final shouldDelete = await showDialog<bool>(
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

    if (shouldDelete == true) {
      try {
        await _repairRepository.deleteRepairJob(_repairJob!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Repair job deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(); // Go back to the previous screen
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
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 72,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              'Error loading repair details',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadRepairJob,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 72,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              'Repair Job Not Found',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'The repair job you are looking for does not exist or may have been deleted.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to find minimum of two integers
int min(int a, int b) {
  return a < b ? a : b;
}
