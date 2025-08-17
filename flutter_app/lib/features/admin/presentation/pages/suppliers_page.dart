import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/supplier.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  final _searchController = TextEditingController();
  
  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];
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
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _suppliers.clear();
        _isLoading = true;
        _hasActiveFilters = !_showOnlyActive || _searchController.text.isNotEmpty;
      });
    }

    try {
      final response = await apiService.getSuppliers(
        page: _currentPage,
        limit: 20,
        isActive: _showOnlyActive ? true : null,
      );

      if (response['success']) {
        final data = response['data'];
        final newSuppliers = (data['suppliers'] as List)
            .map((json) => Supplier.fromJson(json))
            .toList();
        
        setState(() {
          if (refresh) {
            _suppliers = newSuppliers;
          } else {
            _suppliers.addAll(newSuppliers);
          }
          _filteredSuppliers = _suppliers;
          _totalPages = data['pagination']['totalPages'] ?? 1;
          _hasMoreData = _currentPage < _totalPages;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load suppliers';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading suppliers: $e';
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
        onRefresh: () => _loadSuppliers(refresh: true),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(theme),
            _buildSearchAndFilters(theme),
            _buildSuppliersList(theme),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSupplierDialog(context),
        backgroundColor: AppColors.primary500,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Supplier',
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
                  Icons.local_shipping,
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
                      '${_suppliers.length}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total Suppliers',
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
                  hintText: 'Search suppliers...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterSuppliersBySearch('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  _filterSuppliersBySearch(value);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _filterSuppliersBySearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSuppliers = _suppliers;
      } else {
        _filteredSuppliers = _suppliers.where((supplier) {
          final name = supplier.name.toLowerCase();
          final contactName = supplier.contactPerson?.name?.toLowerCase() ?? '';
          final contactEmail = supplier.contactPerson?.email?.toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) || 
                 contactName.contains(query.toLowerCase()) ||
                 contactEmail.contains(query.toLowerCase());
        }).toList();
      }
      
      // Update active filters state - consider both search and active filters
      _hasActiveFilters = !_showOnlyActive || query.isNotEmpty;
    });
  }

  Widget _buildSuppliersList(ThemeData theme) {
    if (_isLoading && _suppliers.isEmpty) {
      return SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _suppliers.isEmpty) {
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
                onPressed: () => _loadSuppliers(refresh: true),
                style: AppButtonStyle.primary,
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredSuppliers.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_shipping_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant),
              SizedBox(height: 16),
              Text('No suppliers found', style: theme.textTheme.headlineSmall),
              SizedBox(height: 8),
              Text(
                'Try adding a new supplier or adjusting your search',
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
            if (index == _filteredSuppliers.length) {
              if (_hasMoreData) {
                return _buildLoadMoreButton();
              }
              return null;
            }
            
            final supplier = _filteredSuppliers[index];
            return _buildSupplierCard(theme, supplier);
          },
          childCount: _filteredSuppliers.length + (_hasMoreData ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildSupplierCard(ThemeData theme, Supplier supplier) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEditSupplierDialog(context, supplier),
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
                child: Icon(Icons.local_shipping, color: AppColors.primary500, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (supplier.contactPerson?.name != null) ...[
                      SizedBox(height: 4),
                      Text(
                        'Contact: ${supplier.contactPerson!.name}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (supplier.contactPerson?.email != null) ...[
                      SizedBox(height: 2),
                      Text(
                        supplier.contactPerson!.email!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${supplier.productCount} products',
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
                          'by ${supplier.createdBy}',
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
                  color: supplier.isActive 
                      ? AppColors.success500.withValues(alpha: 0.1)
                      : AppColors.error500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  supplier.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: supplier.isActive ? AppColors.success500 : AppColors.error500,
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
            _loadSuppliers();
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
        title: Text('Filter Suppliers'),
        content: SwitchListTile(
          title: Text('Show only active'),
          value: _showOnlyActive,
          onChanged: (value) {
            setState(() {
              _showOnlyActive = value;
              _hasActiveFilters = !value || _searchController.text.isNotEmpty;
            });
            Navigator.pop(context);
            _loadSuppliers(refresh: true);
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

  void _showAddSupplierDialog(BuildContext context) {
    final nameController = TextEditingController();
    final contactNameController = TextEditingController();
    final contactEmailController = TextEditingController();
    final contactPhoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add Supplier'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Supplier Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a supplier name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: contactNameController,
                  decoration: InputDecoration(
                    labelText: 'Contact Person Name (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: contactEmailController,
                  decoration: InputDecoration(
                    labelText: 'Contact Email (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: contactPhoneController,
                  decoration: InputDecoration(
                    labelText: 'Contact Phone (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
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
                  final response = await apiService.createSupplier({
                    'name': nameController.text.trim(),
                    'contactPerson': {
                      'name': contactNameController.text.trim(),
                      'email': contactEmailController.text.trim(),
                      'phone': contactPhoneController.text.trim(),
                    },
                  });

                  if (!mounted) return;

                  if (response['success']) {
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                    _loadSuppliers(refresh: true);
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Supplier created successfully')),
                      );
                    }
                  } else {
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(response['message'] ?? 'Failed to create supplier'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error creating supplier: $e'),
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

  void _showEditSupplierDialog(BuildContext context, Supplier supplier) {
    final nameController = TextEditingController(text: supplier.name);
    final contactNameController = TextEditingController(text: supplier.contactPerson?.name);
    final contactEmailController = TextEditingController(text: supplier.contactPerson?.email);
    final contactPhoneController = TextEditingController(text: supplier.contactPerson?.phone);
    final formKey = GlobalKey<FormState>();
    bool isActive = supplier.isActive;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit Supplier'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Supplier Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a supplier name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: contactNameController,
                  decoration: InputDecoration(
                    labelText: 'Contact Person Name (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: contactEmailController,
                  decoration: InputDecoration(
                    labelText: 'Contact Email (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: contactPhoneController,
                  decoration: InputDecoration(
                    labelText: 'Contact Phone (Optional)',
                    border: OutlineInputBorder(),
                  ),
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
                  final response = await apiService.updateSupplier(supplier.id, {
                    'name': nameController.text.trim(),
                    'contactPerson': {
                      'name': contactNameController.text.trim(),
                      'email': contactEmailController.text.trim(),
                      'phone': contactPhoneController.text.trim(),
                    },
                    'isActive': isActive,
                  });

                  if (!mounted) return;

                  if (response['success']) {
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                    _loadSuppliers(refresh: true);
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Supplier updated successfully')),
                      );
                    }
                  } else {
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(response['message'] ?? 'Failed to update supplier'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating supplier: $e'),
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
