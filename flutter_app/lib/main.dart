import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/theme_provider.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/signup_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/inventory/presentation/pages/inventory_page.dart';
import 'features/inventory/presentation/widgets/add_product_dialog.dart';
import 'features/inventory/presentation/pages/product_details_page.dart';
import 'features/inventory/presentation/pages/brand_management_page.dart';
import 'features/sales/presentation/pages/sales_page.dart';
import 'features/customers/presentation/pages/customers_page.dart';
import 'features/customers/presentation/pages/add_customer_page.dart';
import 'features/customers/presentation/pages/customer_details_page.dart';

import 'features/admin/presentation/pages/admin_page.dart';
import 'features/reports/presentation/pages/reports_page.dart';
import 'shared/widgets/breadcrumb.dart';
import 'core/services/breadcrumb_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

// GoRouter configuration
final _router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;
    final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

    // If not authenticated and not on login/signup page, redirect to login
    if (!isAuthenticated && !isLoggingIn) {
      return '/login';
    }

    // If authenticated and on login/signup page, redirect to home
    if (isAuthenticated && isLoggingIn) {
      return '/';
    }

    // No redirect needed
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const SignupPage(),
    ),


    ShellRoute(
      builder: (context, state, child) {
        return ScaffoldWithNavigation(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/inventory',
          name: 'inventory',
          builder: (context, state) => const InventoryPage(),
        ),
        GoRoute(
          path: '/inventory/add',
          name: 'add-product',
          builder: (context, state) => const AddProductPage(),
        ),
        GoRoute(
          path: '/inventory/:id',
          name: 'product-details',
          builder: (context, state) {
            final productId = state.pathParameters['id']!;
            return ProductDetailsPage(productId: productId);
          },
        ),
        GoRoute(
          path: '/inventory/brands',
          name: 'brand-management',
          builder: (context, state) => const BrandManagementPage(),
        ),
        GoRoute(
          path: '/sales',
          name: 'sales',
          builder: (context, state) => const SalesPage(),
        ),
        GoRoute(
          path: '/customers',
          name: 'customers',
          builder: (context, state) => const CustomersPage(),
        ),
        GoRoute(
          path: '/customers/add',
          name: 'add-customer',
          builder: (context, state) => const AddCustomerPage(),
        ),
        GoRoute(
          path: '/customers/:id',
          name: 'customer-details',
          builder: (context, state) => CustomerDetailsPage(
            customerId: state.pathParameters['id']!,
          ),
        ),

        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/admin',
          name: 'admin',
          builder: (context, state) => const AdminPage(),
        ),
        GoRoute(
          path: '/reports',
          name: 'reports',
          builder: (context, state) => const ReportsPage(),
        ),
      ],
    ),
  ],
);



class ScaffoldWithNavigation extends StatefulWidget {
  final Widget child;

  const ScaffoldWithNavigation({
    super.key,
    required this.child,
  });

  @override
  State<ScaffoldWithNavigation> createState() => _ScaffoldWithNavigationState();
}

class _ScaffoldWithNavigationState extends State<ScaffoldWithNavigation> {
  int _currentIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Dashboard',
      route: '/',
    ),
    // NavigationItem(
    //   icon: Icons.inventory_2_outlined,
    //   activeIcon: Icons.inventory_2,
    //   label: 'Inventory',
    //   route: '/inventory',
    // ),
    NavigationItem(
      icon: Icons.people_outlined,
      activeIcon: Icons.people,
      label: 'Customers',
      route: '/customers',
    ),
    NavigationItem(
      icon: Icons.admin_panel_settings_outlined,
      activeIcon: Icons.admin_panel_settings,
      label: 'Admin',
      route: '/admin',
    ),
    NavigationItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Reports',
      route: '/reports',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize current index based on initial route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final location = GoRouterState.of(context).uri.path;
      // Handle nested routes by finding the parent route
      String parentRoute = location;
      if (location.startsWith('/customers/')) {
        parentRoute = '/customers';
      } else if (location.startsWith('/sales/')) {
        parentRoute = '/sales';
      }
      
      final index = _navigationItems.indexWhere((item) => item.route == parentRoute);
      if (index != -1 && index != _currentIndex) {
        setState(() {
          _currentIndex = index;
        });
      }
    });
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final location = GoRouterState.of(context).uri.path;
    
    // Don't show AppBar for pages with custom headers
    if (location == '/customers' || location == '/inventory' || location == '/customers/add' || location == '/inventory/add') {
      return null;
    }
    
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      elevation: 0,
      leading: location == '/' 
          ? Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.user;
                return GestureDetector(
                  onTap: () {
                    context.go('/profile');
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary500,
                          AppColors.primary700,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary500.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                );
              },
            )
          : null, // Other pages will handle their own leading widget
      title: location == '/customers' || location == '/inventory'
          ? null // Don't show title for pages with custom headers
          : Text(
              _getPageTitle(location),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
      actions: [
        if (location == '/') ...[
          // Show notification and search only on home screen
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () {
              // Handle notifications
            },
          ),
          IconButton(
            icon: Icon(
              Icons.search,
              color: isDark ? Colors.black87 : Colors.black87,
            ),
            onPressed: () {
              // Handle search
            },
          ),
        ] else if (location == '/profile') ...[
          // Show logout only on profile page
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return IconButton(
                icon: Icon(
                  Icons.logout,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              );
            },
          ),
        ],
        // Other pages will have their own actions defined in their respective pages
      ],
    );
  }

  String _getPageTitle(String location) {
    // Handle dynamic customer details route
    if (location.startsWith('/customers/') && location != '/customers/add') {
      return 'Customer Details';
    }
    
    switch (location) {
      case '/':
        return 'Dashboard';
      case '/admin':
        return 'Admin Panel';
      case '/reports':
        return 'Reports';
      case '/inventory':
        return 'Inventory';
      case '/inventory/add':
        return 'Add Product';
      case '/inventory/brands':
        return 'Brand Management';
      case '/sales':
        return 'Sales';
      case '/customers':
        return 'Customers';
      case '/customers/add':
        return 'Add Customer';
      case '/settings':
        return 'Settings';
      case '/profile':
        return 'Profile';
      default:
        return 'Hardware Store';
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    // Handle nested routes by finding the parent route
    String parentRoute = location;
    if (location.startsWith('/customers/')) {
      parentRoute = '/customers';
    } else if (location.startsWith('/sales/')) {
      parentRoute = '/sales';
    }
    
    final newIndex = _navigationItems.indexWhere((item) => item.route == parentRoute);
    
    // Update current index if it changed
    if (newIndex != -1 && newIndex != _currentIndex) {
      _currentIndex = newIndex;
    }

    // Get breadcrumbs for current route
    final breadcrumbs = BreadcrumbService.getBreadcrumbsForRoute(location);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Breadcrumb navigation (hide for pages with custom headers)
          if (location != '/customers' && location != '/inventory' && location != '/customers/add' && location != '/inventory/add')
            Breadcrumb(
              items: breadcrumbs,
              showHome: location != '/',
            ),
          // Main content
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: Container(
        key: const ValueKey('bottom_navigation'),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _navigationItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = index == _currentIndex;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentIndex = index;
                      });
                      context.go(item.route);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected 
                                ? Colors.blue
                                : Colors.grey.shade600,
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected 
                                  ? Colors.blue
                                  : Colors.grey.shade600,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    this.label = '',
    required this.route,
  });
}
