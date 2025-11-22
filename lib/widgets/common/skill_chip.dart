import 'package:flutter/material.dart';
import 'package:project/theme/app_theme.dart';

/// A selectable skill chip used for skill selection in forms.
/// 
/// This is the standardized component for both seeker and company 
/// skill selection. Uses color highlighting without checkmarks.
/// 
/// Usage:
/// ```dart
/// SelectableSkillChip(
///   label: 'Flutter',
///   isSelected: _selectedSkills.contains('Flutter'),
///   onSelected: (selected) => setState(() {
///     if (selected) _selectedSkills.add('Flutter');
///     else _selectedSkills.remove('Flutter');
///   }),
/// )
/// ```
class SelectableSkillChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;
  final Color? selectedColor;

  const SelectableSkillChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selectedColor ?? theme.primaryColor;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      onSelected: onSelected,
      selectedColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.grey.shade300,
      ),
    );
  }
}

/// A chip displaying a skill name.
/// 
/// Can show a checkmark when [isMatched] is true to indicate
/// the user has this skill.
class SkillChip extends StatelessWidget {
  final String name;
  final bool isMatched;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SkillChip({
    super.key,
    required this.name,
    this.isMatched = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isMatched ? AppTheme.secondaryColor : AppTheme.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMatched 
              ? color.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isMatched 
                ? color.withValues(alpha: 0.3)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMatched)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: color,
                ),
              ),
            Text(
              name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isMatched ? color : AppTheme.textSecondary,
                fontWeight: isMatched ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A simple skill chip without match indicator.
/// 
/// Uses primary color styling.
class SimpleSkillChip extends StatelessWidget {
  final String name;
  final VoidCallback? onTap;

  const SimpleSkillChip({
    super.key,
    required this.name,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          name,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// A wrap of skill chips.
/// 
/// Usage:
/// ```dart
/// SkillChipWrap(
///   skills: ['Flutter', 'Dart', 'Firebase'],
///   matchedSkills: {'Flutter', 'Dart'},
/// )
/// ```
class SkillChipWrap extends StatelessWidget {
  final List<String> skills;
  final Set<String>? matchedSkillIds;
  final Set<String>? matchedSkills;
  final List<String>? skillIds;
  final bool showMatchIndicator;

  const SkillChipWrap({
    super.key,
    required this.skills,
    this.matchedSkillIds,
    this.matchedSkills,
    this.skillIds,
    this.showMatchIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.asMap().entries.map((entry) {
        final index = entry.key;
        final name = entry.value;
        final skillId = skillIds != null && index < skillIds!.length 
            ? skillIds![index] 
            : null;
        
        // Check if matched by ID or by name
        final isMatchedById = showMatchIndicator && 
            matchedSkillIds != null && 
            skillId != null &&
            matchedSkillIds!.contains(skillId);
        final isMatchedByName = showMatchIndicator && 
            matchedSkills != null && 
            matchedSkills!.contains(name);
        final isMatched = isMatchedById || isMatchedByName;

        if (showMatchIndicator) {
          return SkillChip(name: name, isMatched: isMatched);
        }
        return SimpleSkillChip(name: name);
      }).toList(),
    );
  }
}
