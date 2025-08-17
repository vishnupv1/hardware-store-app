import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/widgets/breadcrumb.dart';
import '../../../../core/services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  String _selectedLoginType = 'admin'; // Default to admin login

  @override
  void initState() {
    super.initState();
    // Get user type from URL parameters if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      final userType = uri.queryParameters['type'];
      if (userType != null && ['admin', 'employee', 'vendor'].contains(userType)) {
        setState(() {
          _selectedLoginType = userType;
        });
      }
    });
    
    // For testing purposes, pre-fill admin credentials
    _emailController.text = 'admin@email.com';
    _passwordController.text = 'Vis@123456';
  }

  List<BreadcrumbItem> _getBreadcrumbs() {
    // Check if we came from landing page (has user type parameter)
    final uri = GoRouterState.of(context).uri;
    final userType = uri.queryParameters['type'];
    
    if (userType != null) {
      // Came from landing page, show landing -> login breadcrumb
      return [
        BreadcrumbItem(
          label: 'Welcome',
          route: '/landing',
          icon: Icons.home,
        ),
        BreadcrumbItem(
          label: 'Login',
          icon: Icons.login,
        ),
      ];
    } else {
      // Direct access to login, show only login
      return [
        BreadcrumbItem(
          label: 'Login',
          icon: Icons.login,
        ),
      ];
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = false;
    
    switch (_selectedLoginType) {
      case 'admin':
        success = await authProvider.loginAdmin(
          _emailController.text.trim(),
          _passwordController.text,
        );
        break;
      case 'employee':
        success = await authProvider.loginEmployee(
          _emailController.text.trim(),
          _passwordController.text,
        );
        break;
      case 'vendor':
        success = await authProvider.loginVendor(
          _emailController.text.trim(),
          _passwordController.text,
        );
        break;
      default:
        success = await authProvider.loginClient(
          _emailController.text.trim(),
          _passwordController.text,
        );
    }
    
    if (success && mounted) {
      context.go('/');
    } else if (mounted) {
      // Show error message with more details
      final errorMessage = authProvider.errorMessage ?? 'Login failed';
      
      // Check if it's a rate limiting error
      final isRateLimitError = errorMessage.toLowerCase().contains('too many') || 
                              errorMessage.toLowerCase().contains('rate limit') ||
                              errorMessage.toLowerCase().contains('authentication attempts');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRateLimitError ? 'Rate Limit Exceeded' : 'Login Failed',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(errorMessage),
              if (isRateLimitError) ...[
                const SizedBox(height: 8),
                const Text(
                  'Please wait a few minutes before trying again.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
          backgroundColor: isRateLimitError ? Colors.orange : Colors.red,
          duration: Duration(seconds: isRateLimitError ? 8 : 5),
          action: SnackBarAction(
            label: 'Details',
            textColor: Colors.white,
            onPressed: () {
              // Show detailed error dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(isRateLimitError ? 'Rate Limit Error' : 'Login Error Details'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(errorMessage),
                      if (isRateLimitError) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'This happens when there are too many failed login attempts. To resolve this:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('• Wait 5-10 minutes before trying again'),
                        const Text('• Make sure you\'re using the correct credentials'),
                        const Text('• Check your internet connection'),
                        const Text('• Contact support if the issue persists'),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }
  }

  void _testConnection() async {
    try {
      final isConnected = await apiService.testConnection();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isConnected 
                ? '✅ Connection successful!' 
                : '❌ Connection failed. Check console for details.'
            ),
            backgroundColor: isConnected ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Connection test failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient and patterns
          _buildBackground(isDark),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Breadcrumb navigation with custom styling for login page
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: _getBreadcrumbs().asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isLast = index == _getBreadcrumbs().length - 1;

                      return Row(
                        children: [
                          if (index > 0) ...[
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 8),
                          ],
                          GestureDetector(
                            onTap: isLast || item.route == null
                                ? null
                                : () => context.go(item.route!),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (item.icon != null) ...[
                                  Icon(
                                    item.icon,
                                    size: 16,
                                    color: isLast
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  item.label,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isLast
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.7),
                                    fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          _buildHeader(theme),
                          const SizedBox(height: 40),
                          _buildLoginForm(theme),
                          const SizedBox(height: 24),
                          _buildRememberMeSection(theme),
                          const SizedBox(height: 24),
                          _buildLoginButton(),
                          const SizedBox(height: 12),
                          _buildTestConnectionButton(),
                          const SizedBox(height: 24),
                          _buildDivider(theme),
                          const SizedBox(height: 24),
                          _buildSocialLoginSection(theme),
                          const SizedBox(height: 32),
                          _buildSignUpSection(theme),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [
                const Color(0xFF0F0F23),
                const Color(0xFF1A1A2E),
                const Color(0xFF16213E),
              ]
            : [
                const Color(0xFF667eea),
                const Color(0xFF764ba2),
                const Color(0xFFf093fb),
              ],
        ),
      ),
      child: Stack(
        children: [
          // Floating geometric shapes
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: 10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Grid pattern overlay
          Positioned.fill(
            child: CustomPaint(
              painter: LoginGridPainter(isDark: isDark),
            ),
          ),
          // Animated floating particles
          ...List.generate(6, (index) => _buildFloatingParticle(index, isDark)),
        ],
      ),
    );
  }

  Widget _buildFloatingParticle(int index, bool isDark) {
    return Positioned(
      left: (index * 60.0) % 350,
      top: (index * 80.0) % 700,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(seconds: 4 + index),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 15 * (value - 0.5)),
            child: Container(
              width: 3 + (index % 2) * 2,
              height: 3 + (index % 2) * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1 + (index % 2) * 0.05),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              gradient: AppColors.primaryGradient,
            ),
            child: const Icon(
              Icons.lock_outline,
              color: Colors.white,
              size: 50,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Welcome Back',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 16,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.2),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }



  Widget _buildLoginForm(ThemeData theme) {
    return Column(
      children: [
        AppTextField(
          label: 'Email Address',
          hint: 'Enter your email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          prefixIcon: Icon(
            Icons.email_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          validator: Validators.validateEmail,
          style: AppTextFieldStyle.outlined,
          size: AppTextFieldSize.large,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Password',
          hint: 'Enter your password',
          controller: _passwordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          prefixIcon: Icon(
            Icons.lock_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          validator: Validators.validatePassword,
          style: AppTextFieldStyle.outlined,
          size: AppTextFieldSize.large,
        ),
      ],
    );
  }

  Widget _buildRememberMeSection(ThemeData theme) {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value ?? false;
            });
          },
          activeColor: AppColors.primary500,
        ),
        Text(
          'Remember me',
          style: theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            // Handle forgot password
          },
          child: Text(
            'Forgot Password?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.primary500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return AppButton(
          text: 'Sign In',
          onPressed: _handleLogin,
          isLoading: authProvider.isLoading,
          style: AppButtonStyle.primary,
          size: AppButtonSize.large,
          icon: Icons.login,
        );
      },
    );
  }

  Widget _buildTestConnectionButton() {
    return AppButton(
      text: 'Test Connection',
      onPressed: _testConnection,
      style: AppButtonStyle.secondary,
      size: AppButtonSize.medium,
      icon: Icons.wifi,
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            'or continue with',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLoginSection(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            theme,
            'Google',
            Icons.g_mobiledata,
            AppColors.error500,
            () {
              // Handle Google login
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            theme,
            'Apple',
            Icons.apple,
            Colors.black,
            () {
              // Handle Apple login
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    ThemeData theme,
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 15,
            ),
          ),
          TextButton(
            onPressed: () {
              context.go('/signup');
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Sign Up',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginGridPainter extends CustomPainter {
  final bool isDark;

  LoginGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.02 : 0.03)
      ..strokeWidth = 0.5;

    final spacing = 60.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
