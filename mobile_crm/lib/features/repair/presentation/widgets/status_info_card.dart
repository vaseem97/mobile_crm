import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/repair_job_card.dart';
import '../../domain/entities/repair_job.dart';

class StatusInfoCard extends StatelessWidget {
  final RepairJob repairJob;
  const StatusInfoCard({Key? key, required this.repairJob}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = repairJob.status;
    final statusColor =
        status == RepairStatus.pending ? AppColors.warning : AppColors.primary;
    final statusIcon = status == RepairStatus.pending
        ? Icons.pending_actions
        : Icons.delivery_dining;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build_circle, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Device Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
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
                        status == RepairStatus.pending
                            ? 'Pending Repair'
                            : 'Device Returned',
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
                  child: Icon(Icons.smartphone,
                      color: AppColors.primary.withOpacity(0.7)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${repairJob.deviceBrand} ${repairJob.deviceModel}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${DateFormat('dd MMM yyyy, h:mm a').format(repairJob.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (status == RepairStatus.returned &&
                          repairJob.deliveredAt != null)
                        Text(
                          'Returned: ${DateFormat('dd MMM yyyy, h:mm a').format(repairJob.deliveredAt!)}',
                          style: Theme.of(context).textTheme.bodySmall,
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
}
