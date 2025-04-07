import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/repair_job_card.dart';
import '../../../../core/services/service_locator.dart';
import '../../data/repositories/repair_repository_impl.dart';
import '../../domain/entities/repair_job.dart';
import 'dart:math';

class AddRepairPage extends StatefulWidget {
  const AddRepairPage({Key? key}) : super(key: key);

  @override
  State<AddRepairPage> createState() => _AddRepairPageState();
}

class _AddRepairPageState extends State<AddRepairPage> {
  final _formKey = GlobalKey<FormState>();
  final _repairRepository = getService<RepairRepositoryImpl>();
  final _scrollController = ScrollController();
  bool _isPatternActive = false;

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

  // Repair Info
  final _estimatedCostController = TextEditingController();
  final _notesController = TextEditingController();
  final _selectedParts = <String>[];
  final _advanceAmountController = TextEditingController();
  final _customIssueController = TextEditingController();
  bool _isLoading = false;
  bool _canScanQR = false; // Feature flag for future QR scanner
  String? _selectedWarranty; // <-- Add state variable for warranty

  // Add these new methods for pattern drawing
  void _handlePatternStart(Offset position) {
    setState(() {
      _clearPattern(); // Clear existing pattern when starting a new one
      _isDragging = true;
      _isPatternActive = true;

      // Find the closest dot to the touch point
      final cellSize = 240 / 3;
      final row = (position.dy / cellSize).floor().clamp(0, 2);
      final col = (position.dx / cellSize).floor().clamp(0, 2);

      _addPatternDot(row, col);
    });
  }

  void _handlePatternUpdate(Offset position) {
    if (!_isDragging) return;

    // Calculate which cell the user is hovering over
    final cellSize = 240 / 3;
    final row = (position.dy / cellSize).floor().clamp(0, 2);
    final col = (position.dx / cellSize).floor().clamp(0, 2);

    // Check if this is a new dot that's not already in the pattern
    final List<int> newDot = [row, col];
    bool isDotAlreadySelected = _patternDots.any(
      (dot) => dot[0] == row && dot[1] == col,
    );

    // Only add the dot if it's new
    if (!isDotAlreadySelected) {
      // If there are existing dots, check if we need to add dots in between
      if (_patternDots.isNotEmpty) {
        final lastDot = _patternDots.last;
        final rowDiff = row - lastDot[0];
        final colDiff = col - lastDot[1];

        // First check for special connections like diagonal through center
        if (_canConnectDots(lastDot[0], lastDot[1], row, col)) {
          // Special connection handled by the helper method
        }
        // Then check if we need to add intermediate dots for other connections
        else if (rowDiff.abs() > 1 || colDiff.abs() > 1) {
          // Add intermediate dots for smoother pattern
          _addIntermediateDots(lastDot[0], lastDot[1], row, col);
        }
      }

      _addPatternDot(row, col);
    }
  }

  void _handlePatternEnd() {
    setState(() {
      _isDragging = false;
      _isPatternActive = false;
    });
  }

  void _addIntermediateDots(
      int startRow, int startCol, int endRow, int endCol) {
    // Calculate the number of steps needed
    final rowDiff = endRow - startRow;
    final colDiff = endCol - startCol;
    final steps = max(rowDiff.abs(), colDiff.abs());

    // Add dots along the path
    for (int i = 1; i < steps; i++) {
      final ratio = i / steps;
      // Use precise casting to ensure accurate intermediate positions
      final intermediateRow = startRow + (rowDiff * ratio).round();
      final intermediateCol = startCol + (colDiff * ratio).round();

      // Ensure we're within grid bounds
      if (intermediateRow >= 0 &&
          intermediateRow <= 2 &&
          intermediateCol >= 0 &&
          intermediateCol <= 2) {
        // Check if this dot is already selected
        bool isDotAlreadySelected = _patternDots.any(
          (dot) => dot[0] == intermediateRow && dot[1] == intermediateCol,
        );

        if (!isDotAlreadySelected) {
          _addPatternDot(intermediateRow, intermediateCol);
        }
      }
    }
  }

  // Simplified helper method to handle specific dot connections that might be missed
  bool _canConnectDots(int startRow, int startCol, int endRow, int endCol) {
    // Calculate the differences for L-shape detection
    final int rowDiff = endRow - startRow;
    final int colDiff = endCol - startCol;

    // Common problematic connections like connecting 1→5→9 or 3→5→7
    // Check for diagonal through center
    if ((startRow == 0 && startCol == 0 && endRow == 2 && endCol == 2) || // 1→9
        (startRow == 0 && startCol == 2 && endRow == 2 && endCol == 0) || // 3→7
        (startRow == 2 && startCol == 0 && endRow == 0 && endCol == 2) || // 7→3
        (startRow == 2 && startCol == 2 && endRow == 0 && endCol == 0)) {
      // 9→1

      // Add the center dot (5) if not already in the pattern
      bool hasCenterDot = _patternDots.any((dot) => dot[0] == 1 && dot[1] == 1);
      if (!hasCenterDot) {
        _addPatternDot(1, 1); // Add center dot (row 1, col 1)
      }
      return true;
    }

    // Knight moves (L-shapes) - need to add intermediate dots
    if ((rowDiff.abs() == 2 && colDiff.abs() == 1) ||
        (rowDiff.abs() == 1 && colDiff.abs() == 2)) {
      return true;
    }

    return false;
  }

