import 'package:flutter/material.dart';
import 'package:project/models/models.dart';
import 'package:project/theme/app_theme.dart';

/// A reusable skill selector widget that groups skills by category.
/// 
/// Used for selecting skills in both seeker profile editing and job posting.
/// 
/// Usage:
/// ```dart
/// SkillSelector(
///   skills: availableSkills,
///   selectedSkillIds: _selectedSkillIds,
///   onSkillToggled: (skillId, selected) {
///     setState(() {
///       if (selected) _selectedSkillIds.add(skillId);
///       else _selectedSkillIds.remove(skillId);
///     });
///   },
/// )
/// ```
class SkillSelector extends StatelessWidget {
  /// List of all available skills to display.
  final List<Skill> skills;
  
  /// Set of currently selected skill IDs.
  final Set<String> selectedSkillIds;
  
  /// Callback when a skill is toggled.
  final void Function(String skillId, bool selected) onSkillToggled;

  const SkillSelector({
    super.key,
    required this.skills,
    required this.selectedSkillIds,
    required this.onSkillToggled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (skills.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Loading skills...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }
    
    // Group skills by category
    final skillsByCategory = <SkillCategory, List<Skill>>{};
    for (final skill in skills) {
      skillsByCategory.putIfAbsent(skill.category, () => []).add(skill);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${selectedSkillIds.length} skill${selectedSkillIds.length == 1 ? '' : 's'} selected',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...skillsByCategory.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatCategory(entry.key),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.value.map((skill) {
                    final isSelected = selectedSkillIds.contains(skill.skillId);
                    return FilterChip(
                      label: Text(skill.skillName),
                      selected: isSelected,
                      showCheckmark: false,
                      onSelected: (selected) => onSkillToggled(skill.skillId, selected),
                      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _formatCategory(SkillCategory category) {
    switch (category) {
      case SkillCategory.technical:
        return 'Technical Skills';
      case SkillCategory.soft:
        return 'Soft Skills';
      case SkillCategory.other:
        return 'Other Skills';
    }
  }
}
