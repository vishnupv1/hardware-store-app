import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../core/utils/validators.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateUserProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty 
          ? null 
          : _phoneController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
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
      backgroundColor: isDark ? AppColors.neutral900 : AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Picture Section
              _buildProfilePictureSection(theme),
              const SizedBox(height: 32),
              
              // Form Fields
              _buildFormFields(theme),
              const SizedBox(height: 32),
              
              // Save Button
              AppButton(
                text: _isLoading ? 'Saving...' : 'Save Changes',
                onPressed: _isLoading ? null : _saveProfile,
                style: AppButtonStyle.primary,
                size: AppButtonSize.large,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary500.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image picker coming soon!'),
                ),
              );
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Change Photo'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(ThemeData theme) {
    return Column(
      children: [
        AppTextField(
          controller: _firstNameController,
          label: 'First Name',
          hint: 'Enter your first name',
          prefixIcon: Icon(Icons.person_outline),
          validator: Validators.validateName,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _lastNameController,
          label: 'Last Name',
          hint: 'Enter your last name',
          prefixIcon: Icon(Icons.person_outline),
          validator: Validators.validateName,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Enter your email',
          prefixIcon: Icon(Icons.email_outlined),
          keyboardType: TextInputType.emailAddress,
          enabled: false, // Email cannot be changed
          helperText: 'Email cannot be changed',
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _phoneController,
          label: 'Phone Number (Optional)',
          hint: 'Enter your phone number',
          prefixIcon: Icon(Icons.phone_outlined),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              return Validators.validatePhone(value);
            }
            return null;
          },
          enabled: !_isLoading,
        ),
      ],
    );
  }
}
