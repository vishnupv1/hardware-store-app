import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/dropdown_field.dart';

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

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  final _minStockLevelController = TextEditingController();
  final _unitController = TextEditingController();
  final _modelController = TextEditingController();
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();

  String? _selectedCategory;
  String? _selectedBrand;
  String? _selectedSupplier;
  bool _isLoading = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _wholesalePriceController.dispose();
    _stockQuantityController.dispose();
    _minStockLevelController.dispose();
    _unitController.dispose();
    _modelController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
        return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button and title
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: AppColors.successGradient,
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.go('/inventory'),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Add Product',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Create new product',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildBasicInfoSection(theme),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildPricingSection(theme),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildInventorySection(theme),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildDetailsSection(theme),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildStatusSection(theme),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildActionButtons(theme),
              ),
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
      Icons.inventory_2,
      [
        _buildTextField(
          controller: _nameController,
          label: 'Product Name',
          hint: 'Enter product name',
          icon: Icons.inventory_2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Product name is required';
            }
            if (value.trim().length < 2) {
              return 'Product name must be at least 2 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _descriptionController,
          label: 'Description',
          hint: 'Enter product description',
          icon: Icons.description,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _skuController,
                label: 'SKU',
                hint: 'Enter SKU',
                icon: Icons.qr_code,
                inputFormatters: [
                  UpperCaseTextInputFormatter(),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller: _barcodeController,
                label: 'Barcode',
                hint: 'Enter barcode',
                icon: Icons.qr_code_scanner,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPricingSection(ThemeData theme) {
    return _buildSection(
      theme,
      'Pricing Information',
      Icons.attach_money,
      [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _costPriceController,
                label: 'Cost Price (₹)',
                hint: '0.00',
                icon: Icons.shopping_cart,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Cost price is required';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price < 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller: _sellingPriceController,
                label: 'Selling Price (₹)',
                hint: '0.00',
                icon: Icons.sell,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Selling price is required';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price < 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _wholesalePriceController,
                label: 'Wholesale Price (₹)',
                hint: '0.00',
                icon: Icons.store,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Wholesale price is required';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price < 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller: _modelController,
                label: 'Model',
                hint: 'Product model',
                icon: Icons.model_training,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInventorySection(ThemeData theme) {
    return _buildSection(
      theme,
      'Inventory Information',
      Icons.inventory,
      [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _stockQuantityController,
                label: 'Stock Quantity',
                hint: '0',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Stock quantity is required';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity < 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller: _minStockLevelController,
                label: 'Min Stock Level',
                hint: '0',
                icon: Icons.warning,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsSection(ThemeData theme) {
    return _buildSection(
      theme,
      'Product Details',
      Icons.category,
      [
        DropdownField(
          label: 'Category',
          value: _selectedCategory,
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
          type: 'category',
        ),
        const SizedBox(height: 16),
        DropdownField(
          label: 'Brand',
          value: _selectedBrand,
          onChanged: (value) {
            setState(() {
              _selectedBrand = value;
            });
          },
          type: 'brand',
        ),
        const SizedBox(height: 16),
        DropdownField(
          label: 'Supplier',
          value: _selectedSupplier,
          onChanged: (value) {
            setState(() {
              _selectedSupplier = value;
            });
          },
          type: 'supplier',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _weightController,
                label: 'Weight (kg)',
                hint: '0.0',
                icon: Icons.fitness_center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller: _unitController,
                label: 'Unit',
                hint: 'pcs, kg, m, etc.',
                icon: Icons.category,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Unit is required';
                  }
                  if (value.trim().length > 20) {
                    return 'Unit cannot exceed 20 characters';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _lengthController,
                label: 'Length (cm)',
                hint: '0.0',
                icon: Icons.straighten,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller: _widthController,
                label: 'Width (cm)',
                hint: '0.0',
                icon: Icons.straighten,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller: _heightController,
                label: 'Height (cm)',
                hint: '0.0',
                icon: Icons.straighten,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSection(ThemeData theme) {
    return _buildSection(
      theme,
      'Status',
      Icons.check_circle,
      [
        _buildSwitchField(
          label: 'Active Product',
          value: _isActive,
          onChanged: (value) {
            setState(() {
              _isActive = value;
            });
          },
          icon: Icons.check_circle,
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary500, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error500),
            ),
            filled: true,
            fillColor: AppColors.neutral50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }



  Widget _buildSwitchField({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
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
          onChanged: onChanged,
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
          Expanded(
            child: AppButton(
              text: 'Cancel',
              onPressed: () => context.go('/inventory'),
              style: AppButtonStyle.secondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AppButton(
              text: _isLoading ? 'Adding...' : 'Add Product',
              onPressed: _isLoading ? null : _submitForm,
              style: AppButtonStyle.primary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'sku': _skuController.text.trim(),
        'barcode': _barcodeController.text.trim(),
        'costPrice': double.parse(_costPriceController.text),
        'sellingPrice': double.parse(_sellingPriceController.text),
        'wholesalePrice': double.parse(_wholesalePriceController.text),
        'stockQuantity': int.parse(_stockQuantityController.text),
        'minStockLevel': _minStockLevelController.text.isEmpty ? 0 : int.parse(_minStockLevelController.text),
        'unit': _unitController.text.trim(),
        'category': _selectedCategory,
        'brand': _selectedBrand,
        'model': _modelController.text.trim(),
        'weight': _weightController.text.isNotEmpty ? double.parse(_weightController.text) : null,
        'dimensions': {
          'length': _lengthController.text.isNotEmpty ? double.parse(_lengthController.text) : null,
          'width': _widthController.text.isNotEmpty ? double.parse(_widthController.text) : null,
          'height': _heightController.text.isNotEmpty ? double.parse(_heightController.text) : null,
        },
        'isActive': _isActive,
      };

      final response = await apiService.createProduct(productData);

      if (response['success']) {
        if (mounted) {
          context.go('/inventory');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product ${_nameController.text} added successfully!'),
              backgroundColor: AppColors.success500,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to add product');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred while adding product');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
