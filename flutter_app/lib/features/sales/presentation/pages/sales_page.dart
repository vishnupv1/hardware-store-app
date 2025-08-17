import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/widgets/app_button.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _filteredSales = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _selectedStatus;
  String? _selectedPaymentMethod;
  int _currentPage = 1;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSales({bool refresh = false}) async {
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

      final response = await apiService.getSales(
        page: _currentPage,
        limit: 20,
        saleStatus: _selectedStatus,
        paymentStatus: _selectedPaymentMethod,
      );

      if (response['success']) {
        final data = response['data'];
        final sales = List<Map<String, dynamic>>.from(data['sales'] ?? []);

        setState(() {
          if (refresh) {
            _sales = sales;
          } else {
            _sales.addAll(sales);
          }
          _filteredSales = _sales;
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
        _showErrorSnackBar('Failed to load sales');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      _showErrorSnackBar('Failed to load sales');
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

  void _debounceSearch() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == _searchController.text) {
        _loadSales(refresh: true);
      }
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Sales'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status filter
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text('All Statuses')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
              ),
              SizedBox(height: 16),
              // Payment method filter
              DropdownButtonFormField<String>(
                initialValue: _selectedPaymentMethod,
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text('All Methods')),
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'card', child: Text('Card')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI')),
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadSales(refresh: true);
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => _loadSales(refresh: true),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(theme),
            _buildSearchAndFilters(theme),
            _buildSalesList(theme),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/sales/add'),
        backgroundColor: AppColors.primary500,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Sale',
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
          gradient: AppColors.successGradient,
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
                  Icons.point_of_sale,
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
                      '${_sales.length}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total Sales',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.filter_list, color: Colors.white),
                    onPressed: _showFilterDialog,
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
                  hintText: 'Search sales...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _loadSales(refresh: true);
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

  Widget _buildSalesList(ThemeData theme) {
    if (_isLoading && _sales.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError && _sales.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error500,
              ),
              SizedBox(height: 16),
              Text(
                'Failed to load sales',
                style: theme.textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              AppButton(
                text: 'Retry',
                onPressed: () => _loadSales(refresh: true),
                style: AppButtonStyle.secondary,
              ),
            ],
          ),
        ),
      );
    }

    if (_sales.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.point_of_sale,
                size: 64,
                color: AppColors.primary500,
              ),
              SizedBox(height: 16),
              Text(
                'No Sales Found',
                style: theme.textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              Text(
                'Start by creating your first sale',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= _filteredSales.length) {
              if (_hasMoreData) {
                _loadSales();
                return _buildLoadMoreButton();
              }
              return null;
            }

            final sale = _filteredSales[index];
            return _buildSaleCard(theme, sale);
          },
          childCount: _filteredSales.length + (_hasMoreData ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildSaleCard(ThemeData theme, Map<String, dynamic> sale) {
    final total = sale['totalAmount'] ?? 0.0;
    final status = sale['saleStatus'] ?? 'pending';
    final customerName = sale['customerName'] ?? 'Unknown Customer';
    final date = DateTime.tryParse(sale['saleDate'] ?? '') ?? DateTime.now();

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/sales/${sale['_id']}'),
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
                          customerName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sale # : ${sale['invoiceNumber'] ?? 'N/A'}',
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
                        '₹${total.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary500,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusLabel(status),
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
                      'Date: ${_formatDate(date)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (sale['paymentMethod'] != null)
                    Expanded(
                      child: Text(
                        'Payment: ${_getPaymentMethodLabel(sale['paymentMethod'])}',
                        style: theme.textTheme.bodyMedium,
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

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : AppButton(
                text: 'Load More',
                onPressed: _loadSales,
                style: AppButtonStyle.secondary,
              ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String _getPaymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'upi':
        return 'UPI';
      case 'bank_transfer':
        return 'Bank';
      default:
        return method;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
