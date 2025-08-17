import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class DropdownField extends StatefulWidget {
  final String label;
  final String? value;
  final Function(String?) onChanged;
  final bool isRequired;
  final String? errorText;
  final String type; // 'category', 'supplier', 'brand', or 'customer'

  const DropdownField({
    super.key,
    required this.label,
    this.value,
    required this.onChanged,
    this.isRequired = false,
    this.errorText,
    required this.type,
  });

  @override
  State<DropdownField> createState() => _DropdownFieldState();
}

class _DropdownFieldState extends State<DropdownField> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      Map<String, dynamic> response;
      if (widget.type == 'category') {
        response = await apiService.getCategoriesForDropdown();
      } else if (widget.type == 'supplier') {
        response = await apiService.getSuppliersForDropdown();
      } else if (widget.type == 'brand') {
        response = await apiService.getBrandsForDropdown();
      } else if (widget.type == 'customer') {
        response = await apiService.getCustomersForDropdown();
      } else {
        throw Exception('Invalid dropdown type');
      }

      if (response['success']) {
        setState(() {
          _items = List<Map<String, dynamic>>.from(response['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load items';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading items: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label + (widget.isRequired ? ' *' : ''),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.errorText != null 
                  ? Colors.red 
                  : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isLoading
              ? Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text('Loading...'),
                    ],
                  ),
                )
              : _errorMessage != null
                  ? Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.refresh, size: 20),
                            onPressed: _loadItems,
                          ),
                        ],
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      initialValue: widget.value,
                      onChanged: widget.onChanged,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        hintText: 'Select ${widget.label.toLowerCase()}',
                      ),
                      items: [
                        if (!widget.isRequired)
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('Select ${widget.label.toLowerCase()}'),
                          ),
                        ..._items.map((item) {
                          return DropdownMenuItem<String>(
                            value: item['_id'] ?? item['id'],
                            child: Text(item['name'] ?? ''),
                          );
                        }),
                      ],
                      validator: widget.isRequired
                          ? (value) {
                              if (value == null || value.isEmpty) {
                                return '${widget.label} is required';
                              }
                              return null;
                            }
                          : null,
                    ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
