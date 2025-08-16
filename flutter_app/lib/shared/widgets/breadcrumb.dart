import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class BreadcrumbItem {
  final String label;
  final String? route;
  final IconData? icon;

  BreadcrumbItem({
    required this.label,
    this.route,
    this.icon,
  });
}

class Breadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final bool showHome;

  const Breadcrumb({
    super.key,
    required this.items,
    this.showHome = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    List<BreadcrumbItem> breadcrumbItems = [];
    
    // Add home item if showHome is true
    if (showHome) {
      breadcrumbItems.add(BreadcrumbItem(
        label: 'Home',
        route: '/',
        icon: Icons.home,
      ));
    }
    
    // Add all other items
    breadcrumbItems.addAll(items);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: breadcrumbItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == breadcrumbItems.length - 1;

          return Row(
            children: [
              if (index > 0) ...[
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                            ? AppColors.primary500
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      item.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isLast
                            ? AppColors.primary500
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
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
    );
  }
}
