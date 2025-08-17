import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../core/services/api_service.dart';

class BrandsPage extends StatefulWidget {
  const BrandsPage({super.key});

  @override
  State<BrandsPage> createState() => _BrandsPageState();
}

class _BrandsPageState extends State<BrandsPage> {
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _brands = [];
  List<Map<String, dynamic>> _filteredBrands = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;
  
  // Filters
  bool _showOnlyActive = true;
  bool _hasActiveFilters = false;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _brands.clear();
        _isLoading = true;
      });
    }

    try {
      final response = await apiService.getBrands(
        page: _currentPage,
        limit: 20,
        isActive: _showOnlyActive ? true : null,
      );

      if (response['success']) {
        final data = response['data'];
        final newBrands = List<Map<String, dynamic>>.from(data['brands'] ?? []);
        
        setState(() {
          if (refresh) {
            _brands = newBrands;
          } else {
            _brands.addAll(newBrands);
          }
          _filteredBrands = _brands;
          _totalPages = data['pagination']['totalPages'] ?? 1;
          _hasMoreData = _currentPage < _totalPages;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load brands';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading brands: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredBrands = _brands.where((brand) {
        // Active filter
        if (_showOnlyActive && !(brand['isActive'] ?? true)) {
          return false;
        }
        
        return true;
      }).toList();
      
      // Update active filters state - consider both search and active filters
      _hasActiveFilters = !_showOnlyActive || _searchController.text.isNotEmpty;
    });
  }

  void _loadMoreBrands() {
    if (_hasMoreData && !_isLoading) {
      setState(() {
        _currentPage++;
      });
      _loadBrands();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: null,
      body: RefreshIndicator(
        onRefresh: () => _loadBrands(refresh: true),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(theme),
            _buildSearchAndFilters(theme),
            _buildBrandsList(theme),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBrandDialog(context),
        backgroundColor: AppColors.primary500,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Brand',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/'),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.branding_watermark,
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
                      '${_brands.length}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total Brands',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.filter_list, color: Colors.white),
                    onPressed: _showFilterDialog,
                  ),
                  if (_hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search brands...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterBrandsBySearch('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  _filterBrandsBySearch(value);
                },
              ),
            ),
            const SizedBox(height: 16),
            // Active filters display
            if (_hasActiveFilters)
              _buildActiveFilters(theme),
          ],
        ),
      ),
    );
  }



  Widget _buildActiveFilters(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (!_showOnlyActive)
          Chip(
            label: Text('Show all brands'),
            onDeleted: () {
              setState(() {
                _showOnlyActive = true;
              });
              _applyFilters();
            },
          ),
      ],
    );
  }

  void _filterBrandsBySearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBrands = _brands;
      } else {
        _filteredBrands = _brands.where((brand) {
          final name = brand['name']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase());
        }).toList();
      }
      
      // Update active filters state
      _hasActiveFilters = !_showOnlyActive || query.isNotEmpty;
    });
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
            onPressed: () => _loadBrands(refresh: true),
            style: AppButtonStyle.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildBrandsList(ThemeData theme) {
    if (_isLoading && _brands.isEmpty) {
      return SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _brands.isEmpty) {
      return SliverFillRemaining(
        child: _buildErrorWidget(theme),
      );
    }

    if (_filteredBrands.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.branding_watermark_outlined,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: 16),
              Text(
                'No brands found',
                style: theme.textTheme.headlineSmall,
              ),
              SizedBox(height: 8),
              Text(
                'Try adding a new brand or adjusting your search',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == _filteredBrands.length) {
              if (_hasMoreData) {
                return _buildLoadMoreButton();
              }
              return null;
            }
            
            final brand = _filteredBrands[index];
            return _buildBrandCard(theme, brand);
          },
          childCount: _filteredBrands.length + (_hasMoreData ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildBrandCard(ThemeData theme, Map<String, dynamic> brand) {
    final isActive = brand['isActive'] ?? true;
    final productCount = brand['productCount'] ?? 0;
    final description = brand['description'];
    final createdBy = brand['createdBy'];

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEditBrandDialog(context, brand),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.branding_watermark,
                  color: AppColors.primary500,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brand['name'] ?? 'Unnamed Brand',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$productCount products',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (createdBy != null) ...[
                          SizedBox(width: 8),
                          Text(
                            '•',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'by ${createdBy['firstName'] ?? ''} ${createdBy['lastName'] ?? ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Icon(
                    Icons.edit,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
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
                onPressed: _loadMoreBrands,
                style: AppButtonStyle.secondary,
              ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Brands'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Active brands filter
              SwitchListTile(
                title: Text('Show only active brands'),
                value: _showOnlyActive,
                onChanged: (value) {
                  setState(() {
                    _showOnlyActive = value;
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
                _showOnlyActive = true;
                _searchController.clear();
                _hasActiveFilters = false;
              });
              _filterBrandsBySearch('');
            },
            child: Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applyFilters();
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showAddBrandDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isActive = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add New Brand'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Brand Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('Active'),
                value: isActive,
                onChanged: (value) {
                  setState(() {
                    isActive = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Brand name is required')),
                  );
                  return;
                }

                try {
                  final response = await apiService.createBrand(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim().isEmpty 
                        ? null 
                        : descriptionController.text.trim(),
                    isActive: isActive,
                  );
                  
                  if (!mounted) return;
                  
                  if (response['success']) {
                    Navigator.of(dialogContext).pop();
                    _loadBrands(refresh: true);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Brand added successfully!'),
                          backgroundColor: AppColors.success500,
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(response['message'] ?? 'Failed to add brand'),
                          backgroundColor: AppColors.error500,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error adding brand: $e'),
                        backgroundColor: AppColors.error500,
                      ),
                    );
                  }
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBrandDialog(BuildContext context, Map<String, dynamic> brand) {
    final nameController = TextEditingController(text: brand['name'] ?? '');
    final descriptionController = TextEditingController(text: brand['description'] ?? '');
    bool isActive = brand['isActive'] ?? true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Brand'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Brand Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('Active'),
                value: isActive,
                onChanged: (value) {
                  setState(() {
                    isActive = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Brand name is required')),
                  );
                  return;
                }

                try {
                  final response = await apiService.updateBrand(brand['_id'], 
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim().isEmpty 
                        ? null 
                        : descriptionController.text.trim(),
                    isActive: isActive,
                  );
                  
                  if (!mounted) return;
                  
                  if (response['success']) {
                    Navigator.of(dialogContext).pop();
                    _loadBrands(refresh: true);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Brand updated successfully!'),
                          backgroundColor: AppColors.success500,
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(response['message'] ?? 'Failed to update brand'),
                          backgroundColor: AppColors.error500,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating brand: $e'),
                        backgroundColor: AppColors.error500,
                      ),
                    );
                  }
                }
              },
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }


}
