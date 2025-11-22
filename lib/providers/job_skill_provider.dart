import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project/models/models.dart';

class JobSkillProvider with ChangeNotifier {
  Box? _jobSkillBox;
  List<JobSkill> _jobSkills = [];
  final _supabase = Supabase.instance.client;
  bool _initialized = false;

  List<JobSkill> get jobSkills => _jobSkills;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    
    if (!Hive.isBoxOpen('jobSkillsBox')) {
      _jobSkillBox = await Hive.openBox('jobSkillsBox');
    } else {
      _jobSkillBox = Hive.box('jobSkillsBox');
    }
    getAllJobSkills();
    // Fetch from Supabase (awaited to prevent race conditions)
    await fetchAllJobSkillsFromSupabase();
  }

  /// Add job skill: Supabase first, then Hive cache
  Future<void> addJobSkill(JobSkill jobSkill) async {
    if (_jobSkillBox == null) await init();
    
    try {
      // 1. Insert into Supabase
      await _supabase
          .from('job_skills')
          .insert(jobSkill.toMap());

      // 2. Cache in Hive
      final key = '${jobSkill.jobId}_${jobSkill.skillId}';
      await _jobSkillBox!.put(key, jobSkill.toMap());

      // 3. Update local state (check for duplicates)
      final exists = _jobSkills.any((e) => 
        e.jobId == jobSkill.jobId && e.skillId == jobSkill.skillId);
      if (!exists) {
        _jobSkills.add(jobSkill);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding job skill: $e');
      rethrow;
    }
  }

  /// Add multiple job skills at once (for batch saving)
  Future<void> addJobSkills(List<JobSkill> skills) async {
    if (_jobSkillBox == null) await init();
    if (skills.isEmpty) return;

    try {
      // 1. Insert all into Supabase
      final data = skills.map((s) => s.toMap()).toList();
      await _supabase
          .from('job_skills')
          .insert(data);

      // 2. Cache in Hive and update local state
      for (final skill in skills) {
        final key = '${skill.jobId}_${skill.skillId}';
        await _jobSkillBox!.put(key, skill.toMap());
        
        final exists = _jobSkills.any((e) => 
          e.jobId == skill.jobId && e.skillId == skill.skillId);
        if (!exists) {
          _jobSkills.add(skill);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding job skills: $e');
      rethrow;
    }
  }

  /// Delete all skills for a job and add new ones
  Future<void> updateJobSkills(String jobId, List<JobSkill> newSkills) async {
    if (_jobSkillBox == null) await init();

    try {
      // 1. Delete existing skills for job from Supabase
      await _supabase
          .from('job_skills')
          .delete()
          .eq('jobId', jobId);

      // 2. Insert new skills
      if (newSkills.isNotEmpty) {
        final data = newSkills.map((s) => s.toMap()).toList();
        await _supabase
            .from('job_skills')
            .insert(data);
      }

      // 3. Update Hive cache
      // Remove old entries
      final keysToRemove = _jobSkillBox!.keys.where((key) => 
        key.toString().startsWith('${jobId}_'));
      for (final key in keysToRemove) {
        await _jobSkillBox!.delete(key);
      }
      
      // Add new entries
      for (final skill in newSkills) {
        final key = '${skill.jobId}_${skill.skillId}';
        await _jobSkillBox!.put(key, skill.toMap());
      }

      // 4. Update local state
      _jobSkills.removeWhere((e) => e.jobId == jobId);
      _jobSkills.addAll(newSkills);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating job skills: $e');
      rethrow;
    }
  }

  Future<void> deleteJobSkill(String jobId, String skillId) async {
    if (_jobSkillBox == null) await init();
    
    try {
      // 1. Delete from Supabase
      await _supabase
          .from('job_skills')
          .delete()
          .eq('jobId', jobId)
          .eq('skillId', skillId);

      // 2. Delete from Hive cache
      final key = '${jobId}_$skillId';
      await _jobSkillBox!.delete(key);

      // 3. Update local state
      _jobSkills.removeWhere((e) => e.jobId == jobId && e.skillId == skillId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting job skill: $e');
      rethrow;
    }
  }

  /// Delete all skills for a job
  Future<void> deleteAllSkillsForJob(String jobId) async {
    if (_jobSkillBox == null) await init();

    try {
      // 1. Delete from Supabase
      await _supabase
          .from('job_skills')
          .delete()
          .eq('jobId', jobId);

      // 2. Delete from Hive cache
      final keysToRemove = _jobSkillBox!.keys.where((key) => 
        key.toString().startsWith('${jobId}_'));
      for (final key in keysToRemove) {
        await _jobSkillBox!.delete(key);
      }

      // 3. Update local state
      _jobSkills.removeWhere((e) => e.jobId == jobId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting all job skills: $e');
      rethrow;
    }
  }

  void getAllJobSkills() {
    if (_jobSkillBox == null) return;
    _jobSkills = _jobSkillBox!.values.map((e) =>
      JobSkill.fromMap(Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
    ).toList();
    notifyListeners();
  }

  /// Fetch all job skills from Supabase
  Future<void> fetchAllJobSkillsFromSupabase() async {
    if (_jobSkillBox == null) return;
    
    try {
      final response = await _supabase
          .from('job_skills')
          .select();

      final newJobSkills = (response as List<dynamic>)
          .map((e) => JobSkill.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      // Clear and rebuild cache
      await _jobSkillBox!.clear();
      for (final jobSkill in newJobSkills) {
        final key = '${jobSkill.jobId}_${jobSkill.skillId}';
        await _jobSkillBox!.put(key, jobSkill.toMap());
      }

      // Replace local state atomically
      _jobSkills = newJobSkills;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching job skills from Supabase: $e');
    }
  }

  List<JobSkill> getSkillsForJob(String jobId) {
    return _jobSkills.where((s) => s.jobId == jobId).toList();
  }

  List<JobSkill> getJobsRequiringSkill(String skillId) {
    return _jobSkills.where((s) => s.skillId == skillId).toList();
  }
}
