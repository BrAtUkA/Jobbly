import 'package:flutter/material.dart';
import 'package:project/theme/app_theme.dart';

/// Data for a single stat item.
class ProfileStatData {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const ProfileStatData({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// A single stat item with icon, value, and label.
class ProfileStatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const ProfileStatItem({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  factory ProfileStatItem.fromData(ProfileStatData data) {
    return ProfileStatItem(
      value: data.value,
      label: data.label,
      icon: data.icon,
      color: data.color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A row of stat items.
/// 
/// Usage:
/// ```dart
/// ProfileStatsRow(
///   stats: [
///     ProfileStatData(value: '5', label: 'Jobs', icon: Icons.work, color: Colors.blue),
///     ProfileStatData(value: '3', label: 'Active', icon: Icons.check, color: Colors.green),
///   ],
/// )
/// ```
class ProfileStatsRow extends StatelessWidget {
  final List<ProfileStatData> stats;

  const ProfileStatsRow({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index > 0 ? 6 : 0,
              right: index < stats.length - 1 ? 6 : 0,
            ),
            child: ProfileStatItem.fromData(stat),
          ),
        );
      }).toList(),
    );
  }
}
