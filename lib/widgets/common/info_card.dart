import 'package:flutter/material.dart';
import 'package:project/theme/app_theme.dart';

/// Standard card container used throughout the app.
/// 
/// Provides consistent styling with white background, rounded corners,
/// and subtle shadow.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Data model for a single info item (icon + label + value).
class InfoItemData {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const InfoItemData({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });
}

/// A single info item with icon, label, and value.
/// 
/// Used in info grids and detail displays.
class InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const InfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  factory InfoItem.fromData(InfoItemData data) {
    return InfoItem(
      icon: data.icon,
      label: data.label,
      value: data.value,
      color: data.color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? AppTheme.primaryColor;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: effectiveColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: effectiveColor == AppTheme.primaryColor 
                      ? AppTheme.textPrimary 
                      : effectiveColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A grid of info items in rows of 2.
/// 
/// Usage:
/// ```dart
/// InfoGrid(
///   items: [
///     InfoItemData(icon: Icons.location_on, label: 'Location', value: 'NYC'),
///     InfoItemData(icon: Icons.work, label: 'Type', value: 'Full-time'),
///   ],
/// )
/// ```
class InfoGrid extends StatelessWidget {
  final List<InfoItemData> items;
  final int columns;

  const InfoGrid({
    super.key,
    required this.items,
    this.columns = 2,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    
    for (int i = 0; i < items.length; i += columns) {
      final rowItems = items.skip(i).take(columns).toList();
      rows.add(
        Row(
          children: rowItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < rowItems.length - 1 ? 8 : 0,
                ),
                child: InfoItem.fromData(item),
              ),
            );
          }).toList(),
        ),
      );
      if (i + columns < items.length) {
        rows.add(const SizedBox(height: 16));
      }
    }

    return Column(children: rows);
  }
}

/// An info card containing a grid of info items.
class InfoCard extends StatelessWidget {
  final List<InfoItemData> items;
  final int columns;

  const InfoCard({
    super.key,
    required this.items,
    this.columns = 2,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: InfoGrid(items: items, columns: columns),
    );
  }
}
