class Employee {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String employeeId;
  final String department;
  final String position;
  final DateTime hireDate;
  final double? salary;
  final bool isActive;
  final bool isLocked;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String role;
  final List<String> permissions;
  final String? avatar;

  Employee({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.employeeId,
    required this.department,
    required this.position,
    required this.hireDate,
    this.salary,
    required this.isActive,
    required this.isLocked,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
    required this.role,
    required this.permissions,
    this.avatar,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['_id'] ?? json['id'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      employeeId: json['employeeId'],
      department: json['department'],
      position: json['position'],
      hireDate: DateTime.parse(json['hireDate']),
      salary: json['salary']?.toDouble(),
      isActive: json['isActive'] ?? true,
      isLocked: json['isLocked'] ?? false,
      lastLogin: json['lastLogin'] != null 
          ? DateTime.parse(json['lastLogin']) 
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      role: json['role'] ?? 'employee',
      permissions: List<String>.from(json['permissions'] ?? []),
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'employeeId': employeeId,
      'department': department,
      'position': position,
      'hireDate': hireDate.toIso8601String(),
      'salary': salary,
      'isActive': isActive,
      'isLocked': isLocked,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'role': role,
      'permissions': permissions,
      'avatar': avatar,
    };
  }

  String get fullName => '$firstName $lastName';
  String get displayName => fullName.isNotEmpty ? fullName : email;
  
  int get yearsOfService {
    final now = DateTime.now();
    return now.year - hireDate.year - (now.month < hireDate.month || (now.month == hireDate.month && now.day < hireDate.day) ? 1 : 0);
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  bool hasAnyPermission(List<String> requiredPermissions) {
    return requiredPermissions.any((permission) => permissions.contains(permission));
  }

  bool hasAllPermissions(List<String> requiredPermissions) {
    return requiredPermissions.every((permission) => permissions.contains(permission));
  }

  @override
  String toString() {
    return 'Employee(id: $id, email: $email, name: $fullName, employeeId: $employeeId, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Employee && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  Employee copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? employeeId,
    String? department,
    String? position,
    DateTime? hireDate,
    double? salary,
    bool? isActive,
    bool? isLocked,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? role,
    List<String>? permissions,
    String? avatar,
  }) {
    return Employee(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      position: position ?? this.position,
      hireDate: hireDate ?? this.hireDate,
      salary: salary ?? this.salary,
      isActive: isActive ?? this.isActive,
      isLocked: isLocked ?? this.isLocked,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      avatar: avatar ?? this.avatar,
    );
  }
}
