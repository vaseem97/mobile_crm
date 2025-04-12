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
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<RepairJob>>(
      stream: _repairRepository.getRepairJobsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: colorScheme.primary,
            ),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 500,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: colorScheme.error,
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
                  FilledButton.tonal(
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
          color: colorScheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              'Statistics For:',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: colorScheme.outline.withOpacity(0.5)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down,
                        color: colorScheme.primary),
                    elevation: 2,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedPeriod = newValue;
                        });
                      }
                    },
                    items: <String>[
                      'Today',
                      'This Week',
                      'This Month',
                      'This Year'
                    ].map<DropdownMenuItem<String>>((String value) {
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
        ),
      ),
    );
  }

  Widget _buildRevenueStats(BuildContext context, double totalRevenue) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Revenue Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                ),
                Icon(
                  Icons.trending_up_rounded,
                  color: colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.currency_rupee,
                    size: 36,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${totalRevenue.toStringAsFixed(0)}',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Revenue for $_selectedPeriod',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Repair Statistics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onBackground,
                ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => context.push('/repairs/pending'),
                borderRadius: BorderRadius.circular(20),
                child: Card(
                  elevation: 0,
                  color: colorScheme.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildRepairStat(
                      context,
                      totalRepairs.toString(),
                      'Total Repairs',
                      colorScheme.onPrimaryContainer,
                      Icons.build_rounded,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => context.push('/repairs/pending'),
                borderRadius: BorderRadius.circular(20),
                child: Card(
                  elevation: 0,
                  color: colorScheme.tertiaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildRepairStat(
                      context,
                      pendingCount.toString(),
                      'Pending',
                      colorScheme.onTertiaryContainer,
                      Icons.pending_actions_rounded,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => context.push('/repairs/returned'),
          borderRadius: BorderRadius.circular(20),
          child: Card(
            elevation: 0,
            color: colorScheme.secondaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.onSecondaryContainer.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        completedCount.toString(),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                      ),
                      Text(
                        'Completed Repairs',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                            ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: colorScheme.onSecondaryContainer.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepairStat(
    BuildContext context,
    String count,
    String title,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeviceDistribution(
      BuildContext context, Map<String, int> deviceBrands) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Device Distribution',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                ),
                Icon(
                  Icons.phone_android_rounded,
                  color: colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            deviceBrands.isEmpty
                ? _buildEmptyStateMessage('No device data available')
                : Column(
                    children: deviceBrands.entries.take(5).map((entry) {
                      return _buildDistributionItem(
                        context,
                        entry.key,
                        entry.value,
                        _getColorForBrand(entry.key, colorScheme),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Color _getColorForBrand(String brand, ColorScheme colorScheme) {
    final brandColors = {
      'Samsung': colorScheme.primary,
      'Apple': colorScheme.tertiary,
      'Xiaomi': colorScheme.secondary,
      'Oppo': colorScheme.primary.withBlue(180),
      'Vivo': colorScheme.tertiary.withRed(120),
      'OnePlus': colorScheme.error,
      'Realme': colorScheme.tertiary.withGreen(180),
      'Nokia': colorScheme.primary.withBlue(230),
    };

    return brandColors[brand] ?? colorScheme.primary;
  }

  Widget _buildCommonRepairTypes(
      BuildContext context, Map<String, int> repairTypes) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Common Repair Types',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                ),
                Icon(
                  Icons.handyman_rounded,
                  color: colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            repairTypes.isEmpty
                ? _buildEmptyStateMessage('No repair type data available')
                : Column(
                    children: repairTypes.entries.take(5).map((entry) {
                      return _buildRepairTypeItem(
                        context,
                        entry.key,
                        entry.value,
                        _getColorForRepairType(entry.key, colorScheme),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Color _getColorForRepairType(String type, ColorScheme colorScheme) {
    final typeColors = {
      'Screen': colorScheme.primary,
      'Battery': colorScheme.secondary,
      'Charging': colorScheme.tertiary,
      'Water': colorScheme.error,
      'Software': colorScheme.primary.withGreen(180),
    };

    // Find a matching type
    for (var key in typeColors.keys) {
      if (type.toLowerCase().contains(key.toLowerCase())) {
        return typeColors[key]!;
      }
    }

    return colorScheme.primary;
  }

  Widget _buildEmptyStateMessage(String message) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: colorScheme.outline,
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: colorScheme.outline,
                fontSize: 16,
              ),
            ),
          ],
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
    final colorScheme = Theme.of(context).colorScheme;

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
                      color: colorScheme.onSurface,
                    ),
              ),
              Text(
                '$count repairs',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage > 0 ? percentage / 100 : 0.05,
              backgroundColor: colorScheme.surfaceVariant,
              color: color,
              minHeight: 10,
            ),
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
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate percentage based on total repair count
    double percentage = 0;
    if (count > 0) {
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
                        color: colorScheme.onSurface,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$count repairs',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage > 0 ? percentage : 0.05,
              backgroundColor: colorScheme.surfaceVariant,
              color: color,
              minHeight: 10,
            ),
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
