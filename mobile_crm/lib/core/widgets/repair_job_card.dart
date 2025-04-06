import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

enum RepairStatus {
  pending, // Device is being repaired
  delivered, // Repair completed and device delivered to customer
}

class RepairJobCard extends StatelessWidget {
  final String id;
  final String customerName;
  final String customerPhone;
  final String deviceModel;
  final String problem;
  final RepairStatus status;
  final DateTime createdAt;
  final double estimatedCost;
  final VoidCallback onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onStatusChange;

  const RepairJobCard({
    Key? key,
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.deviceModel,
    required this.problem,
    required this.status,
    required this.createdAt,
    required this.estimatedCost,
    required this.onView,
    this.onEdit,
    this.onDelete,
    this.onStatusChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          if (onEdit != null)
            SlidableAction(
              onPressed: (_) => onEdit?.call(),
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
            ),
          if (onDelete != null)
            SlidableAction(
              onPressed: (_) => onDelete?.call(),
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
        ],
      ),
      child: GestureDetector(
        onTap: onView,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: _getStatusColor().withOpacity(0.1),
                      child: Icon(
                        _getStatusIcon(),
                        color: _getStatusColor(),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deviceModel,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            customerName,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customerPhone,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatusText(),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: _getStatusColor(),
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${estimatedCost.toStringAsFixed(0)}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          problem.length > 20
                              ? '${problem.substring(0, 20)}...'
                              : problem,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy').format(createdAt),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
                if (status != RepairStatus.delivered &&
                    onStatusChange != null) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: onStatusChange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryLight.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sync,
                            size: 16,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Update Status',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (status) {
      case RepairStatus.pending:
        return 'Pending';
      case RepairStatus.delivered:
        return 'Delivered';
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case RepairStatus.pending:
        return Icons.pending_actions;
      case RepairStatus.delivered:
        return Icons.delivery_dining;
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case RepairStatus.pending:
        return AppColors.warning;
      case RepairStatus.delivered:
        return AppColors.primary;
    }
  }
}
