import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../core/services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _refreshAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Dashboard data
  Map<String, dynamic>? _customerStats;
  Map<String, dynamic>? _productStats;
  Map<String, dynamic>? _salesStats;
  Map<String, dynamic>? _recentActivity;
  bool _isLoading = true;
  
  // Speed dial state
  bool _isSpeedDialOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Load all dashboard stats in a single API call
      final dashboardResponse = await apiService.getDashboardStats();

      if (dashboardResponse['success'] == false) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final dashboardData = dashboardResponse['data'];
      
      setState(() {
        _customerStats = dashboardData['customerStats'] ?? {};
        _productStats = dashboardData['productStats'] ?? {};
        _salesStats = dashboardData['salesStats'] ?? {};
        _recentActivity = dashboardData['recentActivity'] ?? {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshDashboardData() async {
    // Start the refresh animation
    _refreshAnimationController.repeat();
    
    await _loadDashboardData();
    
    // Stop the refresh animation
    _refreshAnimationController.stop();
    _refreshAnimationController.reset();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral900 : AppColors.background,
      floatingActionButton: _buildSpeedDial(),
      body: RefreshIndicator(
        onRefresh: _refreshDashboardData,
        color: AppColors.primary500,
        backgroundColor: isDark ? AppColors.neutral800 : AppColors.background,
        strokeWidth: 3.0,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeSection(theme),
                        const SizedBox(height: 24),
                        _buildDashboardCards(theme),
                        const SizedBox(height: 24),
                        _buildRecentActivitySection(theme),
                        const SizedBox(height: 24),
                        _buildQuickActionsSection(theme),
                        const SizedBox(height: 24),
                        _buildFeatureShowcaseSection(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }





  Widget _buildWelcomeSection(ThemeData theme) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.infoGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 36, 175, 255).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'User',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user?.role == 'client' ? 'Client' : 'User',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Manage your hardware store efficiently today!',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildDashboardCards(ThemeData theme) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading dashboard data...'),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Dashboard Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _refreshDashboardData,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _refreshAnimationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _refreshAnimationController.value * 2 * 3.14159,
                          child: Icon(
                            Icons.refresh,
                            color: AppColors.success500,
                            size: 16,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Refresh',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.success500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                'Total Customers',
                _customerStats?['totalCustomers']?.toString() ?? '0',
                'Active: ${_customerStats?['activeCustomers']?.toString() ?? '0'}',
                Icons.people,
                AppColors.primary500,
                AppColors.primaryGradient,
                () => context.go('/customers'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                theme,
                'Active Products',
                _productStats?['activeProducts']?.toString() ?? '0',
                'Stock: ${_productStats?['totalStockQuantity']?.toString() ?? '0'}',
                Icons.inventory,
                AppColors.success500,
                AppColors.successGradient,
                () => context.go('/inventory'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                'Total Sales',
                _salesStats?['totalSales']?.toString() ?? '0',
                'Avg: ₹${_salesStats?['averageOrderValue']?.toStringAsFixed(0) ?? '0'}',
                Icons.point_of_sale,
                AppColors.warning500,
                AppColors.warningGradient,
                () => context.go('/sales'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                theme,
                'Revenue',
                '₹${_salesStats?['totalRevenue']?.toStringAsFixed(0) ?? '0'}',
                'Items: ${_salesStats?['totalItems']?.toString() ?? '0'}',
                Icons.trending_up,
                AppColors.secondary500,
                AppColors.secondaryGradient,
                () => context.go('/reports'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAlertCards(theme),
      ],
    );
  }

  Widget _buildAlertCards(ThemeData theme) {
    final lowStockCount = _productStats?['lowStockProducts'] ?? 0;
    final outOfStockCount = _productStats?['outOfStockProducts'] ?? 0;
    final customersOverLimit = _customerStats?['customersOverLimit'] ?? 0;

    return Column(
      children: [
        if (lowStockCount > 0 || outOfStockCount > 0 || customersOverLimit > 0) ...[
          Text(
            'Alerts',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (lowStockCount > 0)
          _buildAlertCard(
            theme,
            'Low Stock Alert',
            '$lowStockCount products need restocking',
            Icons.warning,
            AppColors.warning500,
            () => context.go('/inventory'),
          ),
        if (outOfStockCount > 0) ...[
          const SizedBox(height: 8),
          _buildAlertCard(
            theme,
            'Out of Stock',
            '$outOfStockCount products are out of stock',
            Icons.error,
            AppColors.error500,
            () => context.go('/inventory'),
          ),
        ],
        if (customersOverLimit > 0) ...[
          const SizedBox(height: 8),
          _buildAlertCard(
            theme,
            'Credit Limit Exceeded',
            '$customersOverLimit customers over credit limit',
            Icons.account_balance_wallet,
            AppColors.error500,
            () => context.go('/customers'),
          ),
        ],
      ],
    );
  }

  Widget _buildAlertCard(
    ThemeData theme,
    String title,
    String message,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    LinearGradient gradient,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildQuickActionsAccordion(theme),
      ],
    );
  }

  Widget _buildQuickActionsAccordion(ThemeData theme) {
    return Column(
      children: [
        _buildAccordionItem(
          theme,
          'Sales Management',
          Icons.point_of_sale,
          AppColors.primary500,
          [
            _buildAccordionAction(
              theme,
              'New Sale',
              Icons.add_shopping_cart,
              'Create a new sales transaction',
              () => context.go('/sales'),
            ),
            _buildAccordionAction(
              theme,
              'View Sales',
              Icons.receipt_long,
              'View all sales history',
              () => context.go('/sales'),
            ),
            _buildAccordionAction(
              theme,
              'Sales Reports',
              Icons.analytics,
              'Generate sales reports',
              () => context.go('/reports'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildAccordionItem(
          theme,
          'Inventory Management',
          Icons.inventory,
          AppColors.success500,
          [
            _buildAccordionAction(
              theme,
              'Add Product',
              Icons.add_box,
              'Add new product to inventory',
              () => context.go('/inventory/add'),
            ),
            _buildAccordionAction(
              theme,
              'View Products',
              Icons.inventory_2,
              'Browse all products',
              () => context.go('/inventory'),
            ),
            _buildAccordionAction(
              theme,
              'Manage Brands',
              Icons.branding_watermark,
              'Add or edit product brands',
              () => context.go('/brands'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildAccordionItem(
          theme,
          'Customer Management',
          Icons.people,
          AppColors.warning500,
          [
            _buildAccordionAction(
              theme,
              'Add Customer',
              Icons.person_add,
              'Register new customer',
              () => context.go('/customers/add'),
            ),
            _buildAccordionAction(
              theme,
              'View Customers',
              Icons.people_outline,
              'Browse customer database',
              () => context.go('/customers'),
            ),
            _buildAccordionAction(
              theme,
              'Customer Reports',
              Icons.assessment,
              'View customer analytics',
              () => context.go('/reports'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildAccordionItem(
          theme,
          'System & Reports',
          Icons.settings,
          AppColors.info500,
          [
            _buildAccordionAction(
              theme,
              'Analytics Dashboard',
              Icons.dashboard,
              'View business analytics',
              () => context.go('/reports'),
            ),
            _buildAccordionAction(
              theme,
              'System Settings',
              Icons.settings,
              'Configure system preferences',
              () => context.go('/settings'),
            ),
            _buildAccordionAction(
              theme,
              'Admin Panel',
              Icons.admin_panel_settings,
              'Access admin functions',
              () => context.go('/admin'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccordionItem(
    ThemeData theme,
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return ExpansionTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      collapsedBackgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.02),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildAccordionAction(
    ThemeData theme,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primary500,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: theme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }





  Widget _buildFeatureShowcaseSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Store Management',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.secondaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary500.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Complete Management',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Manage inventory, track sales, handle customers, and generate reports for your hardware wholesale business.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'View Reports',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reports feature coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: AppButtonStyle.primary,
                size: AppButtonSize.medium,
                backgroundColor: Colors.white,
                textColor: AppColors.secondary700,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDial() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Speed dial items
        if (_isSpeedDialOpen) ...[
          _buildSpeedDialItem(
            icon: Icons.point_of_sale,
            label: 'Sale',
            color: AppColors.success500,
            onTap: () => context.go('/sales/add'),
          ),
          const SizedBox(height: 16),
          _buildSpeedDialItem(
            icon: Icons.person_add,
            label: 'Customer',
            color: AppColors.primary500,
            onTap: () => context.go('/customers/add'),
          ),
          const SizedBox(height: 16),
          _buildSpeedDialItem(
            icon: Icons.inventory,
            label: 'Product',
            color: AppColors.warning500,
            onTap: () => context.go('/inventory/add'),
          ),
          const SizedBox(height: 16),
        ],
        // Main FAB button
        FloatingActionButton(
          onPressed: () {
            setState(() {
              _isSpeedDialOpen = !_isSpeedDialOpen;
            });
          },
          backgroundColor: AppColors.primary500,
          child: AnimatedRotation(
            turns: _isSpeedDialOpen ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _isSpeedDialOpen ? Icons.close : Icons.add,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDialItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      preferBelow: false,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(ThemeData theme) {
    if (_recentActivity == null) {
      return const SizedBox.shrink();
    }

    final recentSales = _recentActivity!['recentSales'] as List? ?? [];
    final recentCustomers = _recentActivity!['recentCustomers'] as List? ?? [];
    final lowStockProducts = _recentActivity!['lowStockProducts'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Recent Sales
        if (recentSales.isNotEmpty) ...[
          _buildActivityCard(
            theme,
            'Recent Sales',
            Icons.point_of_sale,
            AppColors.success500,
            recentSales.map((sale) => {
              'title': sale['invoiceNumber'] ?? 'N/A',
              'subtitle': '${sale['customerName'] ?? 'N/A'} - ₹${sale['totalAmount']?.toStringAsFixed(0) ?? '0'}',
              'status': sale['saleStatus'] ?? 'completed',
            }).toList(),
            () => context.go('/sales'),
          ),
          const SizedBox(height: 12),
        ],

        // Recent Customers
        if (recentCustomers.isNotEmpty) ...[
          _buildActivityCard(
            theme,
            'Recent Customers',
            Icons.people,
            AppColors.primary500,
            recentCustomers.map((customer) => {
              'title': customer['name'] ?? 'N/A',
              'subtitle': '${customer['email'] ?? 'N/A'} - ${customer['customerType'] ?? 'N/A'}',
              'status': 'active',
            }).toList(),
            () => context.go('/customers'),
          ),
          const SizedBox(height: 12),
        ],

        // Low Stock Products
        if (lowStockProducts.isNotEmpty) ...[
          _buildActivityCard(
            theme,
            'Low Stock Alerts',
            Icons.warning,
            AppColors.warning500,
            lowStockProducts.map((product) => {
              'title': product['name'] ?? 'N/A',
              'subtitle': 'Stock: ${product['stockQuantity'] ?? 0} (Min: ${product['minStockLevel'] ?? 0})',
              'status': 'warning',
            }).toList(),
            () => context.go('/inventory'),
          ),
        ],
      ],
    );
  }

  Widget _buildActivityCard(
    ThemeData theme,
    String title,
    IconData icon,
    Color color,
    List<Map<String, dynamic>> items,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...items.take(3).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            item['subtitle'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(item['status']).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item['status'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(item['status']),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success500;
      case 'pending':
        return AppColors.warning500;
      case 'cancelled':
        return AppColors.error500;
      case 'active':
        return AppColors.success500;
      case 'warning':
        return AppColors.warning500;
      default:
        return AppColors.neutral500;
    }
  }
}

