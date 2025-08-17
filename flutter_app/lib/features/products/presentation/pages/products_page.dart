import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/breadcrumb.dart';
import '../../../../core/services/breadcrumb_service.dart';
import '../../../../core/services/api_service.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;
  
  // Filters
  String _selectedCategory = '';
  String _selectedBrand = '';
  String _selectedStockStatus = '';
  bool _showOnlyActive = true;
  
  List<String> _categories = [];
  List<String> _brands = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadFilterData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _products.clear();
        _isLoading = true;
      });
    }

    try {
      final response = await apiService.getProducts(
        page: _currentPage,
        limit: 20,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
        brand: _selectedBrand.isNotEmpty ? _selectedBrand : null,
        isActive: _showOnlyActive ? true : null,
        stockStatus: _selectedStockStatus.isNotEmpty ? _selectedStockStatus : null,
      );

      if (response['success']) {
        final data = response['data'];
        final newProducts = List<Map<String, dynamic>>.from(data['products'] ?? []);
        
        setState(() {
          if (refresh) {
            _products = newProducts;
          } else {
            _products.addAll(newProducts);
          }
          _filteredProducts = _products;
          _totalPages = data['totalPages'] ?? 1;
          _hasMoreData = _currentPage < _totalPages;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load products';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading products: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFilterData() async {
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
    } catch (e) {
      // Handle error silently
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _products.where((product) {
        // Category filter
        if (_selectedCategory.isNotEmpty && product['category'] != _selectedCategory) {
          return false;
        }
        
        // Brand filter
        if (_selectedBrand.isNotEmpty && product['brand'] != _selectedBrand) {
          return false;
        }
        
        // Stock status filter
        if (_selectedStockStatus.isNotEmpty) {
          final quantity = product['quantity'] ?? 0;
          switch (_selectedStockStatus) {
            case 'in_stock':
              if (quantity <= 0) return false;
              break;
            case 'low_stock':
              final minStock = product['minStockLevel'] ?? 0;
              if (quantity > minStock || quantity <= 0) return false;
              break;
            case 'out_of_stock':
              if (quantity > 0) return false;
              break;
          }
        }
        
        return true;
      }).toList();
    });
  }

  void _loadMoreProducts() {
    if (_hasMoreData && !_isLoading) {
      setState(() {
        _currentPage++;
      });
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral900 : AppColors.background,
      appBar: AppBar(
        title: Text('Products'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Breadcrumb navigation
            Breadcrumb(
              items: BreadcrumbService.getBreadcrumbsForRoute('/products'),
            ),
            // Search and actions
            _buildSearchAndActions(theme),
            // Main content
            Expanded(
              child: _isLoading && _products.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : _errorMessage != null && _products.isEmpty
                      ? _buildErrorWidget(theme)
                      : _buildProductsList(theme),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/inventory/add'),
        backgroundColor: AppColors.primary500,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search bar
          AppTextField(
            label: 'Search products',
            hint: 'Search by name, SKU, or description',
            controller: _searchController,
            prefixIcon: Icon(Icons.search),
            onChanged: (value) {
              _loadProducts(refresh: true);
            },
            style: AppTextFieldStyle.outlined,
            size: AppTextFieldSize.large,
          ),
          const SizedBox(height: 16),
          // Active filters display
          if (_selectedCategory.isNotEmpty || _selectedBrand.isNotEmpty || _selectedStockStatus.isNotEmpty)
            _buildActiveFilters(theme),
        ],
      ),
    );
  }

  Widget _buildActiveFilters(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_selectedCategory.isNotEmpty)
          Chip(
            label: Text('Category: $_selectedCategory'),
            onDeleted: () {
              setState(() {
                _selectedCategory = '';
              });
              _applyFilters();
            },
          ),
        if (_selectedBrand.isNotEmpty)
          Chip(
            label: Text('Brand: $_selectedBrand'),
            onDeleted: () {
              setState(() {
                _selectedBrand = '';
              });
              _applyFilters();
            },
          ),
        if (_selectedStockStatus.isNotEmpty)
          Chip(
            label: Text('Stock: ${_getStockStatusLabel(_selectedStockStatus)}'),
            onDeleted: () {
              setState(() {
                _selectedStockStatus = '';
              });
              _applyFilters();
            },
          ),
      ],
    );
  }

  String _getStockStatusLabel(String status) {
    switch (status) {
      case 'in_stock':
        return 'In Stock';
      case 'low_stock':
        return 'Low Stock';
      case 'out_of_stock':
        return 'Out of Stock';
      default:
        return status;
    }
  }

  Widget _buildErrorWidget(ThemeData theme) {
    return Center(
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
            onPressed: () => _loadProducts(refresh: true),
            style: AppButtonStyle.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(ThemeData theme) {
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 16),
            Text(
              'No products found',
              style: theme.textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadProducts(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _filteredProducts.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredProducts.length) {
            return _buildLoadMoreButton();
          }
          
          final product = _filteredProducts[index];
          return _buildProductCard(theme, product);
        },
      ),
    );
  }

  Widget _buildProductCard(ThemeData theme, Map<String, dynamic> product) {
    final quantity = product['quantity'] ?? 0;
    final minStockLevel = product['minStockLevel'] ?? 0;
    final isLowStock = quantity > 0 && quantity <= minStockLevel;
    final isOutOfStock = quantity <= 0;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/products/${product['_id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] ?? 'Unnamed Product',
                          style: theme.textTheme.titleMedium?.copyWith(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${(product['price'] ?? 0).toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary500,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOutOfStock 
                              ? Colors.red 
                              : isLowStock 
                                  ? Colors.orange 
                                  : Colors.green,
                          borderRadius: BorderRadius.circular(12),
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
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Quantity: $quantity',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (product['category'] != null && product['category'].toString().isNotEmpty)
                    Expanded(
                      child: Text(
                        'Category: ${product['category']}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
              if (product['brand'] != null && product['brand'].toString().isNotEmpty) ...[
                SizedBox(height: 4),
                Text(
                  'Brand: ${product['brand']}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : AppButton(
                text: 'Load More',
                onPressed: _loadMoreProducts,
                style: AppButtonStyle.secondary,
              ),
      ),
    );
  }

  void _showFilterDialog() {
    // Create local variables to track changes
    String tempCategory = _selectedCategory;
    String tempBrand = _selectedBrand;
    String tempStockStatus = _selectedStockStatus;
    bool tempShowOnlyActive = _showOnlyActive;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Products'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category filter
              if (_categories.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: tempCategory.isNotEmpty ? tempCategory : null,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text('All Categories'),
                    ),
                    ..._categories.map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      tempCategory = value ?? '';
                    });
                  },
                ),
                SizedBox(height: 16),
              ],
              // Brand filter
              if (_brands.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: tempBrand.isNotEmpty ? tempBrand : null,
                  decoration: InputDecoration(
                    labelText: 'Brand',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text('All Brands'),
                    ),
                    ..._brands.map((brand) => DropdownMenuItem(
                      value: brand,
                      child: Text(brand),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      tempBrand = value ?? '';
                    });
                  },
                ),
                SizedBox(height: 16),
              ],
              // Stock status filter
              DropdownButtonFormField<String>(
                initialValue: tempStockStatus.isNotEmpty ? tempStockStatus : null,
                decoration: InputDecoration(
                  labelText: 'Stock Status',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text('All'),
                  ),
                  DropdownMenuItem(
                    value: 'in_stock',
                    child: Text('In Stock'),
                  ),
                  DropdownMenuItem(
                    value: 'low_stock',
                    child: Text('Low Stock'),
                  ),
                  DropdownMenuItem(
                    value: 'out_of_stock',
                    child: Text('Out of Stock'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    tempStockStatus = value ?? '';
                  });
                },
              ),
              SizedBox(height: 16),
              // Active products filter
              SwitchListTile(
                title: Text('Show only active products'),
                value: tempShowOnlyActive,
                onChanged: (value) {
                  setState(() {
                    tempShowOnlyActive = value;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                tempCategory = '';
                tempBrand = '';
                tempStockStatus = '';
                tempShowOnlyActive = true;
              });
            },
            child: Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Update the main state variables
              setState(() {
                _selectedCategory = tempCategory;
                _selectedBrand = tempBrand;
                _selectedStockStatus = tempStockStatus;
                _showOnlyActive = tempShowOnlyActive;
              });
              Navigator.of(context).pop();
              _applyFilters();
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }
}
