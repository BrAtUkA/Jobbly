import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project/models/models.dart';

/// SeekerProvider - Supabase-first with Hive caching
/// 
/// Write: Supabase (cloud) → Hive (local cache)
/// Read: Hive (fast) → Fallback to Supabase if missing
class SeekerProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  Box? _seekerBox;
  List<Seeker> _seekers = [];

  List<Seeker> get seekers => _seekers;

  Future<void> init() async {
    if (_seekerBox != null && _seekerBox!.isOpen) return;
    if (!Hive.isBoxOpen('seekersBox')) {
      _seekerBox = await Hive.openBox('seekersBox');
    } else {
      _seekerBox = Hive.box('seekersBox');
    }
    await getAllSeekers();
  }

  /// Add a new seeker - saves to Supabase first, then caches in Hive
  Future<void> addSeeker(Seeker seeker) async {
    if (_seekerBox == null) await init();
    
    try {
      // 1. Save to Supabase (source of truth)
      await _supabase.from('seekers').insert({
        'seekerId': seeker.seekerId,
        'fullName': seeker.fullName,
        'pfp': seeker.pfp,
        'resumeUrl': seeker.resumeUrl,
        'experience': seeker.experience,
        'education': seeker.education.name,
        'phone': seeker.phone,
        'location': seeker.location,
        'email': seeker.email,
        'createdAt': seeker.createdAt.toIso8601String(),
      });
      
      // 2. Cache in Hive
      await _seekerBox!.put(seeker.userId, seeker.toMap());
      _seekers.add(seeker);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding seeker to Supabase: $e');
      rethrow;
    }
  }

  /// Update seeker - saves to Supabase first, then updates Hive cache
  Future<void> updateSeeker(Seeker seeker) async {
    if (_seekerBox == null) await init();
    
    try {
      // 1. Update in Supabase (source of truth)
      await _supabase.from('seekers').update({
        'fullName': seeker.fullName,
        'pfp': seeker.pfp,
        'resumeUrl': seeker.resumeUrl,
        'experience': seeker.experience,
        'education': seeker.education.name,
        'phone': seeker.phone,
        'location': seeker.location,
      }).eq('seekerId', seeker.seekerId);
      
      // 2. Update Hive cache
      await _seekerBox!.put(seeker.userId, seeker.toMap());
      
      final index = _seekers.indexWhere((e) => e.userId == seeker.userId);
      if (index != -1) {
        _seekers[index] = seeker;
      } else {
        _seekers.add(seeker);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating seeker in Supabase: $e');
      rethrow;
    }
  }

  /// Delete seeker - removes from Supabase first, then from Hive cache
  Future<void> deleteSeeker(String userId) async {
    if (_seekerBox == null) await init();
    
    try {
      // 1. Delete from Supabase
      await _supabase.from('seekers').delete().eq('seekerId', userId);
      
      // 2. Remove from Hive cache
      await _seekerBox!.delete(userId);
      _seekers.removeWhere((e) => e.userId == userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting seeker from Supabase: $e');
      rethrow;
    }
  }

  /// Get all seekers from Hive cache
  Future<void> getAllSeekers() async {
    if (_seekerBox == null) return;
    _seekers = _seekerBox!.values.map((e) =>
      Seeker.fromMap(Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
    ).toList();
    notifyListeners();
  }

  /// Fetch all seekers from Supabase and refresh Hive cache
  Future<void> fetchAllSeekersFromSupabase() async {
    if (_seekerBox == null) await init();
    
    try {
      final response = await _supabase.from('seekers').select();
      
      _seekers = [];
      for (final data in response) {
        final map = Map<String, dynamic>.from(data);
        // Add fields needed for local model
        map['userId'] = map['seekerId'];
        map['password'] = 'secured_by_supabase';
        map['userType'] = UserType.seeker.name;
        
        final seeker = Seeker.fromMap(map);
        _seekers.add(seeker);
        
        // Update Hive cache
        await _seekerBox!.put(seeker.userId, seeker.toMap());
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching seekers from Supabase: $e');
      // Fall back to Hive cache
      await getAllSeekers();
    }
  }

  /// Get seeker by ID from local cache
  Seeker? getSeekerById(String userId) {
    try {
      return _seekers.firstWhere((s) => s.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Fetch single seeker from Supabase by ID
  Future<Seeker?> fetchSeekerById(String seekerId) async {
    if (_seekerBox == null) await init();
    
    try {
      final response = await _supabase
          .from('seekers')
          .select()
          .eq('seekerId', seekerId)
          .maybeSingle();
      
      if (response == null) return null;
      
      final map = Map<String, dynamic>.from(response);
      map['userId'] = map['seekerId'];
      map['password'] = 'secured_by_supabase';
      map['userType'] = UserType.seeker.name;
      
      final seeker = Seeker.fromMap(map);
      
      // Update Hive cache
      await _seekerBox!.put(seeker.userId, seeker.toMap());
      
      // Update in-memory list
      final index = _seekers.indexWhere((s) => s.userId == seeker.userId);
      if (index != -1) {
        _seekers[index] = seeker;
      } else {
        _seekers.add(seeker);
      }
      notifyListeners();
      
      return seeker;
    } catch (e) {
      debugPrint('Error fetching seeker from Supabase: $e');
      return getSeekerById(seekerId);
    }
  }
}
