import 'package:flutter/material.dart';
import 'package:project/theme/app_theme.dart';
import 'package:project/models/models.dart';

/// Data class for job info items
class JobInfoData {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const JobInfoData({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });
}

/// A single info item for job details
class JobInfoItem extends StatelessWidget {
  final JobInfoData data;

  const JobInfoItem({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = data.color ?? AppTheme.primaryColor;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(data.icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                data.value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: data.color ?? AppTheme.textPrimary,
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

/// A grid of job info items displayed in a card
class JobInfoGrid extends StatelessWidget {
  final List<List<JobInfoData>> rows;

  const JobInfoGrid({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return Column(
            children: [
              if (index > 0) const SizedBox(height: 16),
              Row(
                children: row.asMap().entries.map((itemEntry) {
                  final itemIndex = itemEntry.key;
                  final item = itemEntry.value;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: itemIndex > 0 ? 8 : 0,
                      ),
                      child: JobInfoItem(data: item),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Factory constructor to build from a Job model
  factory JobInfoGrid.fromJob({
    required Job job,
    required String? companyName,
  }) {
    return JobInfoGrid(
      rows: [
        [
          JobInfoData(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: job.location,
          ),
          JobInfoData(
            icon: Icons.work_outline_rounded,
            label: 'Type',
            value: _formatJobType(job.jobType),
          ),
        ],
        [
          JobInfoData(
            icon: Icons.school_outlined,
            label: 'Education',
            value: _formatEducation(job.requiredEducation),
          ),
          JobInfoData(
            icon: Icons.attach_money_rounded,
            label: 'Salary',
            value: _formatSalary(job),
          ),
        ],
        [
          JobInfoData(
            icon: Icons.calendar_today_outlined,
            label: 'Posted',
            value: _formatDate(job.postedDate),
          ),
          JobInfoData(
            icon: Icons.circle,
            label: 'Status',
            value: job.status == JobStatus.active ? 'Active' : 'Closed',
            color: job.status == JobStatus.active 
                ? AppTheme.secondaryColor 
                : AppTheme.errorColor,
          ),
        ],
      ],
    );
  }

  static String _formatJobType(JobType type) {
    switch (type) {
      case JobType.fullTime:
        return 'Full-time';
      case JobType.partTime:
        return 'Part-time';
      case JobType.internship:
        return 'Internship';
      case JobType.contract:
        return 'Contract';
    }
  }

  static String _formatEducation(EducationLevel level) {
    switch (level) {
      case EducationLevel.matric:
        return 'Matric';
      case EducationLevel.inter:
        return 'Intermediate';
      case EducationLevel.bs:
        return 'Bachelor\'s';
      case EducationLevel.ms:
        return 'Master\'s';
      case EducationLevel.phd:
        return 'PhD';
    }
  }

  static String _formatSalary(Job job) {
    if (job.minSalary != null && job.maxSalary != null) {
      return '${_formatNumber(job.minSalary!)} - ${_formatNumber(job.maxSalary!)}';
    } else if (job.minSalary != null) {
      return '${_formatNumber(job.minSalary!)}+';
    } else if (job.maxSalary != null) {
      return 'Up to ${_formatNumber(job.maxSalary!)}';
    }
    return 'Not specified';
  }

  static String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toStringAsFixed(0);
  }

  static String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
