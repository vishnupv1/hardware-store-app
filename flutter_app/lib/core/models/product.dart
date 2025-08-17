class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final String subcategory;
  final String brand;
  final String model;
  final String sku;
  final double costPrice;
  final double sellingPrice;
  final double wholesalePrice;
  final int stockQuantity;
  final int minStockLevel;
  final String unit; // pieces, kg, meters, etc.
  final String? imageUrl;
  final Map<String, dynamic> specifications;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.brand,
    required this.model,
    required this.sku,
    required this.costPrice,
    required this.sellingPrice,
    required this.wholesalePrice,
    required this.stockQuantity,
    required this.minStockLevel,
    required this.unit,
    this.imageUrl,
    required this.specifications,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      description: json['description'],
      category: _extractName(json['category']),
      subcategory: _extractName(json['subcategory']),
      brand: _extractName(json['brand']),
      model: json['model'],
      sku: json['sku'],
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
      wholesalePrice: (json['wholesalePrice'] ?? 0).toDouble(),
      stockQuantity: json['stockQuantity'] ?? 0,
      minStockLevel: json['minStockLevel'] ?? 0,
      unit: json['unit'],
      imageUrl: json['imageUrl'],
      specifications: json['specifications'] ?? {},
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  static String _extractName(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      return value['name'] ?? '';
    }
    return '';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'subcategory': subcategory,
      'brand': brand,
      'model': model,
      'sku': sku,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'wholesalePrice': wholesalePrice,
      'stockQuantity': stockQuantity,
      'minStockLevel': minStockLevel,
      'unit': unit,
      'imageUrl': imageUrl,
      'specifications': specifications,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isLowStock => stockQuantity <= minStockLevel;
  bool get isOutOfStock => stockQuantity <= 0;
  double get profitMargin => sellingPrice - costPrice;
  double get profitMarginPercentage => costPrice > 0 ? ((sellingPrice - costPrice) / costPrice) * 100 : 0;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, sku: $sku, stock: $stockQuantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
