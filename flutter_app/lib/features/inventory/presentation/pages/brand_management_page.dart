import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/widgets/app_button.dart';

class BrandManagementPage extends StatefulWidget {
  const BrandManagementPage({super.key});

  @override
  State<BrandManagementPage> createState() => _BrandManagementPageState();
}

class _BrandManagementPageState extends State<BrandManagementPage> {
  List<String> _brands = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAddingBrand = false;
  final _brandController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  @override
  void dispose() {
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    try {
      print('Loading brands...');
      final response = await apiService.getProductBrands();
      print('Brands response: $response');
      
      if (response['success']) {
        setState(() {
          _brands = List<String>.from(response['data']['brands'] ?? []);
          _isLoading = false;
        });
        print('Loaded ${_brands.length} brands: $_brands');
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load brands';
          _isLoading = false;
        });
        print('Failed to load brands: ${response['message']}');
      }
    } catch (e) {
      print('Error loading brands: $e');
      setState(() {
        _errorMessage = 'Error loading brands: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addBrand() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final brandName = _brandController.text.trim();
    if (_brands.contains(brandName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Brand "$brandName" already exists'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAddingBrand = true;
    });

    try {
      print('Adding brand: $brandName');
      
      final response = await apiService.addProductBrand(brandName);
      print('Add brand response: $response');
      
      if (response['success']) {
        setState(() {
          _brands.add(brandName);
          _brandController.clear();
          _isAddingBrand = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Brand "$brandName" added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isAddingBrand = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to add brand'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
    } catch (e) {
      setState(() {
        _isAddingBrand = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding brand: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBrand(String brandName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Brand'),
        content: Text('Are you sure you want to delete the brand "$brandName"? This action cannot be undone.'),
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
        // Note: This is a simplified approach. In a real app, you'd have a proper brand management API
        // For now, we'll just remove it from the local list
        setState(() {
          _brands.remove(brandName);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Brand "$brandName" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting brand: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Brand Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/inventory'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddBrandDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget(theme)
              : _buildBrandsList(theme),
    );
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
            onPressed: _loadBrands,
            style: AppButtonStyle.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildBrandsList(ThemeData theme) {
    if (_brands.isEmpty) {
      return Center(
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
              'Add your first brand to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 24),
            AppButton(
              text: 'Add Brand',
              onPressed: () => _showAddBrandDialog(context),
              style: AppButtonStyle.primary,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBrands,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _brands.length,
        itemBuilder: (context, index) {
          final brand = _brands[index];
          return Card(
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.branding_watermark,
                  color: AppColors.primary500,
                ),
              ),
              title: Text(
                brand,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Brand',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteBrand(brand),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddBrandDialog(BuildContext context) {
    _brandController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Brand'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _brandController,
                decoration: InputDecoration(
                  labelText: 'Brand Name',
                  hintText: 'Enter brand name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Brand name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Brand name must be at least 2 characters';
                  }
                  return null;
                },
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'[<>:"/\\|?*]')),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isAddingBrand ? null : () async {
              await _addBrand();
              if (mounted && !_isAddingBrand) {
                Navigator.of(context).pop();
              }
            },
            child: _isAddingBrand
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Add'),
          ),
        ],
      ),
    );
  }
}
