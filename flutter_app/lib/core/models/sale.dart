class SaleItem {
  final String? productId;
  final String productName;
  final String sku;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final double discount;

  SaleItem({
    this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.discount = 0,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      productId: json['productId'],
      productName: json['productName'] ?? '',
      sku: json['sku'] ?? '',
      quantity: json['quantity'] ?? 0,
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

  SaleItem copyWith({
    String? productId,
    String? productName,
    String? sku,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    double? discount,
  }) {
    return SaleItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      discount: discount ?? this.discount,
    );
  }
}

class ShippingAddress {
  final String? street;
  final String? city;
  final String? state;
  final String? pincode;
  final String? country;

  ShippingAddress({
    this.street,
    this.city,
    this.state,
    this.pincode,
    this.country,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      street: json['street'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
    };
  }
}

class PaymentDetails {
  final String? transactionId;
  final String? cardLast4;
  final String? bankName;
  final String? chequeNumber;

  PaymentDetails({
    this.transactionId,
    this.cardLast4,
    this.bankName,
    this.chequeNumber,
  });

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    return PaymentDetails(
      transactionId: json['transactionId'],
      cardLast4: json['cardLast4'],
      bankName: json['bankName'],
      chequeNumber: json['chequeNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'cardLast4': cardLast4,
      'bankName': bankName,
      'chequeNumber': chequeNumber,
    };
  }
}

class Sale {
  final String? id;
  final String? clientId;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final List<SaleItem> items;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String saleStatus;
  final String? notes;
  final String createdBy;
  final DateTime saleDate;
  final DateTime? dueDate;
  final double taxRate;
  final ShippingAddress? shippingAddress;
  final double shippingCost;
  final PaymentDetails? paymentDetails;
  final double refundAmount;
  final String? refundReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Sale({
    this.id,
    this.clientId,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.subtotal,
    this.taxAmount = 0,
    this.discountAmount = 0,
    required this.totalAmount,
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    this.saleStatus = 'completed',
    this.notes,
    required this.createdBy,
    required this.saleDate,
    this.dueDate,
    this.taxRate = 0,
    this.shippingAddress,
    this.shippingCost = 0,
    this.paymentDetails,
    this.refundAmount = 0,
    this.refundReason,
    this.createdAt,
    this.updatedAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['_id'],
      clientId: json['clientId'],
      invoiceNumber: json['invoiceNumber'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => SaleItem.fromJson(item))
          .toList() ?? [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      saleStatus: json['saleStatus'] ?? 'completed',
      notes: json['notes'],
      createdBy: json['createdBy'] ?? '',
      saleDate: DateTime.tryParse(json['saleDate'] ?? '') ?? DateTime.now(),
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
      taxRate: (json['taxRate'] ?? 0).toDouble(),
      shippingAddress: json['shippingAddress'] != null 
          ? ShippingAddress.fromJson(json['shippingAddress']) 
          : null,
      shippingCost: (json['shippingCost'] ?? 0).toDouble(),
      paymentDetails: json['paymentDetails'] != null 
          ? PaymentDetails.fromJson(json['paymentDetails']) 
          : null,
      refundAmount: (json['refundAmount'] ?? 0).toDouble(),
      refundReason: json['refundReason'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'items': items.map((item) => item.toJson()).toList(),
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'saleStatus': saleStatus,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'shippingCost': shippingCost,
      'notes': notes,
      'saleDate': saleDate.toIso8601String(),
      'shippingAddress': shippingAddress?.toJson(),
    };
  }

  Sale copyWith({
    String? id,
    String? clientId,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    List<SaleItem>? items,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    String? paymentMethod,
    String? paymentStatus,
    String? saleStatus,
    String? notes,
    String? createdBy,
    DateTime? saleDate,
    DateTime? dueDate,
    double? taxRate,
    ShippingAddress? shippingAddress,
    double? shippingCost,
    PaymentDetails? paymentDetails,
    double? refundAmount,
    String? refundReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Sale(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      saleStatus: saleStatus ?? this.saleStatus,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      saleDate: saleDate ?? this.saleDate,
      dueDate: dueDate ?? this.dueDate,
      taxRate: taxRate ?? this.taxRate,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      shippingCost: shippingCost ?? this.shippingCost,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      refundAmount: refundAmount ?? this.refundAmount,
      refundReason: refundReason ?? this.refundReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
