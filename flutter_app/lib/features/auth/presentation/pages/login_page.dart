import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/widgets/breadcrumb.dart';
import '../../../../core/services/breadcrumb_service.dart';

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
  bool _isClientLogin = true; // Default to client login for business data access

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
    
    final success = _isClientLogin 
        ? await authProvider.loginClient(
            _emailController.text.trim(),
            _passwordController.text,
          )
        : await authProvider.loginUser(
            _emailController.text.trim(),
            _passwordController.text,
          );

    if (success && mounted) {
      context.go('/');
    } else if (mounted) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral900 : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Breadcrumb navigation
            Breadcrumb(
              items: BreadcrumbService.getBreadcrumbsForRoute('/login'),
              showHome: false,
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
                      _buildLoginTypeToggle(theme),
                      const SizedBox(height: 24),
                      _buildLoginForm(theme),
                      const SizedBox(height: 24),
                      _buildRememberMeSection(theme),
                      const SizedBox(height: 24),
                      _buildLoginButton(),
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
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary500.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_outline,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome Back',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to your account to continue',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginTypeToggle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isClientLogin = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _isClientLogin 
                      ? AppColors.primary500 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Business Owner',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _isClientLogin 
                        ? Colors.white 
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: _isClientLogin 
                        ? FontWeight.w600 
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isClientLogin = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: !_isClientLogin 
                      ? AppColors.primary500 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Employee',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: !_isClientLogin 
                        ? Colors.white 
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: !_isClientLogin 
                        ? FontWeight.w600 
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildDivider(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
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
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpSection(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () {
            context.go('/signup');
          },
          child: Text(
            'Sign Up',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.primary500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
