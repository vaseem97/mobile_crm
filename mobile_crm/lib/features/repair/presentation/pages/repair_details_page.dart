import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/repair_job_card.dart';
import '../../../../core/widgets/image_gallery_widget.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../features/repair/data/repositories/repair_repository_impl.dart';
import '../../../../features/repair/domain/entities/repair_job.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/storage_service.dart';
import '../widgets/status_info_card.dart';

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
      // First try to get the repair job with active check
      final repair = await _repairRepository.getRepairJobById(widget.repairId);

      if (repair != null) {
        // Repair found and is active
        if (mounted) {
          setState(() {
            _repairJob = repair;
            _isLoading = false;
          });
        }
      } else {
        // Check if the repair exists but is deleted
        final deletedRepair = await _repairRepository
            .getRepairJobById(widget.repairId, checkActive: false);

        if (mounted) {
          if (deletedRepair != null) {
            // Repair exists but was deleted
            setState(() {
              _errorMessage = 'This repair job has been deleted';
              _isLoading = false;
            });
          } else {
            // Repair doesn't exist at all
            setState(() {
              _errorMessage = 'Repair job not found';
              _isLoading = false;
            });
          }
        }
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
        deliveredAt: newStatus == RepairStatus.returned
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
      case RepairStatus.returned:
        return 'Device Returned';
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: AppColors.primary),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Repair ID',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      _repairJob!.id,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StatusInfoCard(repairJob: _repairJob!),
          const SizedBox(height: 16),
          if (_repairJob!.imageUrls != null &&
              _repairJob!.imageUrls!.isNotEmpty) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ImageGalleryWidget(imageUrls: _repairJob!.imageUrls!),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildRepairIssueCard(),
          const SizedBox(height: 16),
          _buildPaymentInfoCard(),
          const SizedBox(height: 16),
          _buildDeviceInfoCard(),
          const SizedBox(height: 16),
          _buildPasswordCard(),
          const SizedBox(height: 16),
          _buildNotesCard(),
          const SizedBox(height: 16),
          _buildCustomerInfoCard(),
          const SizedBox(height: 16),
          if (_repairJob!.status != RepairStatus.returned)
            CustomButton(
              text: 'Mark as Returned',
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
            const SizedBox(height: 16),
            if (_repairJob!.partsToReplace.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _repairJob!.partsToReplace.map((part) {
                  return Chip(
                    label: Text(part),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    labelStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  _repairJob!.problem,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
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
                Icon(Icons.payments, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Payment Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Repair Cost',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '₹${_repairJob!.estimatedCost.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_repairJob!.advanceAmount > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Advance Payment',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '₹${_repairJob!.advanceAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Balance Due',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    '₹${(_repairJob!.estimatedCost - _repairJob!.advanceAmount).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _repairJob!.advanceAmount > 0
                          ? AppColors.warning
                          : Colors.black,
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
            if (_repairJob!.warrantyPeriod != null &&
                _repairJob!.warrantyPeriod!.isNotEmpty &&
                _repairJob!.warrantyPeriod! != 'No Warranty') ...[
              const SizedBox(height: 12),
              _buildInfoItem(
                'Warranty',
                _repairJob!.warrantyPeriod!,
                Icons.shield_outlined,
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
    if (_repairJob == null ||
        (_repairJob!.devicePassword.isEmpty &&
            _repairJob!.devicePattern.isEmpty)) {
      return const SizedBox.shrink();
    }

    final bool isPattern = _repairJob!.devicePattern.isNotEmpty;
    final String password =
        isPattern ? _repairJob!.devicePattern : _repairJob!.devicePassword;

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
                  isPattern ? 'Device Pattern' : 'Device PIN',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    _showPasswordDialog(
                      isPattern: isPattern,
                      password: password,
                    );
                  },
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 32),
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
              isPattern
                  ? 'Click the "View" button to see the device unlock pattern'
                  : 'Click the "View" button to see the device PIN/password',
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
        title: Text(isPattern ? 'Device Pattern' : 'Device PIN'),
        content: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPattern) ...[
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Stack(
                    children: [
                      // Draw lines connecting the selected dots
                      CustomPaint(
                        size: const Size(250, 250),
                        painter: PatternViewPainter(pattern: password),
                      ),

                      // Draw the 3x3 grid of dots
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                        ),
                        itemCount: 9,
                        itemBuilder: (context, index) {
                          final row = index ~/ 3;
                          final col = index % 3;

                          // Check if this dot is part of the pattern
                          final String positionName =
                              _getPositionName(row, col);
                          final bool isDotSelected =
                              password.contains(positionName);

                          // Determine if this is the start or end dot
                          final bool isStartDot =
                              password.startsWith(positionName);
                          final bool isEndDot = password.endsWith(positionName);

                          // Calculate the sequence number of this dot in the pattern
                          int sequenceNumber = -1;
                          if (isDotSelected) {
                            final List<String> dots = password.split(' → ');
                            sequenceNumber = dots.indexOf(positionName) + 1;
                          }

                          return Center(
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDotSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDotSelected
                                      ? AppColors.primary
                                      : Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                              child: isDotSelected
                                  ? Center(
                                      child: isStartDot
                                          ? const Text(
                                              'S',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : isEndDot
                                              ? const Text(
                                                  'E',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : Text(
                                                  '$sequenceNumber',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Text(
                    password,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
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

  String _getPositionName(int row, int col) {
    final positions = [
      ['Top-Left', 'Top-Center', 'Top-Right'],
      ['Middle-Left', 'Center', 'Middle-Right'],
      ['Bottom-Left', 'Bottom-Center', 'Bottom-Right'],
    ];
    return positions[row][col];
  }

  Widget _buildNotesCard() {
    if (_repairJob == null ||
        _repairJob!.notes == null ||
        _repairJob!.notes!.isEmpty) {
      return const SizedBox.shrink();
    }

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
                Icon(Icons.note, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Additional Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                _repairJob!.notes!,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
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

  void _showDeliveryConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Device Return'),
        content: const Text(
            'Are you sure you want to mark this repair as returned to the customer?'),
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
              _updateStatus(RepairStatus.returned);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
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
              Icons.delete_outline,
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
              'This repair job has been deleted and is no longer available.',
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

class PatternViewPainter extends CustomPainter {
  final String pattern;

  PatternViewPainter({required this.pattern});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final List<String> dots = pattern.split(' → ');
    if (dots.length <= 1) return;

    final Map<String, Offset> positions = {};

    // Calculate grid cell size
    final cellWidth = size.width / 3;
    final cellHeight = size.height / 3;

    // Create a map of positions
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final String posName = _getPositionName(row, col);
        // Place the center of each dot
        positions[posName] = Offset(
          (col * cellWidth) + (cellWidth / 2),
          (row * cellHeight) + (cellHeight / 2),
        );
      }
    }

    // Draw lines connecting the dots
    for (int i = 0; i < dots.length - 1; i++) {
      final startDot = dots[i];
      final endDot = dots[i + 1];

      if (positions.containsKey(startDot) && positions.containsKey(endDot)) {
        canvas.drawLine(positions[startDot]!, positions[endDot]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  // Helper method to get position name for pattern dots
  String _getPositionName(int row, int col) {
    final positions = [
      ['Top-Left', 'Top-Center', 'Top-Right'],
      ['Middle-Left', 'Center', 'Middle-Right'],
      ['Bottom-Left', 'Bottom-Center', 'Bottom-Right'],
    ];
    return positions[row][col];
  }
}
