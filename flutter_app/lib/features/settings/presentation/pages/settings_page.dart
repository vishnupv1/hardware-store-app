import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/providers/auth_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral900 : AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
              child: Column(
                children: [
                  _buildThemeSection(theme),
                  const SizedBox(height: 24),
                  _buildPreferencesSection(theme),
                  const SizedBox(height: 24),
                  _buildSecuritySection(theme),
                  const SizedBox(height: 24),
                  _buildSupportSection(theme),
                  const SizedBox(height: 24),
                  _buildAboutSection(theme),
                  const SizedBox(height: 32),
                  _buildLogoutButton(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildThemeSection(ThemeData theme) {
    return _buildSectionCard(
      theme,
      'Appearance',
      [
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return _buildSwitchTile(
              theme,
              'Dark Mode',
              'Use dark theme',
              Icons.dark_mode_outlined,
              themeProvider.isDarkMode,
              (value) {
                themeProvider.toggleDarkMode();
              },
            );
          },
        ),
        _buildListTile(
          theme,
          'Language',
          _selectedLanguage,
          Icons.language_outlined,
          () {
            _showLanguageDialog(theme);
          },
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(ThemeData theme) {
    return _buildSectionCard(
      theme,
      'Preferences',
      [
        _buildSwitchTile(
          theme,
          'Notifications',
          'Receive push notifications',
          Icons.notifications_outlined,
          _notificationsEnabled,
          (value) {
            setState(() {
              _notificationsEnabled = value;
            });
          },
        ),
        _buildListTile(
          theme,
          'Sound & Vibration',
          'Customize notification sounds',
          Icons.volume_up_outlined,
          () {
            // Handle sound settings
          },
        ),
        _buildListTile(
          theme,
          'Data Usage',
          'Manage app data usage',
          Icons.data_usage_outlined,
          () {
            // Handle data usage settings
          },
        ),
      ],
    );
  }

  Widget _buildSecuritySection(ThemeData theme) {
    return _buildSectionCard(
      theme,
      'Security',
      [
        _buildSwitchTile(
          theme,
          'Biometric Login',
          'Use fingerprint or face ID',
          Icons.fingerprint_outlined,
          _biometricEnabled,
          (value) {
            setState(() {
              _biometricEnabled = value;
            });
          },
        ),
        _buildListTile(
          theme,
          'Change Password',
          'Update your password',
          Icons.lock_outlined,
          () {
            // Handle password change
          },
        ),
        _buildListTile(
          theme,
          'Two-Factor Authentication',
          'Add extra security',
          Icons.security_outlined,
          () {
            // Handle 2FA settings
          },
        ),
      ],
    );
  }

  Widget _buildSupportSection(ThemeData theme) {
    return _buildSectionCard(
      theme,
      'Support',
      [
        _buildListTile(
          theme,
          'Help Center',
          'Get help and support',
          Icons.help_outline,
          () {
            // Handle help center
          },
        ),
        _buildListTile(
          theme,
          'Contact Us',
          'Reach out to our team',
          Icons.contact_support_outlined,
          () {
            // Handle contact us
          },
        ),
        _buildListTile(
          theme,
          'Privacy Policy',
          'Read our privacy policy',
          Icons.privacy_tip_outlined,
          () {
            // Handle privacy policy
          },
        ),
        _buildListTile(
          theme,
          'Terms of Service',
          'Read our terms of service',
          Icons.description_outlined,
          () {
            // Handle terms of service
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection(ThemeData theme) {
    return _buildSectionCard(
      theme,
      'About',
      [
        _buildListTile(
          theme,
          'App Version',
          '1.0.0',
          Icons.info_outline,
          null,
        ),
        _buildListTile(
          theme,
          'Build Number',
          '1',
          Icons.build_outlined,
          null,
        ),
        _buildListTile(
          theme,
          'Rate App',
          'Rate us on the app store',
          Icons.star_outline,
          () {
            // Handle rate app
          },
        ),
        _buildListTile(
          theme,
          'Share App',
          'Share with friends',
          Icons.share_outlined,
          () {
            // Handle share app
          },
        ),
      ],
    );
  }

  Widget _buildSectionCard(ThemeData theme, String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary500,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary500,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
  ) {
    Widget content = Padding(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }

  Widget _buildLogoutButton(ThemeData theme) {
    return AppButton(
      text: 'Logout',
      onPressed: () {
        _showLogoutDialog(theme);
      },
      style: AppButtonStyle.danger,
      size: AppButtonSize.large,
      icon: Icons.logout,
    );
  }

  void _showLanguageDialog(ThemeData theme) {
    String tempSelectedLanguage = _selectedLanguage;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Select Language',
            style: theme.textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                theme,
                'English',
                tempSelectedLanguage,
                (value) => setDialogState(() => tempSelectedLanguage = value),
              ),
              _buildLanguageOption(
                theme,
                'Spanish',
                tempSelectedLanguage,
                (value) => setDialogState(() => tempSelectedLanguage = value),
              ),
              _buildLanguageOption(
                theme,
                'French',
                tempSelectedLanguage,
                (value) => setDialogState(() => tempSelectedLanguage = value),
              ),
              _buildLanguageOption(
                theme,
                'German',
                tempSelectedLanguage,
                (value) => setDialogState(() => tempSelectedLanguage = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedLanguage = tempSelectedLanguage;
                });
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    ThemeData theme,
    String language,
    String selectedLanguage,
    ValueChanged<String> onChanged,
  ) {
    final isSelected = selectedLanguage == language;
    
    return GestureDetector(
      onTap: () => onChanged(language),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
            ? AppColors.primary500.withValues(alpha: 0.1)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary500 : theme.colorScheme.onSurfaceVariant,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary500 : Colors.transparent,
              ),
              child: isSelected
                ? Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  )
                : null,
            ),
            const SizedBox(width: 16),
            Text(
              language,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary500 : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: theme.textTheme.titleLarge,
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return AppButton(
                text: authProvider.isLoading ? 'Logging out...' : 'Logout',
                onPressed: authProvider.isLoading ? null : () async {
                  Navigator.of(context).pop();
                  await authProvider.logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                style: AppButtonStyle.danger,
                size: AppButtonSize.small,
              );
            },
          ),
        ],
      ),
    );
  }
}
