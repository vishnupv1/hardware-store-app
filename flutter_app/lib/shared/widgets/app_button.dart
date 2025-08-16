import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Custom button widget with different styles and states
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final AppButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final Widget? trailingIcon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style = AppButtonStyle.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.trailingIcon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SizedBox(
      width: width ?? _getButtonWidth(),
      height: height ?? _getButtonHeight(),
      child: _buildButton(isDark),
    );
  }

  Widget _buildButton(bool isDark) {
    final isEnabled = onPressed != null && !isDisabled && !isLoading;

    switch (style) {
      case AppButtonStyle.primary:
        return ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: _getPrimaryButtonStyle(isDark),
          child: _buildButtonContent(),
        );
      
      case AppButtonStyle.secondary:
        return OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: _getSecondaryButtonStyle(isDark),
          child: _buildButtonContent(),
        );
      
      case AppButtonStyle.text:
        return TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: _getTextButtonStyle(isDark),
          child: _buildButtonContent(),
        );
      
      case AppButtonStyle.danger:
        return ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: _getDangerButtonStyle(isDark),
          child: _buildButtonContent(),
        );
      
      case AppButtonStyle.success:
        return ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: _getSuccessButtonStyle(isDark),
          child: _buildButtonContent(),
        );
    }
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        width: _getIconSize(),
        height: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            style == AppButtonStyle.primary || style == AppButtonStyle.danger || style == AppButtonStyle.success
                ? Colors.white
                : AppColors.primary500,
          ),
        ),
      );
    }

    final children = <Widget>[];

    if (icon != null) {
      children.add(
        Icon(
          icon,
          size: _getIconSize(),
        ),
      );
      children.add(SizedBox(width: _getIconSpacing()));
    }

    children.add(
      Flexible(
        child: Text(
          text,
          style: _getTextStyle(),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    if (trailingIcon != null) {
      children.add(SizedBox(width: _getIconSpacing()));
      children.add(trailingIcon!);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  ButtonStyle _getPrimaryButtonStyle(bool isDark) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? AppColors.primary500,
      foregroundColor: textColor ?? Colors.white,
      disabledBackgroundColor: isDark ? AppColors.neutral700 : AppColors.neutral300,
      disabledForegroundColor: isDark ? AppColors.neutral400 : AppColors.neutral500,
      elevation: _getElevation(),
      shadowColor: AppColors.shadowMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      padding: _getPadding(),
    );
  }

  ButtonStyle _getSecondaryButtonStyle(bool isDark) {
    return OutlinedButton.styleFrom(
      foregroundColor: textColor ?? AppColors.primary500,
      disabledForegroundColor: isDark ? AppColors.neutral400 : AppColors.neutral500,
      side: BorderSide(
        color: isDisabled 
            ? (isDark ? AppColors.neutral600 : AppColors.neutral300)
            : AppColors.primary500,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      padding: _getPadding(),
    );
  }

  ButtonStyle _getTextButtonStyle(bool isDark) {
    return TextButton.styleFrom(
      foregroundColor: textColor ?? AppColors.primary500,
      disabledForegroundColor: isDark ? AppColors.neutral400 : AppColors.neutral500,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      padding: _getPadding(),
    );
  }

  ButtonStyle _getDangerButtonStyle(bool isDark) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? AppColors.error500,
      foregroundColor: textColor ?? Colors.white,
      disabledBackgroundColor: isDark ? AppColors.neutral700 : AppColors.neutral300,
      disabledForegroundColor: isDark ? AppColors.neutral400 : AppColors.neutral500,
      elevation: _getElevation(),
      shadowColor: AppColors.shadowMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      padding: _getPadding(),
    );
  }

  ButtonStyle _getSuccessButtonStyle(bool isDark) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? AppColors.success500,
      foregroundColor: textColor ?? Colors.white,
      disabledBackgroundColor: isDark ? AppColors.neutral700 : AppColors.neutral300,
      disabledForegroundColor: isDark ? AppColors.neutral400 : AppColors.neutral500,
      elevation: _getElevation(),
      shadowColor: AppColors.shadowMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      padding: _getPadding(),
    );
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        );
      case AppButtonSize.medium:
        return const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        );
      case AppButtonSize.large:
        return const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        );
    }
  }

  double _getButtonWidth() {
    switch (size) {
      case AppButtonSize.small:
        return 80;
      case AppButtonSize.medium:
        return 120;
      case AppButtonSize.large:
        return 160;
    }
  }

  double _getButtonHeight() {
    switch (size) {
      case AppButtonSize.small:
        return 32;
      case AppButtonSize.medium:
        return 40;
      case AppButtonSize.large:
        return 48;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case AppButtonSize.small:
        return 4;
      case AppButtonSize.medium:
        return 8;
      case AppButtonSize.large:
        return 12;
    }
  }

  double _getElevation() {
    switch (size) {
      case AppButtonSize.small:
        return 1;
      case AppButtonSize.medium:
        return 2;
      case AppButtonSize.large:
        return 4;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 14;
      case AppButtonSize.medium:
        return 16;
      case AppButtonSize.large:
        return 20;
    }
  }

  double _getIconSpacing() {
    switch (size) {
      case AppButtonSize.small:
        return 4;
      case AppButtonSize.medium:
        return 6;
      case AppButtonSize.large:
        return 8;
    }
  }
}

/// Button style options
enum AppButtonStyle {
  primary,
  secondary,
  text,
  danger,
  success,
}

/// Button size options
enum AppButtonSize {
  small,
  medium,
  large,
}
