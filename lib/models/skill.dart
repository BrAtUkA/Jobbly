import 'enums/skill_category.dart';

class Skill {
  String skillId;
  String skillName;
  SkillCategory category;

  Skill({
    required this.skillId,
    required this.skillName,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'skillId': skillId,
      'skillName': skillName,
      'category': category.name,
    };
  }

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      skillId: map['skillId'] ?? '',
      skillName: map['skillName'] ?? '',
      category: SkillCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => SkillCategory.other,
      ),
    );
  }

  @override
  String toString() {
    return 'Skill(skillId: $skillId, skillName: $skillName, category: ${category.name})';
  }
}
