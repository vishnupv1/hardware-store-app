import 'package:flutter/material.dart';
import '../../shared/providers/auth_provider.dart';

class RoleBasedAccess {
  // Admin-only operations
  static const List<String> adminOnlyOperations = [
    'create_customer',
    'add_product',
    'add_category',
    'add_brand',
    'manage_suppliers',
    'manage_employees',
    'system_settings',
    'user_management',
    'billing_management',
    'content_management',
    'advanced_analytics',
    'data_export',
    'audit_logs',
  ];

  // Operations allowed for employees and admins
  static const List<String> employeeAndAdminOperations = [
    'view_dashboard',
    'view_customers',
    'view_products',
    'view_sales',
    'view_inventory',
    'view_reports',
    'create_sales',
    'edit_sales',
    'delete_sales',
    'edit_customers',
    'edit_products',
  ];

  // Operations allowed for all authenticated users
  static const List<String> allUserOperations = [
    'view_profile',
    'edit_profile',
    'view_dashboard',
    'view_reports',
  ];

  // Check if user has permission for a specific operation
  static bool hasPermission(AuthProvider authProvider, String operation) {
    final user = authProvider.user;
    if (user == null) return false;

    // Admin has access to everything
    if (authProvider.userAsAdmin != null) {
      return true;
    }

    // Check admin-only operations
    if (adminOnlyOperations.contains(operation)) {
      return authProvider.userAsAdmin != null;
    }

    // Check employee and admin operations
    if (employeeAndAdminOperations.contains(operation)) {
      return authProvider.userAsAdmin != null || authProvider.userAsEmployee != null;
    }

    // Check all user operations
    if (allUserOperations.contains(operation)) {
      return true;
    }

    return false;
  }

  // Check if user is admin
  static bool isAdmin(AuthProvider authProvider) {
    return authProvider.userAsAdmin != null;
  }

  // Check if user is employee
  static bool isEmployee(AuthProvider authProvider) {
    return authProvider.userAsEmployee != null;
  }

  // Check if user is client
  static bool isClient(AuthProvider authProvider) {
    return authProvider.userAsClient != null;
  }

  // Check if user is regular user
  static bool isUser(AuthProvider authProvider) {
    return authProvider.userAsUser != null;
  }

  // Get user role for display
  static String getUserRole(AuthProvider authProvider) {
    if (authProvider.userAsAdmin != null) return 'Admin';
    if (authProvider.userAsEmployee != null) return 'Employee';
    if (authProvider.userAsClient != null) return 'Client';
    if (authProvider.userAsUser != null) return 'User';
    return 'Unknown';
  }

  // Get user role level (for permission comparison)
  static int getRoleLevel(AuthProvider authProvider) {
    if (authProvider.userAsAdmin != null) return 4; // Highest level
    if (authProvider.userAsEmployee != null) return 3;
    if (authProvider.userAsClient != null) return 2;
    if (authProvider.userAsUser != null) return 1;
    return 0; // Not authenticated
  }

  // Check if user can access admin panel
  static bool canAccessAdminPanel(AuthProvider authProvider) {
    return isAdmin(authProvider);
  }

  // Check if user can create customers
  static bool canCreateCustomer(AuthProvider authProvider) {
    return hasPermission(authProvider, 'create_customer');
  }

  // Check if user can add products
  static bool canAddProduct(AuthProvider authProvider) {
    return hasPermission(authProvider, 'add_product');
  }

  // Check if user can add categories
  static bool canAddCategory(AuthProvider authProvider) {
    return hasPermission(authProvider, 'add_category');
  }

  // Check if user can add brands
  static bool canAddBrand(AuthProvider authProvider) {
    return hasPermission(authProvider, 'add_brand');
  }

  // Check if user can manage suppliers
  static bool canManageSuppliers(AuthProvider authProvider) {
    return hasPermission(authProvider, 'manage_suppliers');
  }

  // Check if user can manage employees
  static bool canManageEmployees(AuthProvider authProvider) {
    return hasPermission(authProvider, 'manage_employees');
  }

  // Get available navigation items based on user role
  static List<Map<String, dynamic>> getAvailableNavigationItems(AuthProvider authProvider) {
    final items = [
      {
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home,
        'label': 'Dashboard',
        'route': '/',
        'available': true, // Everyone can access dashboard
      },
      {
        'icon': Icons.analytics_outlined,
        'activeIcon': Icons.analytics,
        'label': 'Reports',
        'route': '/reports',
        'available': true, // Everyone can access reports
      },
      {
        'icon': Icons.admin_panel_settings_outlined,
        'activeIcon': Icons.admin_panel_settings,
        'label': 'Admin',
        'route': '/admin',
        'available': canAccessAdminPanel(authProvider),
      },
      {
        'icon': Icons.settings_outlined,
        'activeIcon': Icons.settings,
        'label': 'Settings',
        'route': '/settings',
        'available': true, // Everyone can access settings
      },
    ];

    return items.where((item) => item['available'] == true).toList();
  }

  // Get available speed dial items based on user role
  static List<Map<String, dynamic>> getAvailableSpeedDialItems(AuthProvider authProvider) {
    final items = [
      {
        'icon': Icons.point_of_sale,
        'label': 'Sale',
        'color': Colors.green,
        'route': '/sales/add',
        'available': hasPermission(authProvider, 'create_sales'),
      },
      {
        'icon': Icons.person_add,
        'label': 'Customer',
        'color': Colors.blue,
        'route': '/customers/add',
        'available': canCreateCustomer(authProvider),
      },
      {
        'icon': Icons.inventory,
        'label': 'Product',
        'color': Colors.orange,
        'route': '/inventory/add',
        'available': canAddProduct(authProvider),
      },
    ];

    return items.where((item) => item['available'] == true).toList();
  }
}
