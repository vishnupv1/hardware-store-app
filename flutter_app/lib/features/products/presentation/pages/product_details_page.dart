import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/breadcrumb.dart';
import '../../../../core/services/breadcrumb_service.dart';
import '../../../../core/services/api_service.dart';

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

  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _product;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProduct();
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
        setState(() {
          _product = response['data']['product'];
          _populateFields();
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

  void _populateFields() {
    if (_product == null) return;
    
    _nameController.text = _product!['name'] ?? '';
    _descriptionController.text = _product!['description'] ?? '';
    _skuController.text = _product!['sku'] ?? '';
    _barcodeController.text = _product!['barcode'] ?? '';
    _priceController.text = (_product!['price'] ?? 0).toString();
    _costPriceController.text = (_product!['costPrice'] ?? 0).toString();
    _quantityController.text = (_product!['quantity'] ?? 0).toString();
    _minStockLevelController.text = (_product!['minStockLevel'] ?? 0).toString();
    _categoryController.text = _product!['category'] ?? '';
    _brandController.text = _product!['brand'] ?? '';
    _supplierController.text = _product!['supplier'] ?? '';
    _weightController.text = (_product!['weight'] ?? '').toString();
    _dimensionsController.text = _product!['dimensions'] ?? '';
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
        'costPrice': double.parse(_costPriceController.text),
        'quantity': int.parse(_quantityController.text),
        'minStockLevel': int.parse(_minStockLevelController.text),
        'category': _categoryController.text.trim(),
        'brand': _brandController.text.trim(),
        'supplier': _supplierController.text.trim(),
        'weight': _weightController.text.isNotEmpty ? double.parse(_weightController.text) : null,
        'dimensions': _dimensionsController.text.trim(),
      };

      final response = await apiService.updateProduct(widget.productId, productData);

      if (response['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditing = false;
        });
        _loadProduct(); // Reload to get updated data
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to update product'),
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
        
        if (response['success'] && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          if (context.mounted) {
            context.go('/products');
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to delete product'),
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.neutral900 : AppColors.background,
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
        backgroundColor: isDark ? AppColors.neutral900 : AppColors.background,
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
                text: 'Go Back',
                onPressed: () => context.go('/products'),
                style: AppButtonStyle.secondary,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral900 : AppColors.background,
      appBar: AppBar(
        title: Text('Product Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: _handleDelete,
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Breadcrumb navigation
            Breadcrumb(
              items: BreadcrumbService.getBreadcrumbsForRoute('/products/${widget.productId}'),
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
                      if (_isEditing) ...[
                        const SizedBox(height: 32),
                        _buildActionButtons(),
                      ],
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
        Row(
          children: [
            Expanded(
              child: Text(
                _product?['name'] ?? 'Product Details',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_product != null) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (_product!['isActive'] ?? true) ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  (_product!['isActive'] ?? true) ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'SKU: ${_product?['sku'] ?? 'N/A'}',
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
              enabled: _isEditing,
              validator: (value) => Validators.validateRequired(value, 'Product name'),
              style: AppTextFieldStyle.outlined,
              size: AppTextFieldSize.large,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Description',
              hint: 'Enter product description',
              controller: _descriptionController,
              enabled: _isEditing,
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
                    enabled: _isEditing,
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
                    enabled: _isEditing,
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
                    enabled: _isEditing,
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
                    enabled: _isEditing,
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
                    enabled: _isEditing,
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
                    enabled: _isEditing,
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
            AppTextField(
              label: 'Category',
              hint: 'Enter category',
              controller: _categoryController,
              enabled: _isEditing,
              style: AppTextFieldStyle.outlined,
              size: AppTextFieldSize.large,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Brand',
              hint: 'Enter brand',
              controller: _brandController,
              enabled: _isEditing,
              style: AppTextFieldStyle.outlined,
              size: AppTextFieldSize.large,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Supplier',
              hint: 'Enter supplier',
              controller: _supplierController,
              enabled: _isEditing,
              style: AppTextFieldStyle.outlined,
              size: AppTextFieldSize.large,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Weight (kg)',
                    hint: '0.0',
                    controller: _weightController,
                    enabled: _isEditing,
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
                    enabled: _isEditing,
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: 'Cancel',
            onPressed: () {
              setState(() {
                _isEditing = false;
              });
              _populateFields(); // Reset to original values
            },
            style: AppButtonStyle.secondary,
            size: AppButtonSize.large,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppButton(
            text: 'Save Changes',
            onPressed: _isSaving ? null : _handleSave,
            isLoading: _isSaving,
            style: AppButtonStyle.primary,
            size: AppButtonSize.large,
            icon: Icons.save,
          ),
        ),
      ],
    );
  }
}
