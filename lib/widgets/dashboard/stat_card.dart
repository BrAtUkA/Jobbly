import 'package:flutter/material.dart';
import 'package:project/theme/app_theme.dart';

/// A single stat item displaying a value and label with a colored value.
class StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const StatItem({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// A container card displaying multiple stats in a row with dividers.
/// 
/// Usage:
/// ```dart
/// StatsCard(
///   title: 'Overview',
///   stats: [
///     StatData(value: '5', label: 'Jobs', color: AppTheme.primaryColor),
///     StatData(value: '12', label: 'Applications', color: AppTheme.secondaryColor),
///   ],
/// )
/// ```
class StatsCard extends StatelessWidget {
  final String title;
  final List<StatData> stats;

  const StatsCard({
    super.key,
    required this.title,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: _buildStatsWithDividers(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatsWithDividers() {
    final widgets = <Widget>[];
    for (int i = 0; i < stats.length; i++) {
      widgets.add(
        Expanded(
          child: StatItem(
            value: stats[i].value,
            label: stats[i].label,
            color: stats[i].color,
          ),
        ),
      );
      if (i < stats.length - 1) {
        widgets.add(const _VerticalDivider());
      }
    }
    return widgets;
  }
}

/// Data class for a single stat in [StatsCard].
class StatData {
  final String value;
  final String label;
  final Color color;

  const StatData({
    required this.value,
    required this.label,
    required this.color,
  });
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.shade200,
    );
  }
}
