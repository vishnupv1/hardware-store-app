class Supplier {
  final String id;
  final String name;
  final ContactPerson? contactPerson;
  final Address? address;
  final BusinessInfo? businessInfo;
  final bool isActive;
  final String createdBy;
  final int productCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Supplier({
    required this.id,
    required this.name,
    this.contactPerson,
    this.address,
    this.businessInfo,
    required this.isActive,
    required this.createdBy,
    required this.productCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      contactPerson: json['contactPerson'] != null 
          ? ContactPerson.fromJson(json['contactPerson'])
          : null,
      address: json['address'] != null 
          ? Address.fromJson(json['address'])
          : null,
      businessInfo: json['businessInfo'] != null 
          ? BusinessInfo.fromJson(json['businessInfo'])
          : null,
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
      'contactPerson': contactPerson?.toJson(),
      'address': address?.toJson(),
      'businessInfo': businessInfo?.toJson(),
      'isActive': isActive,
      'createdBy': createdBy,
      'productCount': productCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Supplier copyWith({
    String? id,
    String? name,
    ContactPerson? contactPerson,
    Address? address,
    BusinessInfo? businessInfo,
    bool? isActive,
    String? createdBy,
    int? productCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      address: address ?? this.address,
      businessInfo: businessInfo ?? this.businessInfo,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      productCount: productCount ?? this.productCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ContactPerson {
  final String? name;
  final String? email;
  final String? phone;

  ContactPerson({
    this.name,
    this.email,
    this.phone,
  });

  factory ContactPerson.fromJson(Map<String, dynamic> json) {
    return ContactPerson(
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
    };
  }
}

class Address {
  final String? street;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;

  Address({
    this.street,
    this.city,
    this.state,
    this.zipCode,
    this.country,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zipCode'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
    };
  }
}

class BusinessInfo {
  final String? website;
  final String? taxId;
  final String? paymentTerms;

  BusinessInfo({
    this.website,
    this.taxId,
    this.paymentTerms,
  });

  factory BusinessInfo.fromJson(Map<String, dynamic> json) {
    return BusinessInfo(
      website: json['website'],
      taxId: json['taxId'],
      paymentTerms: json['paymentTerms'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'website': website,
      'taxId': taxId,
      'paymentTerms': paymentTerms,
    };
  }
}
