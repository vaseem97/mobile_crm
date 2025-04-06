import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../features/repair/data/repositories/repair_repository_impl.dart';
import '../../../../features/repair/domain/entities/repair_job.dart';
import '../../../../core/widgets/repair_job_card.dart';

class DashboardStatsTab extends StatefulWidget {
  const DashboardStatsTab({Key? key}) : super(key: key);

  @override
  State<DashboardStatsTab> createState() => _DashboardStatsTabState();
}

class _DashboardStatsTabState extends State<DashboardStatsTab> {
  final _repairRepository = getService<RepairRepositoryImpl>();
  bool _isLoading = true;
  String? _errorMessage;

  // Dashboard statistics
  int _totalRepairs = 0;
  int _pendingCount = 0;
  int _inProgressCount = 0;
  int _completedCount = 0;
  double _totalRevenue = 0;
  Map<String, int> _deviceBrands = {};
  Map<String, int> _repairTypes = {};

  String _selectedPeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get all repairs
      final allRepairs = await _repairRepository.getRepairJobs();

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
      final deliveredRepairs = filteredRepairs
          .where((r) => r.status == RepairStatus.delivered)
          .toList();

      final revenue = deliveredRepairs.fold(
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

      if (mounted) {
        setState(() {
          _totalRepairs = filteredRepairs.length;
          _pendingCount = pendingRepairs.length;
          _inProgressCount = 0;
          _completedCount = 0;
          _totalRevenue = revenue;
          _deviceBrands = sortedDeviceBrands;
          _repairTypes = sortedRepairTypes;
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const SizedBox(
                height: 500,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : _errorMessage != null
                ? SizedBox(
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
                            _errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadStatistics,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodSelector(context),
                      const SizedBox(height: 24),
                      _buildRevenueStats(context),
                      const SizedBox(height: 24),
                      _buildRepairStats(context),
                      const SizedBox(height: 24),
                      _buildDeviceDistribution(context),
                      const SizedBox(height: 24),
                      _buildCommonRepairTypes(context),
                    ],
                  ),
      ),
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
                    _loadStatistics();
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

  Widget _buildRevenueStats(BuildContext context) {
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
                      '₹${_totalRevenue.toStringAsFixed(0)}',
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

  Widget _buildRepairStats(BuildContext context) {
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
                    _totalRepairs.toString(),
                    'Total Repairs',
                    AppColors.primary,
                  ),
                ),
                InkWell(
                  onTap: () => context.push('/repairs/pending'),
                  child: _buildRepairStat(
                    context,
                    _pendingCount.toString(),
                    'Pending',
                    AppColors.warning,
                  ),
                ),
                InkWell(
                  onTap: () => context.push('/repairs/completed'),
                  child: _buildRepairStat(
                    context,
                    _completedCount.toString(),
                    'Completed',
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

  Widget _buildDeviceDistribution(BuildContext context) {
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
            _deviceBrands.isEmpty
                ? _buildEmptyStateMessage('No device data available')
                : Column(
                    children: _deviceBrands.entries.take(5).map((entry) {
                      return _buildDistributionItem(
                        context,
                        entry.key,
                        entry.value,
                        _totalRepairs > 0 ? entry.value / _totalRepairs : 0,
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

  Widget _buildCommonRepairTypes(BuildContext context) {
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
            _repairTypes.isEmpty
                ? _buildEmptyStateMessage('No repair type data available')
                : Column(
                    children: _repairTypes.entries.take(5).map((entry) {
                      return _buildRepairTypeItem(
                        context,
                        entry.key,
                        entry.value,
                        _totalRepairs > 0
                            ? entry.value * 100 ~/ _totalRepairs
                            : 0,
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
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDistributionItem(
    BuildContext context,
    String label,
    int count,
    double percentage,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                '$count devices (${(percentage * 100).toInt()}%)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              color: color,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairTypeItem(
    BuildContext context,
    String type,
    int count,
    int percentage,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              type,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Text(
            '$count ($percentage%)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
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
