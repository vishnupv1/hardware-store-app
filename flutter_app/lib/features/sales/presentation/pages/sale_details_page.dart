import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/sale.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/widgets/app_button.dart';

class SaleDetailsPage extends StatefulWidget {
  final String saleId;

  const SaleDetailsPage({
    super.key,
    required this.saleId,
  });

  @override
  State<SaleDetailsPage> createState() => _SaleDetailsPageState();
}

class _SaleDetailsPageState extends State<SaleDetailsPage> {
  Sale? _sale;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSaleDetails();
  }

  Future<void> _loadSaleDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final response = await apiService.getSale(widget.saleId);
      
      if (!mounted) return;
      
      if (response['success']) {
        final saleData = response['data']['sale'];
        setState(() {
          _sale = Sale.fromJson(saleData);
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = response['message'] ?? 'Failed to load sale details';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading sale details: $e';
        _isLoading = false;
      });
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

  void _editSale() {
    context.go('/sales/${widget.saleId}/edit');
  }

  void _deleteSale() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Sale'),
        content: Text('Are you sure you want to delete this sale? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _confirmDeleteSale();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteSale() async {
    try {
      final response = await apiService.cancelSale(widget.saleId);
      
      if (!mounted) return;
      
      if (response['success']) {
        _showSuccessSnackBar('Sale deleted successfully');
        context.go('/sales');
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to delete sale');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error deleting sale: $e');
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'returned':
        return Colors.purple;
      case 'refunded':
        return Colors.blue;
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
      case 'returned':
        return 'Returned';
      case 'refunded':
        return 'Refunded';
      default:
        return status;
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
      case 'credit':
        return 'Credit';
      case 'cheque':
        return 'Cheque';
      default:
        return method;
    }
  }

  String _getPaymentStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'partial':
        return 'Partial';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Sale Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/sales'),
        ),
        actions: [
          if (_sale != null) ...[
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: _editSale,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteSale,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
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
                        'Failed to load sale details',
                        style: theme.textTheme.titleLarge,
                      ),
                      SizedBox(height: 8),
                      Text(
                        _errorMessage ?? 'Unknown error occurred',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      AppButton(
                        text: 'Retry',
                        onPressed: _loadSaleDetails,
                        style: AppButtonStyle.secondary,
                      ),
                    ],
                  ),
                )
              : _sale == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Sale not found',
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _sale!.invoiceNumber,
                                              style: theme.textTheme.headlineSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Invoice Number',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${_sale!.totalAmount.toStringAsFixed(2)}',
                                            style: theme.textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary500,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(_sale!.saleStatus),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _getStatusLabel(_sale!.saleStatus),
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
                                ],
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Customer Information
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
                                  
                                  _buildInfoRow('Customer Name', _sale!.customerName),
                                  _buildInfoRow('Customer ID', _sale!.customerId),
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
                                  Text(
                                    'Sale Items (${_sale!.items.length})',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  
                                  ..._sale!.items.map((item) => Card(
                                    margin: EdgeInsets.only(bottom: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.productName,
                                                  style: theme.textTheme.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '₹${item.totalPrice.toStringAsFixed(2)}',
                                                style: theme.textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'SKU: ${item.sku}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Qty: ${item.quantity} × ₹${item.unitPrice.toStringAsFixed(2)}',
                                                style: theme.textTheme.bodySmall,
                                              ),
                                              if (item.discount > 0)
                                                Text(
                                                  'Discount: ₹${item.discount.toStringAsFixed(2)}',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: Colors.green,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
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
                                        child: _buildInfoRow(
                                          'Payment Method',
                                          _getPaymentMethodLabel(_sale!.paymentMethod),
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildInfoRow(
                                          'Payment Status',
                                          _getPaymentStatusLabel(_sale!.paymentStatus),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Financial Summary
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Financial Summary',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  
                                  _buildInfoRow('Subtotal', '₹${_sale!.subtotal.toStringAsFixed(2)}'),
                                  _buildInfoRow('Tax Amount', '₹${_sale!.taxAmount.toStringAsFixed(2)}'),
                                  _buildInfoRow('Discount Amount', '₹${_sale!.discountAmount.toStringAsFixed(2)}'),
                                  _buildInfoRow('Shipping Cost', '₹${_sale!.shippingCost.toStringAsFixed(2)}'),
                                  Divider(),
                                  _buildInfoRow(
                                    'Total Amount',
                                    '₹${_sale!.totalAmount.toStringAsFixed(2)}',
                                    isTotal: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Shipping Address
                          if (_sale!.shippingAddress != null) ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Shipping Address',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                  
                                    if (_sale!.shippingAddress!.street?.isNotEmpty == true)
                                      _buildInfoRow('Street', _sale!.shippingAddress!.street!),
                                    if (_sale!.shippingAddress!.city?.isNotEmpty == true)
                                      _buildInfoRow('City', _sale!.shippingAddress!.city!),
                                    if (_sale!.shippingAddress!.state?.isNotEmpty == true)
                                      _buildInfoRow('State', _sale!.shippingAddress!.state!),
                                    if (_sale!.shippingAddress!.pincode?.isNotEmpty == true)
                                      _buildInfoRow('Pincode', _sale!.shippingAddress!.pincode!),
                                    if (_sale!.shippingAddress!.country?.isNotEmpty == true)
                                      _buildInfoRow('Country', _sale!.shippingAddress!.country!),
                                  ],
                                ),
                              ),
                            ),
                            
                            SizedBox(height: 16),
                          ],
                          
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
                                  
                                  _buildInfoRow('Sale Date', _formatDate(_sale!.saleDate)),
                                  if (_sale!.dueDate != null)
                                    _buildInfoRow('Due Date', _formatDate(_sale!.dueDate)),
                                  _buildInfoRow('Created By', _sale!.createdBy),
                                  if (_sale!.createdAt != null)
                                    _buildInfoRow('Created At', _formatDate(_sale!.createdAt)),
                                  if (_sale!.updatedAt != null)
                                    _buildInfoRow('Updated At', _formatDate(_sale!.updatedAt)),
                                  if (_sale!.notes?.isNotEmpty == true)
                                    _buildInfoRow('Notes', _sale!.notes!),
                                ],
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 32),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? AppColors.primary500 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
