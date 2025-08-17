import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/sale.dart';
import '../../../../core/models/customer.dart';
import '../../../../core/models/product.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

class EditSalePage extends StatefulWidget {
  final String saleId;

  const EditSalePage({
    super.key,
    required this.saleId,
  });

  @override
  State<EditSalePage> createState() => _EditSalePageState();
}

class _EditSalePageState extends State<EditSalePage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _taxAmountController = TextEditingController();
  final _discountAmountController = TextEditingController();
  final _shippingCostController = TextEditingController();
  
  // Customer selection
  String? _selectedCustomerId;
  Customer? _selectedCustomer;
  List<Customer> _availableCustomers = [];
  
  // Sale items
  List<SaleItem> _saleItems = [];
  
  // Payment and status
  String _paymentMethod = 'cash';
  String _paymentStatus = 'pending';
  String _saleStatus = 'completed';
  
  // Shipping address
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _countryController = TextEditingController();
  
  // Date
  DateTime _saleDate = DateTime.now();
  
  // Loading states
  bool _isLoading = false;
  bool _isLoadingSale = true;
  
  // Available products for selection
  List<Product> _availableProducts = [];
  
  // Original sale data

  @override
  void initState() {
    super.initState();
    _loadSaleDetails();
    _loadCustomers();
    _loadProducts();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _taxAmountController.dispose();
    _discountAmountController.dispose();
    _shippingCostController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadSaleDetails() async {
    try {
      setState(() {
        _isLoadingSale = true;
      });

      final response = await apiService.getSale(widget.saleId);
      
      if (!mounted) return;
      
      if (response['success']) {
        final saleData = response['data']['sale'];
        final sale = Sale.fromJson(saleData);
        
        if (mounted) {
          setState(() {
            _selectedCustomerId = sale.customerId;
            _selectedCustomer = null; // Will be populated when customers load
            _saleItems = List.from(sale.items);
            _paymentMethod = sale.paymentMethod;
            _paymentStatus = sale.paymentStatus;
            _saleStatus = sale.saleStatus;
            _saleDate = sale.saleDate;
            
            // Populate form fields
            _notesController.text = sale.notes ?? '';
            _taxAmountController.text = sale.taxAmount.toString();
            _discountAmountController.text = sale.discountAmount.toString();
            _shippingCostController.text = sale.shippingCost.toString();
            
            // Populate shipping address
            if (sale.shippingAddress != null) {
              _streetController.text = sale.shippingAddress!.street ?? '';
              _cityController.text = sale.shippingAddress!.city ?? '';
              _stateController.text = sale.shippingAddress!.state ?? '';
              _pincodeController.text = sale.shippingAddress!.pincode ?? '';
              _countryController.text = sale.shippingAddress!.country ?? '';
            }
            
            _isLoadingSale = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingSale = false;
          });
          _showErrorSnackBar(response['message'] ?? 'Failed to load sale details');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSale = false;
        });
        _showErrorSnackBar('Error loading sale details: $e');
      }
    }
  }

  Future<void> _loadCustomers() async {
    setState(() {
    });

    try {
      final response = await apiService.getCustomersForDropdown();
      if (!mounted) return;
      
      if (response['success']) {
        final customers = (response['data'] as List)
            .map((json) => Customer.fromJson(json))
            .toList();
        
        if (mounted) {
          setState(() {
            _availableCustomers = customers;
          });
          
          // Set the selected customer from available customers
          if (_selectedCustomerId != null) {
            final selectedCustomer = customers.firstWhere(
              (c) => c.id == _selectedCustomerId,
              orElse: () => customers.first,
            );
            setState(() {
              _selectedCustomer = selectedCustomer;
            });
            // Auto-populate shipping address
            _populateShippingAddress(selectedCustomer);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
        });
        _showErrorSnackBar('Failed to load customers');
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
    });

    try {
      final response = await apiService.getProducts();
      if (!mounted) return;
      
      if (response['success']) {
        final products = (response['data']['products'] as List)
            .map((json) => Product.fromJson(json))
            .where((product) => product.isActive)
            .toList();
        
        if (mounted) {
          setState(() {
            _availableProducts = products;
          });
        }
      } else {
        if (mounted) {
          setState(() {
          });
          _showErrorSnackBar('Failed to load products');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
        });
        _showErrorSnackBar('Failed to load products');
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success500,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _populateShippingAddress(Customer customer) {
    setState(() {
      _streetController.text = customer.address ?? '';
      _cityController.text = customer.city ?? '';
      _stateController.text = customer.state ?? '';
      _pincodeController.text = customer.pincode ?? '';
      _countryController.text = 'India'; // Default country
    });
  }


  void _addSaleItem() {
    showDialog(
      context: context,
      builder: (context) => _AddSaleItemDialog(
        products: _availableProducts,
        onItemAdded: (item) {
          setState(() {
            _saleItems.add(item);
          });
        },
      ),
    );
  }

  void _removeSaleItem(int index) {
    setState(() {
      _saleItems.removeAt(index);
    });
  }

  void _editSaleItem(int index) {
    showDialog(
      context: context,
      builder: (context) => _AddSaleItemDialog(
        products: _availableProducts,
        existingItem: _saleItems[index],
        onItemAdded: (item) {
          setState(() {
            _saleItems[index] = item;
          });
        },
      ),
    );
  }

  double get _subtotal {
    return _saleItems.fold(0, (sum, item) => sum + (item.totalPrice - item.discount));
  }

  double get _taxAmount {
    return double.tryParse(_taxAmountController.text) ?? 0;
  }

  double get _discountAmount {
    return double.tryParse(_discountAmountController.text) ?? 0;
  }

  double get _shippingCost {
    return double.tryParse(_shippingCostController.text) ?? 0;
  }

  double get _totalAmount {
    return _subtotal + _taxAmount - _discountAmount + _shippingCost;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _saleDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCustomerId == null) {
      _showErrorSnackBar('Please select a customer');
      return;
    }

    if (_saleItems.isEmpty) {
      _showErrorSnackBar('Please add at least one item to the sale');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final saleData = {
        'customerId': _selectedCustomerId!,
        'items': _saleItems.map((item) => {
          'productId': item.productId,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'discount': item.discount,
        }).toList(),
        'paymentMethod': _paymentMethod,
        'paymentStatus': _paymentStatus,
        'saleStatus': _saleStatus,
        'taxAmount': _taxAmount,
        'discountAmount': _discountAmount,
        'shippingCost': _shippingCost,
        'notes': _notesController.text.trim(),
        'saleDate': _saleDate.toIso8601String(),
        'shippingAddress': {
          'street': _streetController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'pincode': _pincodeController.text.trim(),
          'country': _countryController.text.trim(),
        },
      };

      final response = await apiService.updateSale(widget.saleId, saleData);
      
      if (!mounted) return;
      
      if (response['success']) {
        _showSuccessSnackBar('Sale updated successfully');
        context.go('/sales/${widget.saleId}');
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to update sale');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error updating sale: $e');
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
    
    if (_isLoadingSale) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Edit Sale'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => context.go('/sales/${widget.saleId}'),
          ),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit Sale'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/sales/${widget.saleId}'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Information',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      FormField<String>(
                        initialValue: _selectedCustomerId,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Customer is required';
                          }
                          return null;
                        },
                                                 builder: (FormFieldState<String> field) {
                           return DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Customer *',
                              border: OutlineInputBorder(),
                              errorText: field.errorText,
                            ),
                            items: _availableCustomers.map((customer) {
                              return DropdownMenuItem<String>(
                                value: customer.id,
                                child: Text(
                                  customer.displayName,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              );
                            }).toList(),
                            onChanged: (customerId) {
                              field.didChange(customerId);
                              setState(() {
                                _selectedCustomerId = customerId;
                                if (customerId != null) {
                                  // Find the selected customer from available customers
                                  final selectedCustomer = _availableCustomers.firstWhere(
                                    (c) => c.id == customerId,
                                  );
                                  _selectedCustomer = selectedCustomer;
                                  // Auto-populate shipping address
                                  _populateShippingAddress(selectedCustomer);
                                } else {
                                  _selectedCustomer = null;
                                  // Clear shipping address
                                  _streetController.clear();
                                  _cityController.clear();
                                  _stateController.clear();
                                  _pincodeController.clear();
                                  _countryController.clear();
                                }
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Sale Items
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sale Items',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppButton(
                            text: 'Add Item',
                            onPressed: _addSaleItem,
                            style: AppButtonStyle.primary,
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      if (_saleItems.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 48,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No items added',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: _saleItems.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(item.productName),
                                subtitle: Text('SKU: ${item.sku}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('₹${item.totalPrice.toStringAsFixed(2)}'),
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () => _editSaleItem(index),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeSaleItem(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Payment Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Information',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                                                         child: FormField<String>(
                               initialValue: _paymentMethod,
                               builder: (FormFieldState<String> field) {
                                 return DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'Payment Method *',
                                    border: OutlineInputBorder(),
                                    errorText: field.errorText,
                                  ),
                                  items: [
                                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                                    DropdownMenuItem(value: 'card', child: Text('Card')),
                                    DropdownMenuItem(value: 'upi', child: Text('UPI')),
                                    DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                                    DropdownMenuItem(value: 'credit', child: Text('Credit')),
                                    DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                                  ],
                                  onChanged: (value) {
                                    field.didChange(value);
                                    setState(() {
                                      _paymentMethod = value!;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                                                         child: FormField<String>(
                               initialValue: _paymentStatus,
                               builder: (FormFieldState<String> field) {
                                 return DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'Payment Status',
                                    border: OutlineInputBorder(),
                                    errorText: field.errorText,
                                  ),
                                  items: [
                                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                                    DropdownMenuItem(value: 'partial', child: Text('Partial')),
                                    DropdownMenuItem(value: 'failed', child: Text('Failed')),
                                  ],
                                  onChanged: (value) {
                                    field.didChange(value);
                                    setState(() {
                                      _paymentStatus = value!;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16),
                      
                                             FormField<String>(
                         initialValue: _saleStatus,
                         builder: (FormFieldState<String> field) {
                           return DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Sale Status',
                              border: OutlineInputBorder(),
                              errorText: field.errorText,
                            ),
                            items: [
                              DropdownMenuItem(value: 'completed', child: Text('Completed')),
                              DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                              DropdownMenuItem(value: 'returned', child: Text('Returned')),
                              DropdownMenuItem(value: 'refunded', child: Text('Refunded')),
                            ],
                            onChanged: (value) {
                              field.didChange(value);
                              setState(() {
                                _saleStatus = value!;
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Financial Details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Financial Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _taxAmountController,
                              label: 'Tax Amount (₹)',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              controller: _discountAmountController,
                              label: 'Discount Amount (₹)',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16),
                      
                      AppTextField(
                        controller: _shippingCostController,
                        label: 'Shipping Cost (₹)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Summary
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Subtotal:'),
                                Text('₹${_subtotal.toStringAsFixed(2)}'),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tax:'),
                                Text('₹${_taxAmount.toStringAsFixed(2)}'),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Discount:'),
                                Text('-₹${_discountAmount.toStringAsFixed(2)}'),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Shipping:'),
                                Text('₹${_shippingCost.toStringAsFixed(2)}'),
                              ],
                            ),
                            Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total:',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${_totalAmount.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Shipping Address
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Shipping Address',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedCustomer != null) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Text(
                                'Auto-filled',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_selectedCustomer != null) ...[
                        SizedBox(height: 8),
                        Text(
                          'Address fields are auto-populated from customer data. You can edit them if needed.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      SizedBox(height: 16),
                      
                      AppTextField(
                        controller: _streetController,
                        label: 'Street Address',
                      ),
                      
                      SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _cityController,
                              label: 'City',
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              controller: _stateController,
                              label: 'State',
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _pincodeController,
                              label: 'Pincode',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              controller: _countryController,
                              label: 'Country',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Additional Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional Information',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Sale Date',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  '${_saleDate.day}/${_saleDate.month}/${_saleDate.year}',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16),
                      
                      AppTextField(
                        controller: _notesController,
                        label: 'Notes',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: _isLoading ? 'Updating Sale...' : 'Update Sale',
                  onPressed: _isLoading ? null : _submitForm,
                  style: AppButtonStyle.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddSaleItemDialog extends StatefulWidget {
  final List<Product> products;
  final SaleItem? existingItem;
  final Function(SaleItem) onItemAdded;

  const _AddSaleItemDialog({
    required this.products,
    this.existingItem,
    required this.onItemAdded,
  });

  @override
  State<_AddSaleItemDialog> createState() => _AddSaleItemDialogState();
}

class _AddSaleItemDialogState extends State<_AddSaleItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _discountController = TextEditingController();
  
  Product? _selectedProduct;
  double _totalPrice = 0;
  String? _selectedCategory;
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    
    // Initialize filtered products with all products
    _filteredProducts = List.from(widget.products);
    
    if (widget.existingItem != null) {
      _selectedProduct = widget.products.firstWhere(
        (p) => p.id == widget.existingItem!.productId,
        orElse: () => widget.products.first,
      );
      _quantityController.text = widget.existingItem!.quantity.toString();
      _unitPriceController.text = widget.existingItem!.unitPrice.toString();
      _discountController.text = widget.existingItem!.discount.toString();
      _calculateTotal();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;
    
    setState(() {
      _totalPrice = (quantity * unitPrice) - discount;
    });
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  void _onProductChanged(Product? product) {
    setState(() {
      _selectedProduct = product;
      if (product != null) {
        _unitPriceController.text = product.sellingPrice.toString();
        _calculateTotal();
      }
    });
  }

  void _onCategoryChanged(String? category) {
    setState(() {
      _selectedCategory = category;
      _selectedProduct = null; // Reset selected product when category changes
      
      if (category == null) {
        // Show all products
        _filteredProducts = List.from(widget.products);
      } else {
        // Filter products by category
        _filteredProducts = widget.products
            .where((product) => product.category == category)
            .toList();
      }
    });
  }

  List<String> get _availableCategories {
    final categories = widget.products.map((p) => p.category).toSet().toList();
    categories.sort();
    return categories;
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a product')),
      );
      return;
    }

    final quantity = int.parse(_quantityController.text);
    final unitPrice = double.parse(_unitPriceController.text);
    final discount = double.tryParse(_discountController.text) ?? 0;

    final saleItem = SaleItem(
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      sku: _selectedProduct!.sku,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: _totalPrice,
      discount: discount,
    );

    widget.onItemAdded(saleItem);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(widget.existingItem != null ? 'Edit Item' : 'Add Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category Filter Dropdown
                             FormField<String>(
                 initialValue: _selectedCategory,
                 builder: (FormFieldState<String> field) {
                   return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Filter by Category (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.filter_list),
                      errorText: field.errorText,
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                                        ..._availableCategories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }),
                    ],
                    onChanged: (value) {
                      field.didChange(value);
                      _onCategoryChanged(value);
                    },
                  );
                },
              ),
              
              SizedBox(height: 16),
              
              if (_filteredProducts.isEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedCategory != null 
                            ? 'No products found in category "$_selectedCategory"'
                            : 'No products available. Please add products first.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                )
              else
                                 FormField<Product>(
                   initialValue: _selectedProduct,
                   validator: (value) {
                     if (value == null) return 'Please select a product';
                     return null;
                   },
                   builder: (FormFieldState<Product> field) {
                     return DropdownButtonFormField<Product>(
                      decoration: InputDecoration(
                        labelText: 'Product *',
                        border: OutlineInputBorder(),
                        errorText: field.errorText,
                      ),
                      items: _filteredProducts.map((product) {
                        return DropdownMenuItem(
                          value: product,
                          child: Text(
                            product.name,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                      onChanged: (product) {
                        field.didChange(product);
                        _onProductChanged(product);
                      },
                    );
                  },
                ),
                
                // Product details below dropdown
                if (_selectedProduct != null) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 8),
                            Text(
                              'Product Details',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailItem('SKU', _selectedProduct!.sku),
                            ),
                            Expanded(
                              child: _buildDetailItem('Stock', '${_selectedProduct!.stockQuantity}'),
                            ),
                            Expanded(
                              child: _buildDetailItem('Price', '₹${_selectedProduct!.sellingPrice.toStringAsFixed(2)}'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              
              SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantity *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) => _calculateTotal(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Quantity is required';
                        }
                        final quantity = int.tryParse(value);
                        if (quantity == null || quantity <= 0) {
                          return 'Quantity must be greater than 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _unitPriceController,
                      decoration: InputDecoration(
                        labelText: 'Unit Price (₹) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      onChanged: (value) => _calculateTotal(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Unit price is required';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price < 0) {
                          return 'Price must be non-negative';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              TextFormField(
                controller: _discountController,
                decoration: InputDecoration(
                  labelText: 'Discount (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (value) => _calculateTotal(),
              ),
              
              SizedBox(height: 16),
              
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Price:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${_totalPrice.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: Text(widget.existingItem != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
