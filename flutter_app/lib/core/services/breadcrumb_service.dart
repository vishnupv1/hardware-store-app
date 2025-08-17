import 'package:flutter/material.dart';
import '../../shared/widgets/breadcrumb.dart';

class BreadcrumbService {
  static List<BreadcrumbItem> getBreadcrumbsForRoute(String route) {
    switch (route) {
      case '/':
        return [
          BreadcrumbItem(
            label: 'Dashboard',
            icon: Icons.dashboard,
          ),
        ];
      
      case '/admin':
        return [
          BreadcrumbItem(
            label: 'Admin Panel',
            icon: Icons.admin_panel_settings,
          ),
        ];
      
      case '/reports':
        return [
          BreadcrumbItem(
            label: 'Reports',
            icon: Icons.analytics,
          ),
        ];
      
      case '/inventory':
        return [
          BreadcrumbItem(
            label: 'Inventory',
            icon: Icons.inventory,
          ),
        ];
      case '/inventory/add':
        return [
          BreadcrumbItem(
            label: 'Inventory',
            route: '/inventory',
            icon: Icons.inventory,
          ),
          BreadcrumbItem(
            label: 'Add Product',
            icon: Icons.add,
          ),
        ];
      case '/inventory/brands':
        return [
          BreadcrumbItem(
            label: 'Inventory',
            route: '/inventory',
            icon: Icons.inventory,
          ),
          BreadcrumbItem(
            label: 'Brand Management',
            icon: Icons.branding_watermark,
          ),
        ];
      
      case '/sales':
        return [
          BreadcrumbItem(
            label: 'Sales',
            icon: Icons.point_of_sale,
          ),
        ];
      
      case '/customers':
        return [
          BreadcrumbItem(
            label: 'Customers',
            icon: Icons.people,
          ),
        ];
      
      case '/brands':
        return [
          BreadcrumbItem(
            label: 'Brands',
            icon: Icons.branding_watermark,
          ),
        ];
      
      case '/profile':
        return [
          BreadcrumbItem(
            label: 'Profile',
            icon: Icons.person,
          ),
        ];
      
      case '/settings':
        return [
          BreadcrumbItem(
            label: 'Settings',
            icon: Icons.settings,
          ),
        ];
      
      case '/login':
        return [
          BreadcrumbItem(
            label: 'Login',
            icon: Icons.login,
          ),
        ];
      
      case '/signup':
        return [
          BreadcrumbItem(
            label: 'Sign Up',
            icon: Icons.person_add,
          ),
        ];
      
      case '/landing':
        return [
          BreadcrumbItem(
            label: 'Welcome',
            icon: Icons.home,
          ),
        ];
      
      default:
        // Handle nested routes or dynamic routes
        if (route.startsWith('/inventory/')) {
          return [
            BreadcrumbItem(
              label: 'Inventory',
              route: '/inventory',
              icon: Icons.inventory,
            ),
            BreadcrumbItem(
              label: 'Product Details',
              icon: Icons.info,
            ),
          ];
        }
        
        if (route.startsWith('/sales/')) {
          return [
            BreadcrumbItem(
              label: 'Sales',
              route: '/sales',
              icon: Icons.point_of_sale,
            ),
            BreadcrumbItem(
              label: 'Transaction Details',
              icon: Icons.receipt,
            ),
          ];
        }
        
        if (route == '/customers/add') {
          return [
            BreadcrumbItem(
              label: 'Customers',
              route: '/customers',
              icon: Icons.people,
            ),
            BreadcrumbItem(
              label: 'Add Customer',
              icon: Icons.person_add,
            ),
          ];
        }
        

        
        if (route.startsWith('/customers/')) {
          return [
            BreadcrumbItem(
              label: 'Customers',
              route: '/customers',
              icon: Icons.people,
            ),
            BreadcrumbItem(
              label: 'Customer Details',
              icon: Icons.person,
            ),
          ];
        }
        
        return [
          BreadcrumbItem(
            label: 'Page',
            icon: Icons.pageview,
          ),
        ];
    }
  }
}
