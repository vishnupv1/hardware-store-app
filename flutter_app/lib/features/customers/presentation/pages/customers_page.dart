import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/customer.dart';
import '../../../../shared/widgets/app_button.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _customers = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _selectedCustomerType;
  String? _selectedStatus;
  int _currentPage = 1;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreData = true;
        _hasError = false;
      });
    }

    if (!_hasMoreData && !refresh) return;

    try {
      setState(() {
        if (refresh) {
          _isLoading = true;
          _hasError = false;
        }
      });

      final response = await apiService.getCustomers(
        page: _currentPage,
        limit: 20,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        customerType: _selectedCustomerType,
        isActive: _selectedStatus == 'active' ? true : _selectedStatus == 'inactive' ? false : null,
      );

      if (response['success']) {
        final data = response['data'];
        final customers = (data['customers'] as List)
            .map((json) => Customer.fromJson(json))
            .toList();

        setState(() {
          if (refresh) {
            _customers = customers;
          } else {
            _customers.addAll(customers);
          }
          _currentPage++;
          _hasMoreData = data['pagination']['hasNext'];
          _isLoading = false;
          _hasError = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        _showErrorSnackBar('Failed to load customers');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      _showErrorSnackBar('Failed to load customers');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(theme),
          _buildSearchAndFilters(theme),
          _buildCustomersList(theme),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/customers/add'),
        backgroundColor: AppColors.primary500,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Customer',
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
                  Icons.people,
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
                      '${_customers.length}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total Customers',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                                    ),
                      IconButton(
                        icon: Icon(Icons.filter_list, color: Colors.white),
                        onPressed: _showFilterDialog,
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
                  hintText: 'Search customers...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _loadCustomers(refresh: true);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  _debounceSearch();
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }




  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Customers'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Customer type filter
              DropdownButtonFormField<String>(
                initialValue: _selectedCustomerType,
                decoration: InputDecoration(
                  labelText: 'Customer Type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text('All Types'),
                  ),
                  DropdownMenuItem(
                    value: 'retail',
                    child: Text('Retail'),
                  ),
                  DropdownMenuItem(
                    value: 'wholesale',
                    child: Text('Wholesale'),
                  ),
                  DropdownMenuItem(
                    value: 'contractor',
                    child: Text('Contractor'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCustomerType = value;
                  });
                },
              ),
              SizedBox(height: 16),
              // Status filter
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text('All Status'),
                  ),
                  DropdownMenuItem(
                    value: 'active',
                    child: Text('Active'),
                  ),
                  DropdownMenuItem(
                    value: 'inactive',
                    child: Text('Inactive'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
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
                _selectedCustomerType = null;
                _selectedStatus = null;
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
              Navigator.of(context).pop();
              _loadCustomers(refresh: true);
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _debounceSearch() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == _searchController.text) {
        _loadCustomers(refresh: true);
      }
    });
  }

  Widget _buildCustomersList(ThemeData theme) {
    if (_isLoading && _customers.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_customers.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _hasError ? Icons.error_outline : Icons.people_outline,
                size: 64,
                color: _hasError ? AppColors.error500 : AppColors.neutral400,
              ),
              const SizedBox(height: 16),
              Text(
                _hasError ? 'Failed to load customers' : 'No customers found',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _hasError ? AppColors.error500 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _hasError 
                    ? 'Please check your connection and try again'
                    : 'Add your first customer to get started',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 24),
              if (_hasError)
                AppButton(
                  text: 'Retry',
                  onPressed: () => _loadCustomers(refresh: true),
                  style: AppButtonStyle.primary,
                )
              else
                              AppButton(
                text: 'Add Customer',
                onPressed: () => context.go('/customers/add'),
                style: AppButtonStyle.primary,
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= _customers.length) {
            if (_hasMoreData) {
              _loadCustomers();
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return null;
          }

          final customer = _customers[index];
          return _buildCustomerCard(theme, customer);
        },
        childCount: _customers.length + (_hasMoreData ? 1 : 0),
      ),
    );
  }

  Widget _buildCustomerCard(ThemeData theme, Customer customer) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showCustomerDetails(customer),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: _getCustomerTypeGradient(customer.customerType),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(
                        _getCustomerTypeIcon(customer.customerType),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            customer.email,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCustomerTypeColor(customer.customerType).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            customer.customerType.toUpperCase(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _getCustomerTypeColor(customer.customerType),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: customer.isActive 
                                ? AppColors.success500.withValues(alpha: 0.1)
                                : AppColors.error500.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            customer.isActive ? 'ACTIVE' : 'INACTIVE',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: customer.isActive 
                                  ? AppColors.success500
                                  : AppColors.error500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildCustomerInfo(
                        'Phone',
                        customer.phoneNumber,
                        Icons.phone,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCustomerInfo(
                        'Credit Limit',
                        '₹${customer.creditLimit.toStringAsFixed(0)}',
                        Icons.account_balance_wallet,
                      ),
                    ),
                  ],
                ),
                if (customer.companyName?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  _buildCustomerInfo(
                    'Company',
                    customer.companyName!,
                    Icons.business,
                  ),
                ],
                if (customer.isOverCreditLimit) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: AppColors.error500,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Credit limit exceeded',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.error500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  LinearGradient _getCustomerTypeGradient(String customerType) {
    switch (customerType) {
      case 'wholesale':
        return AppColors.primaryGradient;
      case 'retail':
        return AppColors.successGradient;
      case 'contractor':
        return AppColors.warningGradient;
      default:
        return AppColors.secondaryGradient;
    }
  }

  Color _getCustomerTypeColor(String customerType) {
    switch (customerType) {
      case 'wholesale':
        return AppColors.primary500;
      case 'retail':
        return AppColors.success500;
      case 'contractor':
        return AppColors.warning500;
      default:
        return AppColors.secondary500;
    }
  }

  IconData _getCustomerTypeIcon(String customerType) {
    switch (customerType) {
      case 'wholesale':
        return Icons.store;
      case 'retail':
        return Icons.shopping_cart;
      case 'contractor':
        return Icons.build;
      default:
        return Icons.person;
    }
  }

  void _showCustomerDetails(Customer customer) {
    context.go('/customers/${customer.id}');
  }


}
