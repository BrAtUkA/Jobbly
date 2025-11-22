import 'package:flutter/material.dart';
import 'package:project/theme/app_theme.dart';

/// A quick action button with an icon and label.
/// 
/// Displays a circular icon on a tinted background with a label below.
/// Used in dashboard quick action sections.
/// 
/// Usage:
/// ```dart
/// QuickActionButton(
///   label: 'Post Job',
///   icon: Icons.add_rounded,
///   color: AppTheme.primaryColor,
///   onTap: () => Navigator.pushNamed(context, '/create-job'),
/// )
/// ```
class QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row of quick action buttons with consistent spacing.
/// 
/// Usage:
/// ```dart
/// QuickActionsRow(
///   actions: [
///     QuickActionData(label: 'Post Job', icon: Icons.add, color: Colors.blue, onTap: () {}),
///     QuickActionData(label: 'Profile', icon: Icons.person, color: Colors.green, onTap: () {}),
///   ],
/// )
/// ```
class QuickActionsRow extends StatelessWidget {
  final List<QuickActionData> actions;

  const QuickActionsRow({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: actions.asMap().entries.map((entry) {
        final index = entry.key;
        final action = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 6,
              right: index == actions.length - 1 ? 0 : 6,
            ),
            child: QuickActionButton(
              label: action.label,
              icon: action.icon,
              color: action.color,
              onTap: action.onTap,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Data class for a quick action in [QuickActionsRow].
class QuickActionData {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickActionData({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
