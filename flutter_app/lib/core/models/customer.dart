class Customer {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? companyName;
  final String? gstNumber;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String customerType; // wholesale, retail, contractor
  final double creditLimit;
  final double currentBalance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.companyName,
    this.gstNumber,
    this.address,
    this.city,
    this.state,
    this.pincode,
    required this.customerType,
    required this.creditLimit,
    required this.currentBalance,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      companyName: json['companyName'],
      gstNumber: json['gstNumber'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      customerType: json['customerType'] ?? 'retail',
      creditLimit: (json['creditLimit'] ?? 0).toDouble(),
      currentBalance: (json['currentBalance'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'companyName': companyName,
      'gstNumber': gstNumber,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'customerType': customerType,
      'creditLimit': creditLimit,
      'currentBalance': currentBalance,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get displayName => companyName?.isNotEmpty == true ? companyName! : name;
  bool get isWholesale => customerType == 'wholesale';
  bool get isContractor => customerType == 'contractor';
  double get availableCredit => creditLimit - currentBalance;
  bool get isOverCreditLimit => currentBalance > creditLimit;

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, type: $customerType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
