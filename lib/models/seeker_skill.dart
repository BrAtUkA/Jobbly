import 'enums/proficiency_level.dart';

class SeekerSkill {
  String seekerId;
  String skillId;
  ProficiencyLevel proficiencyLevel;

  SeekerSkill({
    required this.seekerId,
    required this.skillId,
    this.proficiencyLevel = ProficiencyLevel.intermediate,
  });

  Map<String, dynamic> toMap() {
    return {
      'seekerId': seekerId,
      'skillId': skillId,
      'proficiencyLevel': proficiencyLevel.name,
    };
  }

  factory SeekerSkill.fromMap(Map<String, dynamic> map) {
    return SeekerSkill(
      seekerId: map['seekerId'] ?? '',
      skillId: map['skillId'] ?? '',
      proficiencyLevel: ProficiencyLevel.values.firstWhere(
        (e) => e.name == map['proficiencyLevel'],
        orElse: () => ProficiencyLevel.intermediate,
      ),
    );
  }

  @override
  String toString() {
    return 'SeekerSkill(seekerId: $seekerId, skillId: $skillId, proficiencyLevel: $proficiencyLevel)';
  }
}
