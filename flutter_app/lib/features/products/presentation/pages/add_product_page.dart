import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/breadcrumb.dart';
import '../../../../core/services/breadcrumb_service.dart';
import '../../../../core/services/api_service.dart';

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
  bool _isActive = true;
  bool _isLoading = false;
  List<String> _categories = [];
  List<String> _brands = [];
  List<String> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
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

  Future<void> _loadDropdownData() async {
    try {
      // Load categories
      final categoriesResponse = await apiService.getProductCategories();
      if (categoriesResponse['success']) {
        setState(() {
          _categories = List<String>.from(categoriesResponse['data'] ?? []);
        });
      }

      // Load brands
      final brandsResponse = await apiService.getProductBrands();
      if (brandsResponse['success']) {
        setState(() {
          _brands = List<String>.from(brandsResponse['data'] ?? []);
        });
      }

      _suppliers = ['Supplier 1', 'Supplier 2', 'Supplier 3']; // Placeholder
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<void> _handleSubmit() async {
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
        'price': double.parse(_priceController.text),
        'costPrice': double.parse(_costPriceController.text),
        'quantity': int.parse(_quantityController.text),
        'minStockLevel': int.parse(_minStockLevelController.text),
        'category': _selectedCategory.isNotEmpty ? _selectedCategory : _categoryController.text.trim(),
        'brand': _selectedBrand.isNotEmpty ? _selectedBrand : _brandController.text.trim(),
        'supplier': _selectedSupplier.isNotEmpty ? _selectedSupplier : _supplierController.text.trim(),
        'weight': _weightController.text.isNotEmpty ? double.parse(_weightController.text) : null,
        'dimensions': _dimensionsController.text.trim(),
        'isActive': _isActive,
      };

      final response = await apiService.createProduct(productData);

      if (response['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/products');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to add product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral900 : AppColors.background,
      appBar: AppBar(
        title: Text('Add Product'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Breadcrumb navigation
            Breadcrumb(
              items: BreadcrumbService.getBreadcrumbsForRoute('/inventory/add'),
            ),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      const SizedBox(height: 32),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add New Product',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter product details to add it to your inventory',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
                         AppTextField(
               label: 'Product Name *',
               hint: 'Enter product name',
               controller: _nameController,
               validator: (value) => Validators.validateRequired(value, 'Product name'),
               style: AppTextFieldStyle.outlined,
               size: AppTextFieldSize.large,
             ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Description',
              hint: 'Enter product description',
              controller: _descriptionController,
              maxLines: 3,
              style: AppTextFieldStyle.outlined,
              size: AppTextFieldSize.large,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'SKU',
                    hint: 'Enter SKU',
                    controller: _skuController,
                    style: AppTextFieldStyle.outlined,
                    size: AppTextFieldSize.large,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: 'Barcode',
                    hint: 'Enter barcode',
                    controller: _barcodeController,
                    style: AppTextFieldStyle.outlined,
                    size: AppTextFieldSize.large,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pricing',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                                     child: AppTextField(
                     label: 'Selling Price (₹) *',
                     hint: '0.00',
                     controller: _priceController,
                     keyboardType: TextInputType.number,
                     validator: (value) => Validators.validatePositiveNumber(value, 'Selling price'),
                     style: AppTextFieldStyle.outlined,
                     size: AppTextFieldSize.large,
                   ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: 'Cost Price (₹)',
                    hint: '0.00',
                    controller: _costPriceController,
                    keyboardType: TextInputType.number,
                    style: AppTextFieldStyle.outlined,
                    size: AppTextFieldSize.large,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                                 Expanded(
                   child: AppTextField(
                     label: 'Quantity *',
                     hint: '0',
                     controller: _quantityController,
                     keyboardType: TextInputType.number,
                     validator: (value) => Validators.validateRequired(value, 'Quantity'),
                     style: AppTextFieldStyle.outlined,
                     size: AppTextFieldSize.large,
                   ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: 'Min Stock Level',
                    hint: '0',
                    controller: _minStockLevelController,
                    keyboardType: TextInputType.number,
                    style: AppTextFieldStyle.outlined,
                    size: AppTextFieldSize.large,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Category dropdown or text field
            if (_categories.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory.isNotEmpty ? _selectedCategory : null,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text('Select category'),
                  ),
                  ..._categories.map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 16),
            ] else ...[
              AppTextField(
                label: 'Category',
                hint: 'Enter category',
                controller: _categoryController,
                style: AppTextFieldStyle.outlined,
                size: AppTextFieldSize.large,
              ),
              const SizedBox(height: 16),
            ],
            // Brand dropdown or text field
            if (_brands.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedBrand.isNotEmpty ? _selectedBrand : null,
                decoration: InputDecoration(
                  labelText: 'Brand',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text('Select brand'),
                  ),
                  ..._brands.map((brand) => DropdownMenuItem(
                    value: brand,
                    child: Text(brand),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedBrand = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 16),
            ] else ...[
              AppTextField(
                label: 'Brand',
                hint: 'Enter brand',
                controller: _brandController,
                style: AppTextFieldStyle.outlined,
                size: AppTextFieldSize.large,
              ),
              const SizedBox(height: 16),
            ],
            // Supplier dropdown or text field
            if (_suppliers.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedSupplier.isNotEmpty ? _selectedSupplier : null,
                decoration: InputDecoration(
                  labelText: 'Supplier',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text('Select supplier'),
                  ),
                  ..._suppliers.map((supplier) => DropdownMenuItem(
                    value: supplier,
                    child: Text(supplier),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSupplier = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 16),
            ] else ...[
              AppTextField(
                label: 'Supplier',
                hint: 'Enter supplier',
                controller: _supplierController,
                style: AppTextFieldStyle.outlined,
                size: AppTextFieldSize.large,
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Weight (kg)',
                    hint: '0.0',
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    style: AppTextFieldStyle.outlined,
                    size: AppTextFieldSize.large,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: 'Dimensions',
                    hint: 'L x W x H cm',
                    controller: _dimensionsController,
                    style: AppTextFieldStyle.outlined,
                    size: AppTextFieldSize.large,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: Text('Active'),
              subtitle: Text('Product will be available for sale'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
              activeThumbColor: AppColors.primary500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: 'Cancel',
            onPressed: () => context.go('/products'),
            style: AppButtonStyle.secondary,
            size: AppButtonSize.large,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppButton(
            text: 'Add Product',
            onPressed: _isLoading ? null : _handleSubmit,
            isLoading: _isLoading,
            style: AppButtonStyle.primary,
            size: AppButtonSize.large,
            icon: Icons.add,
          ),
        ),
      ],
    );
  }
}