  // Add _isDragging variable to the state
  bool _isDragging = false;

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
    _scrollController.dispose();
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

    String? tempRepairId;

    try {
      // Show initial loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Creating repair job...'),
          duration: Duration(seconds: 60),
          backgroundColor: Colors.grey,
        ),
      );

      // 1. Prepare RepairJob data
      double estimatedCost = 0.0;
      if (_estimatedCostController.text.isNotEmpty) {
        estimatedCost = double.parse(_estimatedCostController.text);
      }
      double advanceAmount = 0.0;
      if (_advanceAmountController.text.isNotEmpty) {
        advanceAmount = double.parse(_advanceAmountController.text);
      }

      final newRepairData = RepairJob(
        id: 'TEMP_ID',
        customerName: _customerNameController.text,
        customerPhone: _customerPhoneController.text,
        deviceModel: _deviceModelController.text,
        deviceBrand: _selectedBrand!,
        deviceColor: '',
        devicePassword:
            _passwordType == 'PIN' ? _devicePasswordController.text : '',
        devicePattern:
            _passwordType == 'Pattern' ? _devicePasswordController.text : '',
        deviceImei: '',
        problem: _selectedParts.join(', '),
        partsToReplace: _selectedParts,
        estimatedCost: estimatedCost,
        advanceAmount: advanceAmount,
        createdAt: DateTime.now(),
        status: RepairStatus.pending,
        notes: _notesController.text,
        imageUrls: [], // Empty list for now
        warrantyPeriod: _selectedWarranty,
      );

      // 2. Create document in Firestore
      tempRepairId = await _repairRepository.createRepairJob(newRepairData);
      print('Repair document created with ID: $tempRepairId');

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (mounted) {
        // Show final success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Repair job #$tempRepairId created successfully!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back with the new repair ID
        context.pop(tempRepairId);
      }
    } catch (e) {
      print('Error during repair job creation: ${e.toString()}');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (mounted) {
        // Show detailed error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating repair job: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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

  void _showPatternDialog() async {
    // Temporarily store the current pattern in case the user cancels
    final initialPatternDots =
        List<List<int>>.from(_patternDots.map((dot) => List<int>.from(dot)));
    final initialPatternDescription = List<String>.from(_patternDescription);
    final initialDevicePasswordText = _devicePasswordController.text;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (context) {
        // Local state management for the dialog
        List<List<int>> currentDots = List<List<int>>.from(
            initialPatternDots.map((dot) => List<int>.from(dot)));
        List<String> currentDescription =
            List<String>.from(initialPatternDescription);
        bool isDialogDragging = false;

        // Helper functions specific to the dialog's state
        String getPositionNameDialog(int row, int col) {
          final positions = [
            ['Top-Left', 'Top-Center', 'Top-Right'],
            ['Middle-Left', 'Center', 'Middle-Right'],
            ['Bottom-Left', 'Bottom-Center', 'Bottom-Right'],
          ];
          return positions[row][col];
        }

        void addPatternDotDialog(
            int row, int col, Function(Function()) setStateDialog) {
          setStateDialog(() {
            currentDots.add([row, col]);
            currentDescription.add(getPositionNameDialog(row, col));
          });
        }

        void clearPatternDialog(Function(Function()) setStateDialog) {
          setStateDialog(() {
            currentDots = [];
            currentDescription = [];
          });
        }

        // Intermediate dot logic specifically for the dialog
        void addIntermediateDotsDialog(int startRow, int startCol, int endRow,
            int endCol, Function(Function()) setStateDialog) {
          final rowDiff = endRow - startRow;
          final colDiff = endCol - startCol;
          final steps = max(rowDiff.abs(), colDiff.abs());

          for (int i = 1; i < steps; i++) {
            final ratio = i / steps;
            final intermediateRow = (startRow + (rowDiff * ratio)).round();
            final intermediateCol = (startCol + (colDiff * ratio)).round();

            if (intermediateRow >= 0 &&
                intermediateRow <= 2 &&
                intermediateCol >= 0 &&
                intermediateCol <= 2) {
              bool isDotAlreadySelected = currentDots.any((dot) =>
                  dot[0] == intermediateRow && dot[1] == intermediateCol);
              if (!isDotAlreadySelected) {
                // Special check for diagonals passing *through* center
                if (rowDiff.abs() == 2 &&
                    colDiff.abs() == 2 &&
                    intermediateRow == 1 &&
                    intermediateCol == 1) {
                  addPatternDotDialog(
                      intermediateRow, intermediateCol, setStateDialog);
                }
                // Check for standard intermediate dots (not just diagonal center)
                else if ((rowDiff.abs() > 0 || colDiff.abs() > 0) &&
                    !(rowDiff.abs() == 2 && colDiff.abs() == 2)) {
                  addPatternDotDialog(
                      intermediateRow, intermediateCol, setStateDialog);
                }
              }
            }
          }
        }

        // Handle gesture updates within the dialog
        void handlePatternStartDialog(
            Offset position, Function(Function()) setStateDialog) {
          setStateDialog(() {
            clearPatternDialog(setStateDialog);
            isDialogDragging = true;
            final cellSize = 240.0 / 3;
            final row = (position.dy / cellSize).floor().clamp(0, 2);
            final col = (position.dx / cellSize).floor().clamp(0, 2);
            addPatternDotDialog(row, col, setStateDialog);
          });
        }

        void handlePatternUpdateDialog(
            Offset position, Function(Function()) setStateDialog) {
          if (!isDialogDragging) return;

          final cellSize = 240.0 / 3;
          final row = (position.dy / cellSize).floor().clamp(0, 2);
          final col = (position.dx / cellSize).floor().clamp(0, 2);

          bool isDotAlreadySelected =
              currentDots.any((dot) => dot[0] == row && dot[1] == col);

          if (!isDotAlreadySelected) {
            if (currentDots.isNotEmpty) {
              final lastDot = currentDots.last;
              addIntermediateDotsDialog(
                  lastDot[0], lastDot[1], row, col, setStateDialog);
            }
            addPatternDotDialog(row, col, setStateDialog);
          }
        }

        void handlePatternEndDialog(Function(Function()) setStateDialog) {
          setStateDialog(() {
            isDialogDragging = false;
          });
        }

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Draw Device Pattern'),
              contentPadding: const EdgeInsets.all(16),
              content: SingleChildScrollView(
                // Prevents overflow if content is large
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentDescription.isEmpty
                          ? 'Connect the dots to create a pattern.'
                          : 'Pattern: ${currentDescription.join(' → ')}',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: currentDescription.isEmpty
                              ? Colors.grey
                              : AppColors.primary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: GestureDetector(
                        behavior: HitTestBehavior
                            .opaque, // Important for accurate hit testing
                        onPanStart: (details) => handlePatternStartDialog(
                            details.localPosition, setStateDialog),
                        onPanUpdate: (details) => handlePatternUpdateDialog(
                            details.localPosition, setStateDialog),
                        onPanEnd: (_) => handlePatternEndDialog(setStateDialog),
                        child: Stack(
                          children: [
                            // Pattern line
                            if (currentDots.length > 1)
                              CustomPaint(
                                size: const Size(240, 240),
                                painter: PatternLinePainter(currentDots),
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
                                final isDotSelected = currentDots.any(
                                    (dot) => dot[0] == row && dot[1] == col);
                                final isStartDot = currentDots.isNotEmpty &&
                                    currentDots.first[0] == row &&
                                    currentDots.first[1] == col;
                                final isEndDot = currentDots.isNotEmpty &&
                                    currentDots.last[0] == row &&
                                    currentDots.last[1] == col;
                                final dotIndex = currentDots.indexWhere(
                                    (dot) => dot[0] == row && dot[1] == col);

                                return Center(
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
                                          ? const Text('S',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold))
                                          : isEndDot
                                              ? const Text('E',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold))
                                              : isDotSelected
                                                  ? Text('${dotIndex + 1}',
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold))
                                                  : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => clearPatternDialog(setStateDialog),
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context), // Cancel
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: currentDots.length >= 4 // Require at least 4 dots
                      ? () {
                          // Return the pattern description string
                          Navigator.pop(
                              context, currentDescription.join(' → '));
                        }
                      : null, // Disable if pattern is too short
                  child: const Text('Save Pattern'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // Update the main page state if a pattern was saved
    if (result != null) {
      setState(() {
        _devicePasswordController.text = result;
        // Update the main state's pattern dots/description for consistency
        // (though they are mainly managed visually by the dialog now)
        _patternDescription = result.split(' → ');
        // Potentially reconstruct _patternDots from result if needed elsewhere
      });
    } else {
      // User cancelled, revert to the initial state if needed (optional)
      // setState(() {
      //   _patternDots = initialPatternDots;
      //   _patternDescription = initialPatternDescription;
      //   _devicePasswordController.text = initialDevicePasswordText;
      // });
    }
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
            controller: _scrollController,
            physics: _isPatternActive
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
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
              else // Pattern selected
                Column(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit_attributes),
                      label: Text(_patternDescription.isEmpty
                          ? 'Set Device Pattern'
                          : 'Edit Pattern'),
                      onPressed: _showPatternDialog,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                            color: AppColors.primary.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    if (_patternDescription.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.2))),
                        child: Text(
                          'Current Pattern: ${_patternDescription.join(' → ')}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
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
        // Add Warranty Dropdown Here
        _buildDropdownField(
          label: 'Warranty Period (Optional)',
          value: _selectedWarranty,
          items: AppConstants.warrantyOptions,
          prefixIcon: const Icon(Icons.shield_outlined),
          onChanged: (value) {
            setState(() {
              _selectedWarranty = value;
            });
          },
          hint: 'Select warranty period',
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
