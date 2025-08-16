import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// Custom text field widget with validation and different styles
class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final AppTextFieldStyle style;
  final AppTextFieldSize size;
  final bool showCounter;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;
  final String? helperText;
  final String? errorText;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.focusNode,
    this.style = AppTextFieldStyle.outlined,
    this.size = AppTextFieldSize.medium,
    this.showCounter = false,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.helperText,
    this.errorText,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _obscureText = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureText = widget.obscureText;
    
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelLarge?.copyWith(
              color: _hasError 
                  ? AppColors.error500 
                  : (_focusNode.hasFocus 
                      ? AppColors.primary500 
                      : theme.colorScheme.onSurface),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
        ],
        _buildTextField(isDark),
        if (widget.helperText != null && !_hasError) ...[
          const SizedBox(height: 4),
          Text(
            widget.helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (_hasError && widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.error500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(bool isDark) {
    final decoration = _getInputDecoration(isDark);
    
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: _obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      validator: (value) {
        final error = widget.validator?.call(value);
        setState(() {
          _hasError = error != null;
        });
        return error;
      },
      onChanged: (value) {
        if (_hasError) {
          setState(() {
            _hasError = false;
          });
        }
        widget.onChanged?.call(value);
      },
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      inputFormatters: widget.inputFormatters,
      autofocus: widget.autofocus,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      decoration: decoration,
      style: _getTextStyle(),
    );
  }

  InputDecoration _getInputDecoration(bool isDark) {
    final baseDecoration = InputDecoration(
      hintText: widget.hint,
      prefixIcon: widget.prefixIcon,
      suffixIcon: _buildSuffixIcon(),
      counterText: widget.showCounter ? null : '',
      filled: widget.style == AppTextFieldStyle.filled,
      fillColor: widget.style == AppTextFieldStyle.filled
          ? (isDark ? AppColors.neutral800 : AppColors.neutral50)
          : null,
      border: _getBorder(),
      enabledBorder: _getEnabledBorder(),
      focusedBorder: _getFocusedBorder(),
      errorBorder: _getErrorBorder(),
      focusedErrorBorder: _getFocusedErrorBorder(),
      disabledBorder: _getDisabledBorder(),
      contentPadding: _getContentPadding(),
      isDense: widget.size == AppTextFieldSize.small,
    );

    return baseDecoration;
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
          size: _getIconSize(),
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }
    return widget.suffixIcon;
  }

  InputBorder _getBorder() {
    switch (widget.style) {
      case AppTextFieldStyle.outlined:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          borderSide: const BorderSide(color: AppColors.borderLight),
        );
      case AppTextFieldStyle.filled:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          borderSide: BorderSide.none,
        );
      case AppTextFieldStyle.underline:
        return UnderlineInputBorder(
          borderSide: const BorderSide(color: AppColors.borderLight),
        );
    }
  }

  InputBorder _getEnabledBorder() {
    switch (widget.style) {
      case AppTextFieldStyle.outlined:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          borderSide: const BorderSide(color: AppColors.borderLight),
        );
      case AppTextFieldStyle.filled:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          borderSide: BorderSide.none,
        );
      case AppTextFieldStyle.underline:
        return UnderlineInputBorder(
          borderSide: const BorderSide(color: AppColors.borderLight),
        );
    }
  }

  InputBorder _getFocusedBorder() {
    switch (widget.style) {
      case AppTextFieldStyle.outlined:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          borderSide: const BorderSide(color: AppColors.primary500, width: 2),
        );
      case AppTextFieldStyle.filled:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          borderSide: const BorderSide(color: AppColors.primary500, width: 2),
        );
      case AppTextFieldStyle.underline:
        return UnderlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary500, width: 2),
        );
    }
  }

  InputBorder _getErrorBorder() {
    switch (widget.style) {
      case AppTextFieldStyle.outlined:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          borderSide: const BorderSide(color: AppColors.error500, width: 2),
        );
      case AppTextFieldStyle.filled:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          borderSide: const BorderSide(color: AppColors.error500, width: 2),
        );
      case AppTextFieldStyle.underline:
        return UnderlineInputBorder(
          borderSide: const BorderSide(color: AppColors.error500, width: 2),
        );
    }
  }

  InputBorder _getFocusedErrorBorder() {
    switch (widget.style) {
      case AppTextFieldStyle.outlined:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          borderSide: const BorderSide(color: AppColors.error500, width: 2),
        );
      case AppTextFieldStyle.filled:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          borderSide: const BorderSide(color: AppColors.error500, width: 2),
        );
      case AppTextFieldStyle.underline:
        return UnderlineInputBorder(
          borderSide: const BorderSide(color: AppColors.error500, width: 2),
        );
    }
  }

  InputBorder _getDisabledBorder() {
    switch (widget.style) {
      case AppTextFieldStyle.outlined:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          borderSide: const BorderSide(color: AppColors.borderMedium),
        );
      case AppTextFieldStyle.filled:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          borderSide: BorderSide.none,
        );
      case AppTextFieldStyle.underline:
        return UnderlineInputBorder(
          borderSide: const BorderSide(color: AppColors.borderMedium),
        );
    }
  }

  EdgeInsets _getContentPadding() {
    switch (widget.size) {
      case AppTextFieldSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case AppTextFieldSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case AppTextFieldSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    }
  }

  double _getBorderRadius() {
    switch (widget.size) {
      case AppTextFieldSize.small:
        return 4;
      case AppTextFieldSize.medium:
        return 8;
      case AppTextFieldSize.large:
        return 12;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case AppTextFieldSize.small:
        return 16;
      case AppTextFieldSize.medium:
        return 20;
      case AppTextFieldSize.large:
        return 24;
    }
  }

  TextStyle _getTextStyle() {
    switch (widget.size) {
      case AppTextFieldSize.small:
        return const TextStyle(fontSize: 12);
      case AppTextFieldSize.medium:
        return const TextStyle(fontSize: 14);
      case AppTextFieldSize.large:
        return const TextStyle(fontSize: 16);
    }
  }
}

/// Text field style options
enum AppTextFieldStyle {
  outlined,
  filled,
  underline,
}

/// Text field size options
enum AppTextFieldSize {
  small,
  medium,
  large,
}
