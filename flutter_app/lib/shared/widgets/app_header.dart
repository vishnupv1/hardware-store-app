import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final double expandedHeight;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const AppHeader({
    super.key,
    required this.title,
    this.actions,
    this.expandedHeight = 60,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary600,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 8),
        centerTitle: false,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary500,
                AppColors.primary700,
                AppColors.primary800,
              ],
            ),
          ),
        ),
      ),
      actions: actions,
    );
  }
}
