import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/category.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _searchController = TextEditingController();
  
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;
  bool _showOnlyActive = true;
  bool _hasActiveFilters = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _categories.clear();
        _isLoading = true;
      });
    }

    try {
      final response = await apiService.getCategories(
        page: _currentPage,
        limit: 20,
        isActive: _showOnlyActive ? true : null,
      );

      if (response['success']) {
        final data = response['data'];
        final newCategories = (data['categories'] as List)
            .map((json) => Category.fromJson(json))
            .toList();
        
        setState(() {
          if (refresh) {
            _categories = newCategories;
          } else {
            _categories.addAll(newCategories);
          }
          _totalPages = data['pagination']['totalPages'] ?? 1;
          _hasMoreData = _currentPage < _totalPages;
          _isLoading = false;
        });
        
        // Apply filters after loading data
        _applyFilters();
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load categories';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading categories: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: null,
      body: RefreshIndicator(
        onRefresh: () => _loadCategories(refresh: true),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(theme),
            _buildSearchAndFilters(theme),
            _buildCategoriesList(theme),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context),
        backgroundColor: AppColors.primary500,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Category',
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
                onPressed: () => context.go('/admin'),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.category,
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
                      '${_categories.length}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total Categories',
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
                  hintText: 'Search categories...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterCategoriesBySearch('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  _filterCategoriesBySearch(value);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _filterCategoriesBySearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories = _categories.where((category) {
          final name = category.name.toLowerCase();
          final description = category.description?.toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) || 
                 description.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredCategories = _categories.where((category) {
        // Active filter
        if (_showOnlyActive && !category.isActive) {
          return false;
        }
        
        return true;
      }).toList();
      
      // Update active filters state - consider both search and active filters
      _hasActiveFilters = !_showOnlyActive || _searchController.text.isNotEmpty;
    });
  }

  Widget _buildCategoriesList(ThemeData theme) {
    if (_isLoading && _categories.isEmpty) {
      return SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _categories.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(_errorMessage!, style: theme.textTheme.bodyLarge),
              SizedBox(height: 24),
              AppButton(
                text: 'Retry',
                onPressed: () => _loadCategories(refresh: true),
                style: AppButtonStyle.primary,
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredCategories.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.category_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant),
              SizedBox(height: 16),
              Text('No categories found', style: theme.textTheme.headlineSmall),
              SizedBox(height: 8),
              Text(
                'Try adding a new category or adjusting your search',
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
            if (index == _filteredCategories.length) {
              if (_hasMoreData) {
                return _buildLoadMoreButton();
              }
              return null;
            }
            
            final category = _filteredCategories[index];
            return _buildCategoryCard(theme, category);
          },
          childCount: _filteredCategories.length + (_hasMoreData ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(ThemeData theme, Category category) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEditCategoryDialog(context, category),
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
                child: Icon(Icons.category, color: AppColors.primary500, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (category.description != null && category.description!.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        category.description!,
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
                          '${category.productCount} products',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('•', style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                        SizedBox(width: 8),
                        Text(
                          'by ${category.createdBy}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                                              color: category.isActive 
                                ? AppColors.success500.withValues(alpha: 0.1)
                                : AppColors.error500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: category.isActive ? AppColors.success500 : AppColors.error500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: ElevatedButton(
          onPressed: _isLoading ? null : () {
            setState(() {
              _currentPage++;
            });
            _loadCategories();
          },
          child: _isLoading 
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Load More'),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Categories'),
        content: SwitchListTile(
          title: Text('Show only active'),
          value: _showOnlyActive,
          onChanged: (value) {
            setState(() {
              _showOnlyActive = value;
            });
            Navigator.pop(context);
            _loadCategories(refresh: true);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add Category'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final response = await apiService.createCategory({
                    'name': nameController.text.trim(),
                    'description': descriptionController.text.trim(),
                  });

                  if (!mounted) return;

                  if (response['success']) {
                    Navigator.pop(dialogContext);
                    _loadCategories(refresh: true);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Category created successfully')),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(response['message'] ?? 'Failed to create category'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error creating category: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }



  void _showEditCategoryDialog(BuildContext context, Category category) {
    final nameController = TextEditingController(text: category.name);
    final descriptionController = TextEditingController(text: category.description);
    final formKey = GlobalKey<FormState>();
    bool isActive = category.isActive;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit Category'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final response = await apiService.updateCategory(category.id, {
                    'name': nameController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'isActive': isActive,
                  });

                  if (!mounted) return;

                  if (response['success']) {
                    Navigator.pop(dialogContext);
                    _loadCategories(refresh: true);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Category updated successfully')),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(response['message'] ?? 'Failed to update category'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating category: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }
}
