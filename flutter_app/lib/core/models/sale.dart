class Sale {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final List<SaleItem> items;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String paymentMethod; // cash, card, bank_transfer, credit
  final String paymentStatus; // pending, paid, partial
  final String saleStatus; // completed, cancelled, returned
  final String? notes;
  final String createdBy;
  final DateTime saleDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Sale({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.saleStatus,
    this.notes,
    required this.createdBy,
    required this.saleDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['_id'] ?? json['id'],
      invoiceNumber: json['invoiceNumber'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      items: (json['items'] as List<dynamic>)
          .map((item) => SaleItem.fromJson(item))
          .toList(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'],
      saleStatus: json['saleStatus'],
      notes: json['notes'],
      createdBy: json['createdBy'],
      saleDate: DateTime.parse(json['saleDate']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'customerName': customerName,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'saleStatus': saleStatus,
      'notes': notes,
      'createdBy': createdBy,
      'saleDate': saleDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isPaid => paymentStatus == 'paid';
  bool get isPending => paymentStatus == 'pending';
  bool get isCompleted => saleStatus == 'completed';
  bool get isCancelled => saleStatus == 'cancelled';
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  @override
  String toString() {
    return 'Sale(id: $id, invoice: $invoiceNumber, customer: $customerName, total: $totalAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Sale && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class SaleItem {
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final double discount;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.discount,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      productId: json['productId'],
      productName: json['productName'],
      sku: json['sku'],
      quantity: json['quantity'],
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'discount': discount,
    };
  }

  double get finalPrice => totalPrice - discount;
}
