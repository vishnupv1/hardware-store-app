class Admin {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String adminId;
  final String department;
  final String position;
  final DateTime hireDate;
  final double? salary;
  final bool isActive;
  final bool isLocked;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String adminLevel;
  final List<String> permissions;
  final String accessLevel;
  final List<String> allowedModules;
  final String? avatar;

  Admin({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.adminId,
    required this.department,
    required this.position,
    required this.hireDate,
    this.salary,
    required this.isActive,
    required this.isLocked,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
    required this.adminLevel,
    required this.permissions,
    required this.accessLevel,
    required this.allowedModules,
    this.avatar,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    try {
      // Validate required fields (excluding timestamps which can be optional)
      final requiredFields = ['email', 'firstName', 'lastName', 'adminId', 'department', 'position'];
      for (final field in requiredFields) {
        if (json[field] == null) {
          throw Exception('Required field "$field" is missing from admin data');
        }
      }
      
      // Parse dates with error handling
      DateTime parseDate(String fieldName, dynamic value) {
        if (value == null) {
          throw Exception('Date field "$fieldName" is missing');
        }
        try {
          return DateTime.parse(value.toString());
        } catch (e) {
          throw Exception('Invalid date format for "$fieldName": $value');
        }
      }
      
      final admin = Admin(
        id: json['_id'] ?? json['id'] ?? '',
        email: json['email'] ?? '',
        firstName: json['firstName'] ?? json['first_name'] ?? '',
        lastName: json['lastName'] ?? json['last_name'] ?? '',
        phoneNumber: json['phoneNumber'] ?? json['phone_number'],
        adminId: json['adminId'] ?? json['admin_id'] ?? '',
        department: json['department'] ?? '',
        position: json['position'] ?? '',
        hireDate: parseDate('hireDate', json['hireDate'] ?? json['hire_date']),
        salary: json['salary']?.toDouble(),
        isActive: json['isActive'] ?? json['is_active'] ?? true,
        isLocked: json['isLocked'] ?? json['is_locked'] ?? false,
        lastLogin: json['lastLogin'] != null 
            ? parseDate('lastLogin', json['lastLogin'])
            : json['last_login'] != null 
                ? parseDate('lastLogin', json['last_login'])
                : null,
        createdAt: json['createdAt'] != null ? parseDate('createdAt', json['createdAt']) : DateTime.now(),
        updatedAt: json['updatedAt'] != null ? parseDate('updatedAt', json['updatedAt']) : DateTime.now(),
        adminLevel: json['adminLevel'] ?? json['admin_level'] ?? 'admin',
        permissions: List<String>.from(json['permissions'] ?? []),
        accessLevel: json['accessLevel'] ?? json['access_level'] ?? 'limited_access',
        allowedModules: List<String>.from(json['allowedModules'] ?? json['allowed_modules'] ?? []),
        avatar: json['avatar'],
      );
      
      return admin;
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'adminId': adminId,
      'department': department,
      'position': position,
      'hireDate': hireDate.toIso8601String(),
      'salary': salary,
      'isActive': isActive,
      'isLocked': isLocked,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'adminLevel': adminLevel,
      'permissions': permissions,
      'accessLevel': accessLevel,
      'allowedModules': allowedModules,
      'avatar': avatar,
    };
  }

  String get fullName => '$firstName $lastName';
  String get displayName => fullName.isNotEmpty ? fullName : email;
  
  // Role getter to maintain compatibility with other user types
  String get role {
    // Map admin levels to role names for compatibility
    switch (adminLevel) {
      case 'super_admin':
        return 'super_admin';
      case 'admin':
        return 'admin';
      case 'manager':
        return 'manager';
      default:
        return 'admin';
    }
  }
  
  // Additional getters for compatibility with other user types
  bool get isEmailVerified => true; // Admins are typically verified
  bool get isPasswordExpired => false; // This can be calculated if needed
  
  int get yearsOfService {
    final now = DateTime.now();
    return now.year - hireDate.year - (now.month < hireDate.month || (now.month == hireDate.month && now.day < hireDate.day) ? 1 : 0);
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  bool canAccessModule(String module) {
    return allowedModules.contains(module);
  }

  bool hasFullAccess() {
    return accessLevel == 'full_access';
  }

  bool isSuperAdmin() {
    return adminLevel == 'super_admin';
  }

  @override
  String toString() {
    return 'Admin(id: $id, email: $email, name: $fullName, adminId: $adminId, level: $adminLevel, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Admin && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
