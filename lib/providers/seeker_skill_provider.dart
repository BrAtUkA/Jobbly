import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project/models/models.dart';

class SeekerSkillProvider with ChangeNotifier {
  Box? _seekerSkillBox;
  List<SeekerSkill> _seekerSkills = [];
  final _supabase = Supabase.instance.client;
  bool _initialized = false;

  List<SeekerSkill> get seekerSkills => _seekerSkills;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    
    if (!Hive.isBoxOpen('seekerSkillsBox')) {
      _seekerSkillBox = await Hive.openBox('seekerSkillsBox');
    } else {
      _seekerSkillBox = Hive.box('seekerSkillsBox');
    }
    getAllSeekerSkills();
    // Fetch from Supabase
    await fetchAllSeekerSkillsFromSupabase();
  }

  /// Add seeker skill: Supabase first, then Hive cache
  Future<void> addSeekerSkill(SeekerSkill seekerSkill) async {
    if (_seekerSkillBox == null) await init();
    
    try {
      // 1. Insert into Supabase
      await _supabase
          .from('seeker_skills')
          .insert(seekerSkill.toMap());

      // 2. Cache in Hive
      final key = '${seekerSkill.seekerId}_${seekerSkill.skillId}';
      await _seekerSkillBox!.put(key, seekerSkill.toMap());

      // 3. Update local state (check for duplicates)
      final exists = _seekerSkills.any((e) => 
        e.seekerId == seekerSkill.seekerId && e.skillId == seekerSkill.skillId);
      if (!exists) {
        _seekerSkills.add(seekerSkill);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding seeker skill: $e');
      rethrow;
    }
  }

  /// Add multiple seeker skills at once (for batch saving during onboarding)
  Future<void> addSeekerSkills(List<SeekerSkill> skills) async {
    if (_seekerSkillBox == null) await init();
    if (skills.isEmpty) return;

    try {
      // 1. Insert all into Supabase
      final data = skills.map((s) => s.toMap()).toList();
      await _supabase
          .from('seeker_skills')
          .insert(data);

      // 2. Cache in Hive and update local state
      for (final skill in skills) {
        final key = '${skill.seekerId}_${skill.skillId}';
        await _seekerSkillBox!.put(key, skill.toMap());
        
        final exists = _seekerSkills.any((e) => 
          e.seekerId == skill.seekerId && e.skillId == skill.skillId);
        if (!exists) {
          _seekerSkills.add(skill);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding seeker skills: $e');
      rethrow;
    }
  }

  /// Update seeker skill proficiency
  Future<void> updateSeekerSkill(SeekerSkill seekerSkill) async {
    if (_seekerSkillBox == null) await init();
    
    try {
      // 1. Update in Supabase
      await _supabase
          .from('seeker_skills')
          .update({'proficiencyLevel': seekerSkill.proficiencyLevel.name})
          .eq('seekerId', seekerSkill.seekerId)
          .eq('skillId', seekerSkill.skillId);

      // 2. Update Hive cache
      final key = '${seekerSkill.seekerId}_${seekerSkill.skillId}';
      await _seekerSkillBox!.put(key, seekerSkill.toMap());

      // 3. Update local state
      final index = _seekerSkills.indexWhere((e) => 
        e.seekerId == seekerSkill.seekerId && e.skillId == seekerSkill.skillId);
      if (index != -1) {
        _seekerSkills[index] = seekerSkill;
      } else {
        _seekerSkills.add(seekerSkill);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating seeker skill: $e');
      rethrow;
    }
  }

  /// Delete seeker skill: Supabase first, then Hive cache
  Future<void> deleteSeekerSkill(String seekerId, String skillId) async {
    if (_seekerSkillBox == null) await init();
    
    try {
      // 1. Delete from Supabase
      await _supabase
          .from('seeker_skills')
          .delete()
          .eq('seekerId', seekerId)
          .eq('skillId', skillId);

      // 2. Delete from Hive cache
      final key = '${seekerId}_$skillId';
      await _seekerSkillBox!.delete(key);

      // 3. Update local state
      _seekerSkills.removeWhere((e) => e.seekerId == seekerId && e.skillId == skillId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting seeker skill: $e');
      rethrow;
    }
  }

  /// Delete all skills for a seeker and add new ones
  Future<void> updateSeekerSkills(String seekerId, List<SeekerSkill> newSkills) async {
    if (_seekerSkillBox == null) await init();

    try {
      // 1. Delete existing skills for seeker from Supabase
      await _supabase
          .from('seeker_skills')
          .delete()
          .eq('seekerId', seekerId);

      // 2. Insert new skills
      if (newSkills.isNotEmpty) {
        final data = newSkills.map((s) => s.toMap()).toList();
        await _supabase
            .from('seeker_skills')
            .insert(data);
      }

      // 3. Update Hive cache
      // Remove old entries
      final keysToRemove = _seekerSkillBox!.keys.where((key) => 
        key.toString().startsWith('${seekerId}_')).toList();
      for (final key in keysToRemove) {
        await _seekerSkillBox!.delete(key);
      }
      
      // Add new entries
      for (final skill in newSkills) {
        final key = '${skill.seekerId}_${skill.skillId}';
        await _seekerSkillBox!.put(key, skill.toMap());
      }

      // 4. Update local state
      _seekerSkills.removeWhere((e) => e.seekerId == seekerId);
      _seekerSkills.addAll(newSkills);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating seeker skills: $e');
      rethrow;
    }
  }

  /// Fetch all seeker skills from Supabase and sync to Hive
  Future<void> fetchAllSeekerSkillsFromSupabase() async {
    try {
      final response = await _supabase
          .from('seeker_skills')
          .select();

      final skills = (response as List)
          .map((e) => SeekerSkill.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      // Update Hive cache
      await _seekerSkillBox?.clear();
      for (final skill in skills) {
        final key = '${skill.seekerId}_${skill.skillId}';
        await _seekerSkillBox?.put(key, skill.toMap());
      }

      // Update local state
      _seekerSkills = skills;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching seeker skills from Supabase: $e');
      // Fall back to Hive cache
      getAllSeekerSkills();
    }
  }

  void getAllSeekerSkills() {
    if (_seekerSkillBox == null) return;
    _seekerSkills = _seekerSkillBox!.values.map((e) =>
      SeekerSkill.fromMap(Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
    ).toList();
    notifyListeners();
  }

  List<SeekerSkill> getSkillsForSeeker(String seekerId) {
    return _seekerSkills.where((s) => s.seekerId == seekerId).toList();
  }

  List<SeekerSkill> getSeekersWithSkill(String skillId) {
    return _seekerSkills.where((s) => s.skillId == skillId).toList();
  }
}
