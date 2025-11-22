import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project/models/models.dart';

class SkillProvider with ChangeNotifier {
  Box? _skillBox;
  List<Skill> _skills = [];
  final _supabase = Supabase.instance.client;
  bool _initialized = false;

  List<Skill> get skills => _skills;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    
    if (!Hive.isBoxOpen('skillsBox')) {
      _skillBox = await Hive.openBox('skillsBox');
    } else {
      _skillBox = Hive.box('skillsBox');
    }
    getAllSkills();
    // Fetch from Supabase and seed if empty
    await fetchAllSkillsFromSupabase();
  }

  Future<void> addSkill(Skill skill) async {
    if (_skillBox == null) await init();
    
    try {
      // 1. Insert into Supabase
      final response = await _supabase
          .from('skills')
          .insert(skill.toMap())
          .select()
          .single();

      final savedSkill = Skill.fromMap(Map<String, dynamic>.from(response));

      // 2. Cache in Hive
      await _skillBox!.put(savedSkill.skillId, savedSkill.toMap());

      // 3. Update local state
      _skills.add(savedSkill);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding skill: $e');
      rethrow;
    }
  }

  Future<void> deleteSkill(String skillId) async {
    if (_skillBox == null) await init();
    
    try {
      // 1. Delete from Supabase
      await _supabase
          .from('skills')
          .delete()
          .eq('skillId', skillId);

      // 2. Delete from Hive
      await _skillBox!.delete(skillId);

      // 3. Update local state
      _skills.removeWhere((e) => e.skillId == skillId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting skill: $e');
      rethrow;
    }
  }

  void getAllSkills() {
    if (_skillBox == null) return;
    _skills = _skillBox!.values.map((e) =>
      Skill.fromMap(Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
    ).toList();
    _skills.sort((a, b) => a.skillName.compareTo(b.skillName));
    notifyListeners();
  }

  /// Fetch all skills from Supabase and seed default skills if empty
  Future<void> fetchAllSkillsFromSupabase() async {
    if (_skillBox == null) return;
    
    try {
      final response = await _supabase
          .from('skills')
          .select()
          .order('skillName');

      final fetchedSkills = response as List<dynamic>;

      // If no skills exist in database, seed with default skills
      if (fetchedSkills.isEmpty) {
        await _seedDefaultSkills();
        return;
      }

      final newSkills = fetchedSkills
          .map((e) => Skill.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      // Clear and rebuild cache
      await _skillBox!.clear();
      for (final skill in newSkills) {
        await _skillBox!.put(skill.skillId, skill.toMap());
      }

      // Replace local state atomically
      _skills = newSkills;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching skills from Supabase: $e');
      // If fetch fails but we have no local skills, seed defaults locally
      if (_skills.isEmpty) {
        _seedDefaultSkillsLocally();
      }
    }
  }

  /// Seed default skills to Supabase
  Future<void> _seedDefaultSkills() async {
    final defaultSkills = _getDefaultSkillsList();
    
    try {
      final response = await _supabase
          .from('skills')
          .insert(defaultSkills)
          .select();

      // Clear Hive cache and update
      await _skillBox!.clear();
      _skills = [];

      for (var data in response as List<dynamic>) {
        final skill = Skill.fromMap(Map<String, dynamic>.from(data));
        await _skillBox!.put(skill.skillId, skill.toMap());
        _skills.add(skill);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error seeding default skills: $e');
      _seedDefaultSkillsLocally();
    }
  }

  /// Seed default skills locally (fallback)
  void _seedDefaultSkillsLocally() {
    final defaultSkills = _getDefaultSkillsList();
    _skills = [];
    
    for (var data in defaultSkills) {
      final skill = Skill.fromMap(data);
      _skillBox?.put(skill.skillId, skill.toMap());
      _skills.add(skill);
    }
    
    notifyListeners();
  }

  List<Map<String, dynamic>> _getDefaultSkillsList() {
    return [
      // Technical Skills
      {'skillName': 'Flutter', 'category': 'technical'},
      {'skillName': 'React', 'category': 'technical'},
      {'skillName': 'Python', 'category': 'technical'},
      {'skillName': 'JavaScript', 'category': 'technical'},
      {'skillName': 'Java', 'category': 'technical'},
      {'skillName': 'Node.js', 'category': 'technical'},
      {'skillName': 'SQL', 'category': 'technical'},
      {'skillName': 'AWS', 'category': 'technical'},
      {'skillName': 'Docker', 'category': 'technical'},
      {'skillName': 'Git', 'category': 'technical'},
      {'skillName': 'TypeScript', 'category': 'technical'},
      {'skillName': 'React Native', 'category': 'technical'},
      {'skillName': 'Angular', 'category': 'technical'},
      {'skillName': 'Vue.js', 'category': 'technical'},
      {'skillName': 'C++', 'category': 'technical'},
      {'skillName': 'C#', 'category': 'technical'},
      {'skillName': 'PHP', 'category': 'technical'},
      {'skillName': 'Ruby', 'category': 'technical'},
      {'skillName': 'Go', 'category': 'technical'},
      {'skillName': 'Kotlin', 'category': 'technical'},
      {'skillName': 'Swift', 'category': 'technical'},
      {'skillName': 'MongoDB', 'category': 'technical'},
      {'skillName': 'PostgreSQL', 'category': 'technical'},
      {'skillName': 'Firebase', 'category': 'technical'},
      {'skillName': 'GraphQL', 'category': 'technical'},
      // Soft Skills
      {'skillName': 'Communication', 'category': 'soft'},
      {'skillName': 'Leadership', 'category': 'soft'},
      {'skillName': 'Problem Solving', 'category': 'soft'},
      {'skillName': 'Teamwork', 'category': 'soft'},
      {'skillName': 'Time Management', 'category': 'soft'},
      {'skillName': 'Critical Thinking', 'category': 'soft'},
      {'skillName': 'Creativity', 'category': 'soft'},
      {'skillName': 'Adaptability', 'category': 'soft'},
      // Other Skills
      {'skillName': 'Microsoft Office', 'category': 'other'},
      {'skillName': 'Project Management', 'category': 'other'},
      {'skillName': 'Data Analysis', 'category': 'other'},
      {'skillName': 'UI/UX Design', 'category': 'other'},
      {'skillName': 'Agile/Scrum', 'category': 'other'},
      {'skillName': 'Machine Learning', 'category': 'other'},
      {'skillName': 'DevOps', 'category': 'other'},
    ];
  }

  Skill? getSkillById(String skillId) {
    try {
      return _skills.firstWhere((s) => s.skillId == skillId);
    } catch (e) {
      return null;
    }
  }

  Skill? getSkillByName(String name) {
    try {
      return _skills.firstWhere(
        (s) => s.skillName.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  List<Skill> getSkillsByCategory(SkillCategory category) {
    return _skills.where((s) => s.category == category).toList();
  }
}
