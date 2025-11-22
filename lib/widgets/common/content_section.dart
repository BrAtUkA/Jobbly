import 'package:flutter/material.dart';
import 'package:project/theme/app_theme.dart';
import 'package:project/widgets/common/info_card.dart';

/// A titled content section with optional action button.
/// 
/// Displays a title, optional "Edit" or "See All" button, and content.
/// Wrapped in an AppCard for consistent styling.
class ContentSection extends StatelessWidget {
  final String title;
  final Widget content;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  const ContentSection({
    super.key,
    required this.title,
    required this.content,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}

/// A simple text content section.
/// 
/// Displays a title and body text in a styled card.
class TextSection extends StatelessWidget {
  final String title;
  final String content;

  const TextSection({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ContentSection(
      title: title,
      content: Text(
        content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondary,
          height: 1.6,
        ),
      ),
    );
  }
}

/// A detail item with icon, label, and value.
/// 
/// Used in profile details sections.
class DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLink;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const DetailItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isLink = false,
    this.isHighlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlighted = isLink || isHighlighted;

    final content = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: highlighted ? AppTheme.primaryColor : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (isLink)
          Icon(Icons.open_in_new, size: 16, color: AppTheme.primaryColor),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: content,
    );
  }
}
