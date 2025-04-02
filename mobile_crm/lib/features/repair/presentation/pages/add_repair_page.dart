import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/repair_job_card.dart';

class AddRepairPage extends StatefulWidget {
  const AddRepairPage({Key? key}) : super(key: key);

  @override
  State<AddRepairPage> createState() => _AddRepairPageState();
}

class _AddRepairPageState extends State<AddRepairPage> {
  final _formKey = GlobalKey<FormState>();

  // Customer Info
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();

  // Device Info
  final _deviceModelController = TextEditingController();
  String _selectedBrand = AppConstants.deviceBrands.first;
  String _selectedColor = AppConstants.deviceColors.first;
  final _devicePasswordController = TextEditingController();
  final _deviceImeiController = TextEditingController();

  // Repair Info
  final _problemController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _estimatedCostController = TextEditingController();
  final _notesController = TextEditingController();
  final _selectedParts = <String>[];
  bool _isLoading = false;

  // Steps
  int _currentStep = 0;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _deviceModelController.dispose();
    _devicePasswordController.dispose();
    _deviceImeiController.dispose();
    _problemController.dispose();
    _diagnosisController.dispose();
    _estimatedCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Here we would store the data in Firebase
      // For now just navigate back to dashboard
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Repair job created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );

        context.pop();
      });
    }
  }

  void _next() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previous() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Repair'),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepTapped: (step) {
            setState(() {
              _currentStep = step;
            });
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: CustomButton(
                        text: 'Previous',
                        onPressed: _previous,
                        isOutlined: true,
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: _currentStep == 2 ? 'Submit' : 'Next',
                      onPressed: _currentStep == 2 ? _submitForm : _next,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Customer'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: _buildCustomerInfoStep(),
            ),
            Step(
              title: const Text('Device'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: _buildDeviceInfoStep(),
            ),
            Step(
              title: const Text('Repair'),
              isActive: _currentStep >= 2,
              state: _currentStep == 3 ? StepState.complete : StepState.indexed,
              content: _buildRepairInfoStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'Customer Name',
          hint: 'Enter customer name',
          controller: _customerNameController,
          textCapitalization: TextCapitalization.words,
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
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Email (Optional)',
          hint: 'Enter customer email',
          controller: _customerEmailController,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Please enter a valid email';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDeviceInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownField(
          label: 'Device Brand',
          value: _selectedBrand,
          items: AppConstants.deviceBrands,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedBrand = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Device Model',
          hint: 'Enter device model (e.g. iPhone 13 Pro)',
          controller: _deviceModelController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter device model';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Device Color',
          value: _selectedColor,
          items: AppConstants.deviceColors,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedColor = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Device Password (Optional)',
          hint: 'Enter device password or pattern',
          controller: _devicePasswordController,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'IMEI Number (Optional)',
          hint: 'Enter device IMEI number',
          controller: _deviceImeiController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
      ],
    );
  }

  Widget _buildRepairInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'Problem Description',
          hint: 'Describe the issue with the device',
          controller: _problemController,
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please describe the problem';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Initial Diagnosis (Optional)',
          hint: 'Enter initial diagnosis if any',
          controller: _diagnosisController,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildPartsSelector(),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Estimated Cost (₹)',
          hint: 'Enter estimated repair cost',
          controller: _estimatedCostController,
          keyboardType: TextInputType.number,
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
          label: 'Additional Notes (Optional)',
          hint: 'Enter any additional notes or remarks',
          controller: _notesController,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
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
    );
  }

  Widget _buildPartsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parts to Replace (Optional)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.commonRepairProblems.map((part) {
            final isSelected = _selectedParts.contains(part);
            return FilterChip(
              label: Text(part),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedParts.add(part);
                  } else {
                    _selectedParts.remove(part);
                  }
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color:
                      isSelected ? AppColors.primary : const Color(0xFFEEEEEE),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
