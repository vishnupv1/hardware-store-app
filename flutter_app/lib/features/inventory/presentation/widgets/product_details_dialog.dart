import 'package:flutter/material.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../core/services/api_service.dart';

class ProductDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onProductUpdated;
  final VoidCallback onProductDeleted;

  const ProductDetailsDialog({
    super.key,
    required this.product,
    required this.onProductUpdated,
    required this.onProductDeleted,
  });

  @override
  State<ProductDetailsDialog> createState() => _ProductDetailsDialogState();
}

class _ProductDetailsDialogState extends State<ProductDetailsDialog> {
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _populateFields();
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

  void _populateFields() {
    final product = widget.product;
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
  }

  Future<void> _handleSave() async {
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
        'category': _categoryController.text.trim(),
        'brand': _brandController.text.trim(),
        'supplier': _supplierController.text.trim(),
        'weight': _weightController.text.isNotEmpty ? double.parse(_weightController.text) : null,
        'dimensions': _dimensionsController.text.trim(),
      };

      final response = await apiService.updateProduct(widget.product['_id'], productData);

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
        widget.onProductUpdated();
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
          _isLoading = false;
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
        final response = await apiService.deleteProduct(widget.product['_id']);
        
        if (response['success'] && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onProductDeleted();
          if (context.mounted) {
            Navigator.of(context).pop();
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
    final product = widget.product;
    final quantity = product['quantity'] ?? 0;
    final minStockLevel = product['minStockLevel'] ?? 0;
    final isLowStock = quantity > 0 && quantity <= minStockLevel;
    final isOutOfStock = quantity <= 0;

    return Dialog(
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? 'Product Details',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'SKU: ${product['sku'] ?? 'N/A'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
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
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Status indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isOutOfStock 
                    ? Colors.red 
                    : isLowStock 
                        ? Colors.orange 
                        : Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                isOutOfStock 
                    ? 'Out of Stock'
                    : isLowStock 
                        ? 'Low Stock'
                        : 'In Stock',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 24),
            // Form
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBasicInfoSection(theme),
                      SizedBox(height: 16),
                      _buildPricingSection(theme),
                      SizedBox(height: 16),
                      _buildInventorySection(theme),
                      SizedBox(height: 16),
                      _buildDetailsSection(theme),
                      if (_isEditing) ...[
                        SizedBox(height: 24),
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

  Widget _buildBasicInfoSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            AppTextField(
              label: 'Product Name *',
              hint: 'Enter product name',
              controller: _nameController,
              enabled: _isEditing,
              validator: (value) => Validators.validateRequired(value, 'Product name'),
              style: AppTextFieldStyle.outlined,
              size: AppTextFieldSize.medium,
            ),
            SizedBox(height: 12),
            AppTextField(
              label: 'Description',
              hint: 'Enter product description',
              controller: _descriptionController,
              enabled: _isEditing,
              maxLines: 2,
              style: AppTextFieldStyle.outlined,
              size: AppTextFieldSize.medium,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'SKU',
                    hint: 'Enter SKU',
                    controller: _skuController,
                    enabled: _isEditing,
                    style: AppTextFieldStyle.outlined,
                    size: AppTextFieldSize.medium,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Barcode',
                    hint: 'Enter barcode',
                    controller: _barcodeController,
                    enabled: _isEditing,
                    style: AppTextFieldStyle.outlined,
                    size: AppTextFieldSize.medium,
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pricing',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
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
                    size: AppTextFieldSize.medium,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Cost Price (₹)',
                    hint: '0.00',
                    controller: _costPriceController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.number,
                    style: AppTextFieldStyle.outlined,
                    size: AppTextFieldSize.medium,
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
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
                    size: AppTextFieldSize.medium,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Min Stock Level',
                    hint: '0',
                    controller: _minStockLevelController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.number,
                    style: AppTextFieldStyle.outlined,
                    size: AppTextFieldSize.medium,
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            AppTextField(
              label: 'Category',
              hint: 'Enter category',
              controller: _categoryController,
              enabled: _isEditing,
              style: AppTextFieldStyle.outlined,
              size: AppTextFieldSize.medium,
            ),
            SizedBox(height: 12),
            AppTextField(
              label: 'Brand',
              hint: 'Enter brand',
              controller: _brandController,
              enabled: _isEditing,
              style: AppTextFieldStyle.outlined,
              size: AppTextFieldSize.medium,
            ),
            SizedBox(height: 12),
            AppTextField(
              label: 'Supplier',
              hint: 'Enter supplier',
              controller: _supplierController,
              enabled: _isEditing,
              style: AppTextFieldStyle.outlined,
              size: AppTextFieldSize.medium,
            ),
            SizedBox(height: 12),
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
                    size: AppTextFieldSize.medium,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Dimensions',
                    hint: 'L x W x H cm',
                    controller: _dimensionsController,
                    enabled: _isEditing,
                    style: AppTextFieldStyle.outlined,
                    size: AppTextFieldSize.medium,
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
            size: AppButtonSize.medium,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: AppButton(
            text: 'Save Changes',
            onPressed: _isLoading ? null : _handleSave,
            isLoading: _isLoading,
            style: AppButtonStyle.primary,
            size: AppButtonSize.medium,
            icon: Icons.save,
          ),
        ),
      ],
    );
  }
}
