import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
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

class ProductDetailsPage extends StatefulWidget {
  final String productId;

  const ProductDetailsPage({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minStockLevelController = TextEditingController();
  final _categoryController = TextEditingController();
  final _brandController = TextEditingController();
  final _supplierController = TextEditingController();
  final _weightController = TextEditingController();
  final _dimensionsController = TextEditingController();

  String _selectedCategory = '';
  String _selectedBrand = '';
  String _selectedSupplier = '';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _isActive = true;
  String? _errorMessage;
  
  List<String> _categories = [];
  List<String> _brands = [];
  final List<String> _suppliers = ['Supplier 1', 'Supplier 2', 'Supplier 3', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _loadCategoriesAndBrands();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _quantityController.dispose();
    _minStockLevelController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _supplierController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    try {
      final response = await apiService.getProduct(widget.productId);
      
      if (response['success']) {
        final product = response['data'];
        _populateFields(product);
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load product';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading product: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategoriesAndBrands() async {
    try {
      // Load categories
      final categoriesResponse = await apiService.getProductCategories();
      if (categoriesResponse['success']) {
        setState(() {
          _categories = List<String>.from(categoriesResponse['data']['categories'] ?? []);
        });
      }

      // Load brands
      final brandsResponse = await apiService.getProductBrands();
      if (brandsResponse['success']) {
        setState(() {
          _brands = List<String>.from(brandsResponse['data']['brands'] ?? []);
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _populateFields(Map<String, dynamic> product) {
    _nameController.text = product['name'] ?? '';
    _descriptionController.text = product['description'] ?? '';
    _skuController.text = product['sku'] ?? '';
    _barcodeController.text = product['barcode'] ?? '';
    _priceController.text = (product['price'] ?? 0).toString();
    _costPriceController.text = (product['costPrice'] ?? 0).toString();
    _quantityController.text = (product['quantity'] ?? 0).toString();
    _minStockLevelController.text = (product['minStockLevel'] ?? 0).toString();
    _categoryController.text = product['category'] ?? '';
    _brandController.text = product['brand'] ?? '';
    _supplierController.text = product['supplier'] ?? '';
    _weightController.text = (product['weight'] ?? '').toString();
    _dimensionsController.text = product['dimensions'] ?? '';
    _isActive = product['isActive'] ?? true;
    
    // Set dropdown values
    _selectedCategory = product['category'] ?? '';
    _selectedBrand = product['brand'] ?? '';
    _selectedSupplier = product['supplier'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Product Details'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Product Details'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              AppButton(
                text: 'Retry',
                onPressed: _loadProduct,
                style: AppButtonStyle.primary,
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Product Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/inventory'),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: _handleDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 32),
              _buildBasicInfoSection(theme),
              const SizedBox(height: 24),
              _buildPricingSection(theme),
              const SizedBox(height: 24),
              _buildInventorySection(theme),
              const SizedBox(height: 24),
              _buildDetailsSection(theme),
              const SizedBox(height: 24),
              _buildStatusSection(theme),
              if (_isEditing) ...[
                const SizedBox(height: 32),
                _buildActionButtons(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
                            color: AppColors.primary500.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isNotEmpty ? _nameController.text : 'Product Details',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SKU: ${_skuController.text.isNotEmpty ? _skuController.text : 'N/A'}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                                                color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          enabled: _isEditing,
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
          enabled: _isEditing,
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
                enabled: _isEditing,
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
                enabled: _isEditing,
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
                controller: _priceController,
                label: 'Selling Price (₹)',
                hint: '0.00',
                icon: Icons.sell,
                enabled: _isEditing,
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
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller: _costPriceController,
                label: 'Cost Price (₹)',
                hint: '0.00',
                icon: Icons.shopping_cart,
                enabled: _isEditing,
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
                controller: _quantityController,
                label: 'Quantity',
                hint: '0',
                icon: Icons.numbers,
                enabled: _isEditing,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Quantity is required';
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
                enabled: _isEditing,
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
        _buildDropdownField(
          label: 'Category',
          value: _selectedCategory.isEmpty ? null : _selectedCategory,
          items: _categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: _isEditing ? (value) {
            setState(() {
              _selectedCategory = value ?? '';
            });
          } : null,
          icon: Icons.category,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Brand',
          value: _selectedBrand.isEmpty ? null : _selectedBrand,
          items: _brands.map((brand) {
            return DropdownMenuItem(
              value: brand,
              child: Text(brand),
            );
          }).toList(),
          onChanged: _isEditing ? (value) {
            setState(() {
              _selectedBrand = value ?? '';
            });
          } : null,
          icon: Icons.branding_watermark,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Supplier',
          value: _selectedSupplier.isEmpty ? null : _selectedSupplier,
          items: _suppliers.map((supplier) {
            return DropdownMenuItem(
              value: supplier,
              child: Text(supplier),
            );
          }).toList(),
          onChanged: _isEditing ? (value) {
            setState(() {
              _selectedSupplier = value ?? '';
            });
          } : null,
          icon: Icons.local_shipping,
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
                enabled: _isEditing,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller: _dimensionsController,
                label: 'Dimensions',
                hint: 'L x W x H cm',
                icon: Icons.straighten,
                enabled: _isEditing,
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
          onChanged: _isEditing ? (value) {
            setState(() {
              _isActive = value;
            });
          } : null,
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
    bool enabled = true,
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
          enabled: enabled,
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
            color: onChanged != null ? AppColors.neutral50 : AppColors.neutral100,
          ),
          child: FormField<String>(
            initialValue: value,
            builder: (FormFieldState<String> field) {
              return DropdownButtonHideUnderline(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(icon, color: AppColors.textTertiary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<String>(
                          value: value,
                          items: items,
                          onChanged: onChanged != null ? (String? newValue) {
                            field.didChange(newValue);
                            onChanged(newValue);
                          } : null,
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
                  ),
                ),
              );
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
              onPressed: () {
                setState(() {
                  _isEditing = false;
                });
                _loadProduct(); // Reload original data
              },
              style: AppButtonStyle.secondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AppButton(
              text: _isSaving ? 'Saving...' : 'Save Changes',
              onPressed: _isSaving ? null : _handleSave,
              style: AppButtonStyle.primary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'sku': _skuController.text.trim(),
        'barcode': _barcodeController.text.trim(),
        'price': double.parse(_priceController.text),
        'costPrice': _costPriceController.text.isEmpty ? 0 : double.parse(_costPriceController.text),
        'quantity': int.parse(_quantityController.text),
        'minStockLevel': _minStockLevelController.text.isEmpty ? 0 : int.parse(_minStockLevelController.text),
        'category': _selectedCategory.isNotEmpty ? _selectedCategory : _categoryController.text.trim(),
        'brand': _selectedBrand.isNotEmpty ? _selectedBrand : _brandController.text.trim(),
        'supplier': _selectedSupplier.isNotEmpty ? _selectedSupplier : _supplierController.text.trim(),
        'weight': _weightController.text.isNotEmpty ? double.parse(_weightController.text) : null,
        'dimensions': _dimensionsController.text.trim(),
        'isActive': _isActive,
      };

      final response = await apiService.updateProduct(widget.productId, productData);

      if (!mounted) return;

      if (response['success']) {
        if (mounted) {
          setState(() {
            _isEditing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product updated successfully!'),
              backgroundColor: AppColors.success500,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to update product');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('An error occurred while updating product');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Product'),
        content: Text('Are you sure you want to delete this product? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await apiService.deleteProduct(widget.productId);
        
        if (!mounted) return;
        
        if (response['success']) {
          if (mounted) {
            if (context.mounted) {
              context.go('/inventory');
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Product deleted successfully!'),
                backgroundColor: AppColors.success500,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          _showErrorSnackBar(response['message'] ?? 'Failed to delete product');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('An error occurred while deleting product');
        }
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
