import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/customer.dart';
import '../../../../shared/widgets/app_button.dart';

class UpperCaseTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class CustomerDetailsPage extends StatefulWidget {
  final String customerId;
  
  const CustomerDetailsPage({
    super.key,
    required this.customerId,
  });

  @override
  State<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _gstController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _creditLimitController = TextEditingController();

  String _selectedCustomerType = 'retail';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _isActive = true;
  Customer? _customer;

  final List<String> _customerTypes = ['retail', 'wholesale', 'contractor'];
  final List<String> _states = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
    'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
    'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
    'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
    'Uttar Pradesh', 'Uttarakhand', 'West Bengal'
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomerDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerDetails() async {
    try {
      final response = await apiService.getCustomer(widget.customerId);
      
      if (response['success']) {
        final customer = Customer.fromJson(response['data']['customer']);
        setState(() {
          _customer = customer;
          _populateFormFields(customer);
          _isLoading = false;
        });
      } else {
        _showErrorSnackBar('Failed to load customer details');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred while loading customer details');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFormFields(Customer customer) {
    _nameController.text = customer.displayName;
    _emailController.text = customer.email;
    _phoneController.text = customer.phoneNumber;
    _companyController.text = customer.companyName ?? '';
    _gstController.text = customer.gstNumber ?? '';
    _addressController.text = customer.address ?? '';
    _cityController.text = customer.city ?? '';
    _stateController.text = customer.state ?? '';
    _pincodeController.text = customer.pincode ?? '';
    _creditLimitController.text = customer.creditLimit.toString();
    _selectedCustomerType = customer.customerType;
    _isActive = customer.isActive;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Container(
        color: AppColors.background,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_customer == null) {
      return Container(
        color: AppColors.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error500,
              ),
              const SizedBox(height: 16),
              Text(
                'Customer not found',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.error500,
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Go Back',
                onPressed: () => context.go('/customers'),
                style: AppButtonStyle.primary,
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button and edit action
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => context.go('/customers'),
                  ),
                  Expanded(
                    child: Text(
                      'Customer Details',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!_isEditing)
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),
              _buildBasicInfoSection(theme),
              const SizedBox(height: 24),
              _buildBusinessInfoSection(theme),
              const SizedBox(height: 24),
              _buildAddressSection(theme),
              const SizedBox(height: 24),
              _buildFinancialSection(theme),
              const SizedBox(height: 32),
              _buildActionButtons(theme),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildBasicInfoSection(ThemeData theme) {
    return _buildSection(
      theme,
      'Basic Information',
      Icons.person,
      [
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter customer full name',
          icon: Icons.person,
          enabled: _isEditing,
          validator: _isEditing ? (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Name is required';
            }
            if (value.trim().length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          } : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'Enter email address',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          enabled: _isEditing,
          validator: _isEditing ? (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email is required';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          } : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'Enter phone number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          enabled: _isEditing,
          inputFormatters: _isEditing ? [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ] : null,
          validator: _isEditing ? (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Phone number is required';
            }
            if (value.length < 10) {
              return 'Phone number must be 10 digits';
            }
            return null;
          } : null,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Customer Type',
          value: _selectedCustomerType,
          items: _customerTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.toUpperCase()),
            );
          }).toList(),
          onChanged: _isEditing ? (value) {
            setState(() {
              _selectedCustomerType = value!;
            });
          } : null,
          icon: Icons.category,
          enabled: _isEditing,
        ),
      ],
    );
  }

  Widget _buildBusinessInfoSection(ThemeData theme) {
    return _buildSection(
      theme,
      'Business Information',
      Icons.business,
      [
        _buildTextField(
          controller: _companyController,
          label: 'Company/Store Name',
          hint: 'Enter company or store name',
          icon: Icons.business,
          enabled: _isEditing,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _gstController,
          label: 'GST Number',
          hint: 'Enter GST number (optional)',
          icon: Icons.receipt,
          enabled: _isEditing,
          inputFormatters: _isEditing ? [
            UpperCaseTextInputFormatter(),
            LengthLimitingTextInputFormatter(15),
          ] : null,
        ),
      ],
    );
  }

  Widget _buildAddressSection(ThemeData theme) {
    return _buildSection(
      theme,
      'Address Information',
      Icons.location_on,
      [
        _buildTextField(
          controller: _addressController,
          label: 'Address',
          hint: 'Enter complete address',
          icon: Icons.home,
          maxLines: 2,
          enabled: _isEditing,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildTextField(
                controller: _cityController,
                label: 'City',
                hint: 'Enter city',
                icon: Icons.location_city,
                enabled: _isEditing,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: _buildDropdownField(
                label: 'State',
                value: _stateController.text.isEmpty ? null : _stateController.text,
                items: _states.map((state) {
                  return DropdownMenuItem(
                    value: state,
                    child: Text(
                      state,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: _isEditing ? (value) {
                  setState(() {
                    _stateController.text = value ?? '';
                  });
                } : null,
                icon: Icons.map,
                enabled: _isEditing,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _pincodeController,
          label: 'Pincode',
          hint: 'Enter pincode',
          icon: Icons.pin_drop,
          keyboardType: TextInputType.number,
          enabled: _isEditing,
          inputFormatters: _isEditing ? [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ] : null,
        ),
      ],
    );
  }

  Widget _buildFinancialSection(ThemeData theme) {
    return _buildSection(
      theme,
      'Financial Information',
      Icons.account_balance_wallet,
      [
        _buildTextField(
          controller: _creditLimitController,
          label: 'Credit Limit',
          hint: 'Enter credit limit amount',
          icon: Icons.credit_card,
          keyboardType: TextInputType.number,
          enabled: _isEditing,
          inputFormatters: _isEditing ? [
            FilteringTextInputFormatter.digitsOnly,
          ] : null,
          validator: _isEditing ? (value) {
            if (value != null && value.isNotEmpty) {
              final amount = double.tryParse(value);
              if (amount == null || amount < 0) {
                return 'Please enter a valid amount';
              }
            }
            return null;
          } : null,
        ),
        const SizedBox(height: 16),
        _buildSwitchField(
          label: 'Active Customer',
          value: _isActive,
          onChanged: _isEditing ? (value) {
            setState(() {
              _isActive = value;
            });
          } : null,
          icon: Icons.check_circle,
          enabled: _isEditing,
        ),
      ],
    );
  }



  Widget _buildSection(ThemeData theme, String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary500,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLines: maxLines,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.textTertiary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.neutral200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary500, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error500),
            ),
            filled: true,
            fillColor: enabled ? AppColors.neutral50 : AppColors.neutral100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
    required IconData icon,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(12),
            color: enabled ? AppColors.neutral50 : AppColors.neutral100,
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            items: items,
            onChanged: enabled ? onChanged : null,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.textTertiary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            dropdownColor: Colors.white,
            icon: const Icon(Icons.arrow_drop_down),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
            isExpanded: true,
            menuMaxHeight: 300,
            selectedItemBuilder: (BuildContext context) {
              return items.map<Widget>((DropdownMenuItem<String> item) {
                return Text(
                  item.value ?? '',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                );
              }).toList();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchField({
    required String label,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required IconData icon,
    bool enabled = true,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textTertiary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeThumbColor: AppColors.primary500,
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!_isEditing) ...[
            Expanded(
              child: AppButton(
                text: 'Edit',
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                style: AppButtonStyle.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppButton(
                text: 'Back',
                onPressed: () => context.go('/customers'),
                style: AppButtonStyle.secondary,
              ),
            ),
          ] else ...[
            Expanded(
              child: AppButton(
                text: 'Cancel',
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _populateFormFields(_customer!);
                  });
                },
                style: AppButtonStyle.secondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppButton(
                text: _isSaving ? 'Saving...' : 'Save Changes',
                onPressed: _isSaving ? null : _submitForm,
                style: AppButtonStyle.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final customerData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'companyName': _companyController.text.trim(),
        'gstNumber': _gstController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'customerType': _selectedCustomerType,
        'creditLimit': _creditLimitController.text.isEmpty 
            ? 0 
            : double.parse(_creditLimitController.text),
        'isActive': _isActive,
      };

      final response = await apiService.updateCustomer(widget.customerId, customerData);

      if (response['success']) {
        if (mounted) {
          setState(() {
            _isEditing = false;
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Customer ${_nameController.text} updated successfully!'),
              backgroundColor: AppColors.success500,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Reload customer details to get updated data
          await _loadCustomerDetails();
        }
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to update customer');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred while updating customer');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error500,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
