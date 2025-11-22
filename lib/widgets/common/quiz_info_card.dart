import 'package:flutter/material.dart';
import 'package:project/theme/app_theme.dart';
import 'package:project/models/models.dart';

/// Quiz info card showing quiz details with assessment info
class QuizInfoCard extends StatelessWidget {
  final Quiz quiz;
  final Color accentColor;

  const QuizInfoCard({
    super.key,
    required this.quiz,
    this.accentColor = const Color(0xFF8B5CF6),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.quiz_rounded,
                  color: accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assessment Required',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      quiz.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _QuizStat(value: '${quiz.questions.length}', label: 'Questions', color: accentColor),
              const SizedBox(width: 24),
              _QuizStat(value: '${quiz.duration} min', label: 'Duration', color: accentColor),
              const SizedBox(width: 24),
              _QuizStat(value: '${quiz.passingScore}%', label: 'Pass Score', color: accentColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You\'ll need to complete this quiz as part of your application.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _QuizStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Quiz stat item with icon for bottom sheet
class QuizStatIcon extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const QuizStatIcon({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.color = const Color(0xFF8B5CF6),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
