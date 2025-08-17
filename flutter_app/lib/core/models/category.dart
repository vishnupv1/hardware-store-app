class Category {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final String createdBy;
  final int productCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    required this.createdBy,
    required this.productCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      isActive: json['isActive'] ?? true,
      createdBy: json['createdBy']?['firstName'] != null 
          ? '${json['createdBy']['firstName']} ${json['createdBy']['lastName']}'
          : json['createdBy'] ?? '',
      productCount: json['productCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdBy': createdBy,
      'productCount': productCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
    String? createdBy,
    int? productCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      productCount: productCount ?? this.productCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
