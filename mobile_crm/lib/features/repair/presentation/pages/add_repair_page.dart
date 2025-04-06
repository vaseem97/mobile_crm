import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/repair_job_card.dart';
import '../../../../core/services/service_locator.dart';
import '../../data/repositories/repair_repository_impl.dart';
import '../../domain/entities/repair_job.dart';

class AddRepairPage extends StatefulWidget {
  const AddRepairPage({Key? key}) : super(key: key);

  @override
  State<AddRepairPage> createState() => _AddRepairPageState();
}

class _AddRepairPageState extends State<AddRepairPage> {
  final _formKey = GlobalKey<FormState>();
  final _repairRepository = getService<RepairRepositoryImpl>();

  // Customer Info
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  List<RepairJob>? _customerHistory;
  bool _isSearchingCustomer = false;
  bool _showCustomerHistory = false;

  // Device Info
  final _deviceModelController = TextEditingController();
  String? _selectedBrand;
  final _devicePasswordController = TextEditingController();
  String _passwordType = 'PIN';
  List<List<int>> _patternDots = [];
  List<String> _patternDescription = [];
  int? _startDot;

  // Device Images
  final List<File> _deviceImages = [];
  final _imagePicker = ImagePicker();

  // Repair Info
  final _estimatedCostController = TextEditingController();
  final _notesController = TextEditingController();
  final _selectedParts = <String>[];
  final _advanceAmountController = TextEditingController();
  final _customIssueController = TextEditingController();
  bool _isLoading = false;
  bool _canScanQR = false; // Feature flag for future QR scanner

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _deviceModelController.dispose();
    _devicePasswordController.dispose();
    _estimatedCostController.dispose();
    _notesController.dispose();
    _advanceAmountController.dispose();
    _customIssueController.dispose();
    super.dispose();
  }

  Future<void> _searchCustomerByPhone() async {
    if (_customerPhoneController.text.length < 10) return;

    setState(() {
      _isSearchingCustomer = true;
      _customerHistory = null;
      _showCustomerHistory = false;
    });

    try {
      final history = await _repairRepository
          .getRepairJobsByPhone(_customerPhoneController.text);

      if (mounted) {
        setState(() {
          _customerHistory = history;
          _isSearchingCustomer = false;
          _showCustomerHistory = history.isNotEmpty;
        });

        // Auto-fill customer name if we have history
        if (history.isNotEmpty && _customerNameController.text.isEmpty) {
          _customerNameController.text = history.first.customerName;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearchingCustomer = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching customer: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _deviceImages.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _deviceImages.removeAt(index);
    });
  }

  void _addPatternDot(int row, int col) {
    final List<int> dot = [row, col];
    final int dotIndex = row * 3 + col;

    setState(() {
      // If this is the first dot, mark it as start
      if (_patternDots.isEmpty) {
        _startDot = dotIndex;
      }

      _patternDots.add(dot);
      _patternDescription.add('${_getPositionName(row, col)}');
      _devicePasswordController.text = _patternDescription.join(' → ');
    });
  }

  String _getPositionName(int row, int col) {
    final positions = [
      ['Top-Left', 'Top-Center', 'Top-Right'],
      ['Middle-Left', 'Center', 'Middle-Right'],
      ['Bottom-Left', 'Bottom-Center', 'Bottom-Right'],
    ];
    return positions[row][col];
  }

  void _clearPattern() {
    setState(() {
      _patternDots = [];
      _patternDescription = [];
      _devicePasswordController.text = '';
      _startDot = null;
    });
  }

  Future<void> _submitForm() async {
    if (_selectedBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a device brand'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedParts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one issue or part to replace'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get estimated cost as double
      double estimatedCost = 0.0;
      if (_estimatedCostController.text.isNotEmpty) {
        estimatedCost = double.parse(_estimatedCostController.text);
      }

      // Get advance amount as double
      double advanceAmount = 0.0;
      if (_advanceAmountController.text.isNotEmpty) {
        advanceAmount = double.parse(_advanceAmountController.text);
      }

      // Create RepairJob entity
      final newRepair = RepairJob(
        id: '', // Will be generated by repository
        customerName: _customerNameController.text,
        customerPhone: _customerPhoneController.text,
        deviceModel: _deviceModelController.text,
        deviceBrand: _selectedBrand!,
        deviceColor: '', // Empty since we removed the field
        devicePassword: _devicePasswordController.text,
        deviceImei: '', // Empty since we removed the field
        problem: _selectedParts
            .join(', '), // Using selected parts as problem description
        partsToReplace: _selectedParts,
        estimatedCost: estimatedCost,
        advanceAmount:
            advanceAmount, // Add advance amount if available in RepairJob entity
        createdAt: DateTime.now(),
        status: RepairStatus.pending,
        notes: _notesController.text,
        // TODO: Upload images and save URLs
      );

      // Save to Firestore via repository
      final repairId = await _repairRepository.createRepairJob(newRepair);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Repair job #$repairId created successfully!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back with the new repair ID
        context.pop(repairId);
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scanCustomerQR() {
    // This will be implemented in the future
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR Scanner will be available in the next update'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showIssueSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Select Issues or Parts',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _customIssueController,
                            decoration: InputDecoration(
                              hintText: 'Enter custom issue or part',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  if (_customIssueController.text.isNotEmpty) {
                                    final newIssue =
                                        _customIssueController.text.trim();
                                    if (!_selectedParts.contains(newIssue)) {
                                      this.setState(() {
                                        _selectedParts.add(newIssue);
                                      });
                                      _customIssueController.clear();
                                    }
                                  }
                                },
                              ),
                            ),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                final newIssue = value.trim();
                                if (!_selectedParts.contains(newIssue)) {
                                  this.setState(() {
                                    _selectedParts.add(newIssue);
                                  });
                                  _customIssueController.clear();
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: AppConstants.commonRepairProblems.length,
                        itemBuilder: (context, index) {
                          final part = AppConstants.commonRepairProblems[index];
                          final isSelected = _selectedParts.contains(part);

                          return ListTile(
                            title: Text(part),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                    color: AppColors.primary)
                                : const Icon(Icons.circle_outlined),
                            onTap: () {
                              this.setState(() {
                                if (isSelected) {
                                  _selectedParts.remove(part);
                                } else {
                                  _selectedParts.add(part);
                                }
                              });
                              setState(() {}); // Update the modal state
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            tileColor: isSelected
                                ? AppColors.primary.withOpacity(0.1)
                                : null,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Done',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Repair'),
        actions: [
          if (_canScanQR)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _scanCustomerQR,
              tooltip: 'Scan Customer QR',
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _searchCustomerByPhone,
            tooltip: 'Search Existing Customer',
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCustomerInfo(),
                const Divider(height: 40, thickness: 1),
                _buildDeviceInfo(),
                const Divider(height: 40, thickness: 1),
                _buildRepairInfo(),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Submit Repair Job',
                  onPressed: _submitForm,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_outline, color: AppColors.primary),
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
        CustomTextField(
          label: 'Customer Name',
          hint: 'Enter customer name',
          controller: _customerNameController,
          textCapitalization: TextCapitalization.words,
          prefixIcon: const Icon(Icons.person),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter customer name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Phone Number',
          hint: 'Enter customer phone number',
          controller: _customerPhoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.phone),
          suffixIcon: _isSearchingCustomer
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchCustomerByPhone,
                ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter phone number';
            }
            if (value.length != 10) {
              return 'Phone number must be 10 digits';
            }
            return null;
          },
          onChanged: (value) {
            if (value.length == 10) {
              _searchCustomerByPhone();
            }
          },
        ),
        if (_showCustomerHistory) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Previous Repairs',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _customerHistory!.length,
                    itemBuilder: (context, index) {
                      final repair = _customerHistory![index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(
                            '${repair.deviceBrand} ${repair.deviceModel}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${repair.problem} • ${DateFormat('dd MMM yyyy').format(repair.createdAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(repair.status)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(repair.status),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getStatusColor(repair.status),
                              ),
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
        ],
        const SizedBox(height: 8),
        Text(
          'Note: Phone number will be used to identify returning customers',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
        ),
      ],
    );
  }

  Widget _buildDeviceInfo() {
    return Column(
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
        _buildDropdownField(
          label: 'Device Brand',
          value: _selectedBrand,
          items: AppConstants.deviceBrands,
          prefixIcon: const Icon(Icons.phone_android),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedBrand = value;
              });
            }
          },
          hint: 'Select device brand',
          isRequired: true,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Device Model',
          hint: 'Enter device model (e.g. iPhone 13 Pro)',
          controller: _deviceModelController,
          prefixIcon: const Icon(Icons.smartphone),
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter device model';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_outline, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Device Unlock Method',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(Optional)',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'PIN',
                    label: Text('PIN/Password'),
                    icon: Icon(Icons.pin),
                  ),
                  ButtonSegment<String>(
                    value: 'Pattern',
                    label: Text('Pattern'),
                    icon: Icon(Icons.pattern),
                  ),
                ],
                selected: {_passwordType},
                onSelectionChanged: (value) {
                  setState(() {
                    _passwordType = value.first;
                    _devicePasswordController.clear();
                    _patternDots = [];
                    _patternDescription = [];
                    _startDot = null;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (states) {
                      if (states.contains(MaterialState.selected)) {
                        return AppColors.primary.withOpacity(0.1);
                      }
                      return Colors.transparent;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_passwordType == 'PIN')
                CustomTextField(
                  label: 'Device Password/PIN',
                  hint: 'Enter device password or PIN',
                  controller: _devicePasswordController,
                  prefixIcon: const Icon(Icons.lock),
                )
              else
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Draw pattern by tapping dots in sequence',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 240,
                            height: 240,
                            child: Stack(
                              children: [
                                // Pattern line
                                if (_patternDots.length > 1)
                                  CustomPaint(
                                    size: const Size(240, 240),
                                    painter: PatternLinePainter(_patternDots),
                                  ),
                                // Dots grid
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
                                    final isDotSelected = _patternDots.any(
                                        (dot) =>
                                            dot[0] == row && dot[1] == col);
                                    final isStartDot = index == _startDot;
                                    final isEndDot = _patternDots.isNotEmpty &&
                                        _patternDots.last[0] == row &&
                                        _patternDots.last[1] == col;

                                    return GestureDetector(
                                      onTap: () => _addPatternDot(row, col),
                                      child: Center(
                                        child: Container(
                                          width: 50,
                                          height: 50,
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
                                          child: Center(
                                            child: isStartDot
                                                ? const Text(
                                                    'S',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  )
                                                : isEndDot
                                                    ? const Text(
                                                        'E',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      )
                                                    : isDotSelected
                                                        ? Text(
                                                            '${_patternDots.indexWhere((dot) => dot[0] == row && dot[1] == col) + 1}',
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          )
                                                        : null,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _clearPattern,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Clear Pattern'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_patternDescription.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Pattern: ${_patternDescription.join(' → ')}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(Icons.camera_alt, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Device Photos',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Take pictures of device damage or identifying marks',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _takePicture,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Take Photo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (_deviceImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '${_deviceImages.length} photo${_deviceImages.length > 1 ? 's' : ''} captured',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _deviceImages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    image: DecorationImage(
                      image: FileImage(_deviceImages[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRepairInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.build, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Repair Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Issues / Parts to Replace',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
            TextButton.icon(
              onPressed: _showIssueSelector,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Issues'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedParts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please select at least one issue or part to replace',
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedParts.map((part) {
              return Chip(
                label: Text(part),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _selectedParts.remove(part);
                  });
                },
                backgroundColor: AppColors.primary.withOpacity(0.1),
                labelStyle: TextStyle(color: AppColors.primary),
                deleteIconColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'Estimated Cost (₹)',
          hint: 'Enter estimated repair cost',
          controller: _estimatedCostController,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.currency_rupee),
          isRequired: true,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter estimated cost';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Advance Amount (₹)',
          hint: 'Enter advance payment (if any)',
          controller: _advanceAmountController,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.payment),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Additional Notes (Optional)',
          hint: 'Enter any additional notes or remarks',
          controller: _notesController,
          maxLines: 3,
          prefixIcon: const Icon(Icons.note),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    Widget? prefixIcon,
    required String hint,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value == null && isRequired
                  ? Colors.red.shade300
                  : const Color(0xFFEEEEEE),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                prefixIcon,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    hint: Text(
                      hint,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    items: items.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (value == null && isRequired) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              'Please select a brand',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getStatusText(RepairStatus status) {
    switch (status) {
      case RepairStatus.pending:
        return 'Pending';
      case RepairStatus.delivered:
        return 'Delivered';
    }
  }

  Color _getStatusColor(RepairStatus status) {
    switch (status) {
      case RepairStatus.pending:
        return AppColors.warning;
      case RepairStatus.delivered:
        return AppColors.primary;
    }
  }
}

// Custom painter to draw pattern lines
class PatternLinePainter extends CustomPainter {
  final List<List<int>> dots;

  PatternLinePainter(this.dots);

  @override
  void paint(Canvas canvas, Size size) {
    if (dots.length < 2) return;

    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Calculate the center of each cell
    final cellWidth = size.width / 3;
    final cellHeight = size.height / 3;

    // Start from the center of the first dot
    final firstDot = dots.first;
    double startX = (firstDot[1] * cellWidth) + (cellWidth / 2);
    double startY = (firstDot[0] * cellHeight) + (cellHeight / 2);

    path.moveTo(startX, startY);

    // Draw lines to each subsequent dot
    for (int i = 1; i < dots.length; i++) {
      final dot = dots[i];
      final x = (dot[1] * cellWidth) + (cellWidth / 2);
      final y = (dot[0] * cellHeight) + (cellHeight / 2);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
