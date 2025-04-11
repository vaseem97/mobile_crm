import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../features/repair/data/repositories/repair_repository_impl.dart';
import '../../../../features/repair/domain/entities/repair_job.dart';
import '../../../../core/widgets/repair_job_card.dart';
import 'dart:math' show min;

class DashboardStatsTab extends StatefulWidget {
  const DashboardStatsTab({super.key});

  // Static method to set the period to 'Today'
  static void selectTodayPeriod() {
    // We'll implement this differently
    // by using a static variable to track the desired period
    _desiredPeriod = 'Today';
  }

  // Static variable to track the desired period
  static String? _desiredPeriod;

  @override
  State<DashboardStatsTab> createState() => _DashboardStatsTabState();
}

class _DashboardStatsTabState extends State<DashboardStatsTab> {
  final _repairRepository = getService<RepairRepositoryImpl>();
  String _selectedPeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    // Check if there's a desired period set from outside
    if (DashboardStatsTab._desiredPeriod != null) {
      _selectedPeriod = DashboardStatsTab._desiredPeriod!;
      // Reset the static variable
      DashboardStatsTab._desiredPeriod = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RepairJob>>(
      stream: _repairRepository.getRepairJobsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 500,
            child: Center(
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
                    'Error loading statistics',
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
                      setState(() {}); // Trigger widget rebuild
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final allRepairs = snapshot.data ?? [];

        // Filter for the selected period
        final DateTime now = DateTime.now();
        DateTime periodStart;

        switch (_selectedPeriod) {
          case 'Today':
            periodStart = DateTime(now.year, now.month, now.day);
            break;
          case 'This Week':
            // Start of week (assuming Sunday as first day)
            periodStart = now.subtract(Duration(days: now.weekday % 7));
            periodStart =
                DateTime(periodStart.year, periodStart.month, periodStart.day);
            break;
          case 'This Month':
            periodStart = DateTime(now.year, now.month, 1);
            break;
          case 'This Year':
            periodStart = DateTime(now.year, 1, 1);
            break;
          default:
            // Default to this month
            periodStart = DateTime(now.year, now.month, 1);
        }

        final filteredRepairs = allRepairs
            .where((repair) =>
                repair.createdAt.isAfter(periodStart) ||
                repair.createdAt.isAtSameMomentAs(periodStart))
            .toList();

        // Calculate statistics
        final pendingRepairs = filteredRepairs
            .where((r) => r.status == RepairStatus.pending)
            .toList();
        final returnedRepairs = filteredRepairs
            .where((r) => r.status == RepairStatus.returned)
            .toList();

        final revenue = returnedRepairs.fold(
            0.0, (sum, repair) => sum + repair.estimatedCost);

        // Calculate device brand distribution
        final deviceBrands = <String, int>{};
        for (var repair in filteredRepairs) {
          deviceBrands[repair.deviceBrand] =
              (deviceBrands[repair.deviceBrand] ?? 0) + 1;
        }

        // Calculate repair types (using problem field)
        final repairTypes = <String, int>{};
        for (var repair in filteredRepairs) {
          // Simplify problem description for statistics
          String problemType = repair.problem.split(' ').first;
          if (problemType.length < 3) {
            problemType =
                repair.problem.substring(0, min(20, repair.problem.length));
          }

          repairTypes[problemType] = (repairTypes[problemType] ?? 0) + 1;
        }

        // Sort maps by value (descending)
        var sortedDeviceBrands = Map.fromEntries(deviceBrands.entries.toList()
          ..sort((e1, e2) => e2.value.compareTo(e1.value)));

        var sortedRepairTypes = Map.fromEntries(repairTypes.entries.toList()
          ..sort((e1, e2) => e2.value.compareTo(e1.value)));

        return RefreshIndicator(
          onRefresh: () async {
            // No need to manually refresh as stream will update automatically
            return;
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeriodSelector(context),
                const SizedBox(height: 24),
                _buildRevenueStats(context, revenue),
                const SizedBox(height: 24),
                _buildRepairStats(context, filteredRepairs.length,
                    pendingRepairs.length, returnedRepairs.length),
                const SizedBox(height: 24),
                _buildDeviceDistribution(context, sortedDeviceBrands),
                const SizedBox(height: 24),
                _buildCommonRepairTypes(context, sortedRepairTypes),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    return Row(
      children: [
        Text(
          'Statistics For:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPeriod,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                elevation: 0,
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPeriod = newValue;
                    });
                  }
                },
                items: <String>['Today', 'This Week', 'This Month', 'This Year']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueStats(BuildContext context, double totalRevenue) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.currency_rupee,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${totalRevenue.toStringAsFixed(0)}',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                    ),
                    Text(
                      'Total Revenue for $_selectedPeriod',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepairStats(
    BuildContext context,
    int totalRepairs,
    int pendingCount,
    int completedCount,
  ) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repair Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => context.push('/repairs/pending'),
                  child: _buildRepairStat(
                    context,
                    totalRepairs.toString(),
                    'Total Repairs',
                    AppColors.primary,
                  ),
                ),
                InkWell(
                  onTap: () => context.push('/repairs/pending'),
                  child: _buildRepairStat(
                    context,
                    pendingCount.toString(),
                    'Pending',
                    AppColors.warning,
                  ),
                ),
                InkWell(
                  onTap: () => context.push('/repairs/returned'),
                  child: _buildRepairStat(
                    context,
                    completedCount.toString(),
                    'Returned',
                    AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepairStat(
    BuildContext context,
    String count,
    String title,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildDeviceDistribution(
      BuildContext context, Map<String, int> deviceBrands) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            deviceBrands.isEmpty
                ? _buildEmptyStateMessage('No device data available')
                : Column(
                    children: deviceBrands.entries.take(5).map((entry) {
                      return _buildDistributionItem(
                        context,
                        entry.key,
                        entry.value,
                        _getColorForBrand(entry.key),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Color _getColorForBrand(String brand) {
    final brandColors = {
      'Samsung': AppColors.primary,
      'Apple': Colors.grey[800]!,
      'Xiaomi': AppColors.info,
      'Oppo': AppColors.success,
      'Vivo': const Color(0xFF1E88E5),
      'OnePlus': Colors.red[700]!,
      'Realme': Colors.yellow[800]!,
      'Nokia': Colors.blue[800]!,
    };

    return brandColors[brand] ?? AppColors.primary;
  }

  Widget _buildCommonRepairTypes(
      BuildContext context, Map<String, int> repairTypes) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Common Repair Types',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            repairTypes.isEmpty
                ? _buildEmptyStateMessage('No repair type data available')
                : Column(
                    children: repairTypes.entries.take(5).map((entry) {
                      return _buildRepairTypeItem(
                        context,
                        entry.key,
                        entry.value,
                        _getColorForRepairType(entry.key),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Color _getColorForRepairType(String type) {
    final typeColors = {
      'Screen': AppColors.primary,
      'Battery': AppColors.secondary,
      'Charging': AppColors.info,
      'Water': AppColors.warning,
      'Software': AppColors.success,
    };

    // Find a matching type
    for (var key in typeColors.keys) {
      if (type.toLowerCase().contains(key.toLowerCase())) {
        return typeColors[key]!;
      }
    }

    return AppColors.primary;
  }

  Widget _buildEmptyStateMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDistributionItem(
    BuildContext context,
    String title,
    int count,
    Color color,
  ) {
    // Calculate percentage based on total repair count
    double percentage = 0;
    if (count > 0) {
      // Use the parameter passed to _buildDeviceDistribution instead
      final total = context.findAncestorWidgetOfExactType<
                  StreamBuilder<List<RepairJob>>>() !=
              null
          ? count
          : 1;
      percentage = (count / total) * 100;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                '$count repairs',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage > 0 ? percentage / 100 : 0.05,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairTypeItem(
    BuildContext context,
    String title,
    int count,
    Color color,
  ) {
    // Calculate percentage based on total repair count
    double percentage = 0;
    if (count > 0) {
      // For simplicity, just use the count as a reference
      percentage = count > 10 ? 0.8 : count / 10;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$count repairs',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage > 0 ? percentage : 0.05,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

// Helper function to find minimum of two integers
int min(int a, int b) {
  return a < b ? a : b;
}
