import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/repair_job_card.dart';
import '../../../repair/data/repositories/repair_repository_impl.dart';
import '../../../repair/domain/entities/repair_job.dart';

class InvoiceSelectionPage extends StatefulWidget {
  const InvoiceSelectionPage({Key? key}) : super(key: key);

  @override
  State<InvoiceSelectionPage> createState() => _InvoiceSelectionPageState();
}

class _InvoiceSelectionPageState extends State<InvoiceSelectionPage> {
  final _repairRepository = getService<RepairRepositoryImpl>();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  RepairStatus _selectedStatus = RepairStatus.returned;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Repair for Invoice'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatusFilter(),
          Expanded(
            child: _buildRepairsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by customer name or repair ID',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          const Text(
            'Status:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          ChoiceChip(
            label: const Text('Returned'),
            selected: _selectedStatus == RepairStatus.returned,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedStatus = RepairStatus.returned;
                });
              }
            },
            backgroundColor: Colors.grey.shade200,
            selectedColor: AppColors.success.withOpacity(0.2),
            labelStyle: TextStyle(
              color: _selectedStatus == RepairStatus.returned
                  ? AppColors.success
                  : Colors.black87,
              fontWeight: _selectedStatus == RepairStatus.returned
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Pending'),
            selected: _selectedStatus == RepairStatus.pending,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedStatus = RepairStatus.pending;
                });
              }
            },
            backgroundColor: Colors.grey.shade200,
            selectedColor: AppColors.warning.withOpacity(0.2),
            labelStyle: TextStyle(
              color: _selectedStatus == RepairStatus.pending
                  ? AppColors.warning
                  : Colors.black87,
              fontWeight: _selectedStatus == RepairStatus.pending
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairsList() {
    return StreamBuilder<List<RepairJob>>(
      stream: _repairRepository.getRepairJobsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
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
                  'Error loading repairs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final allRepairs = snapshot.data ?? [];
        
        // Filter by status
        final filteredByStatus = allRepairs
            .where((repair) => repair.status == _selectedStatus)
            .toList();
        
        // Filter by search query
        final filteredRepairs = _searchQuery.isEmpty
            ? filteredByStatus
            : filteredByStatus.where((repair) {
                final query = _searchQuery.toLowerCase();
                return repair.customerName.toLowerCase().contains(query) ||
                    repair.id.toLowerCase().contains(query) ||
                    repair.deviceBrand.toLowerCase().contains(query) ||
                    repair.deviceModel.toLowerCase().contains(query);
              }).toList();
        
        if (filteredRepairs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No repairs found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Try a different search term'
                      : 'Try selecting a different status',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                ),
              ],
            ),
          );
        }
        
        // Sort by date (newest first)
        filteredRepairs.sort((a, b) {
          final aDate = a.createdAt;
          final bDate = b.createdAt;
          return bDate.compareTo(aDate);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredRepairs.length,
          itemBuilder: (context, index) {
            final repair = filteredRepairs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  context.push('/invoice-preview/${repair.id}');
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: repair.status == RepairStatus.returned
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              repair.status == RepairStatus.returned
                                  ? Icons.check_circle
                                  : Icons.pending_actions,
                              color: repair.status == RepairStatus.returned
                                  ? AppColors.success
                                  : AppColors.warning,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  repair.id,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                ),
                                Text(
                                  repair.customerName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  '${repair.deviceBrand} ${repair.deviceModel}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                NumberFormat.currency(
                                  symbol: '₹',
                                  decimalDigits: 0,
                                ).format(repair.estimatedCost),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                              ),
                              Text(
                                DateFormat('dd MMM yyyy').format(repair.createdAt),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              context.push('/invoice-preview/${repair.id}');
                            },
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('Generate Invoice'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
