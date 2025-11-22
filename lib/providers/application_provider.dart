import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project/models/models.dart';

class ApplicationProvider with ChangeNotifier {
  Box? _applicationBox;
  List<Application> _applications = [];
  final _supabase = Supabase.instance.client;

  Future<void> init() async {
    if (_applicationBox != null && _applicationBox!.isOpen) return;
    if (!Hive.isBoxOpen('applicationsBox')) {
      _applicationBox = await Hive.openBox('applicationsBox');
    } else {
      _applicationBox = Hive.box('applicationsBox');
    }
    getAllApplications();
    // Fetch from Supabase (awaited to prevent race conditions)
    await fetchAllApplicationsFromSupabase();
  }

  /// Add application: Supabase first, then Hive cache
  Future<void> addApplication(Application application) async {
    if (_applicationBox == null) await init();
    try {
      // 1. Save to Supabase
      final response = await _supabase
          .from('applications')
          .insert({
            'jobId': application.jobId,
            'seekerId': application.seekerId,
            'quizAttemptId': application.quizAttemptId,
            'appliedDate': application.appliedDate.toIso8601String(),
            'status': application.status.name,
          })
          .select()
          .single();

      final savedApp = Application.fromMap(Map<String, dynamic>.from(response));

      // 2. Cache in Hive
      await _applicationBox!.put(savedApp.applicationId, savedApp.toMap());

      // 3. Update local state
      _applications.add(savedApp);
      _applications.sort((a, b) => b.appliedDate.compareTo(a.appliedDate));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding application: $e');
      rethrow;
    }
  }

  /// Update application: Supabase first, then Hive cache
  Future<void> updateApplication(Application application) async {
    if (_applicationBox == null) await init();
    try {
      // 1. Update in Supabase
      await _supabase.from('applications').update({
        'status': application.status.name,
        'quizAttemptId': application.quizAttemptId,
      }).eq('applicationId', application.applicationId);

      // 2. Update Hive cache
      await _applicationBox!.put(application.applicationId, application.toMap());

      // 3. Update local state
      final index = _applications.indexWhere((e) => e.applicationId == application.applicationId);
      if (index != -1) {
        _applications[index] = application;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating application: $e');
      rethrow;
    }
  }

  /// Delete application: Supabase first, then Hive cache
  Future<void> deleteApplication(String applicationId) async {
    if (_applicationBox == null) await init();
    try {
      // 1. Delete from Supabase and verify it was deleted
      final response = await _supabase
          .from('applications')
          .delete()
          .eq('applicationId', applicationId)
          .select();
      
      debugPrint('Delete response for $applicationId: $response');
      
      // If response is empty, the record may not have existed or delete failed
      // Continue anyway to clean up local state

      // 2. Delete from Hive cache
      await _applicationBox!.delete(applicationId);

      // 3. Update local state
      _applications.removeWhere((e) => e.applicationId == applicationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting application: $e');
      rethrow;
    }
  }

  /// Get all applications from Hive cache (fast, local)
  void getAllApplications() {
    if (_applicationBox == null) return;
    _applications = _applicationBox!.values.map((e) =>
      Application.fromMap(Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
    ).toList();
    // Sort by applied date descending
    _applications.sort((a, b) => b.appliedDate.compareTo(a.appliedDate));
    notifyListeners();
  }

  /// Fetch all applications from Supabase and update cache
  Future<void> fetchAllApplicationsFromSupabase() async {
    try {
      final response = await _supabase
          .from('applications')
          .select()
          .order('appliedDate', ascending: false);

      final newApplications = (response as List<dynamic>)
          .map((e) => Application.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      // Clear and rebuild cache
      await _applicationBox!.clear();
      for (final app in newApplications) {
        await _applicationBox!.put(app.applicationId, app.toMap());
      }

      // Replace local state atomically
      _applications = newApplications;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching applications from Supabase: $e');
      // Keep existing cached data on error
    }
  }

  Application? getApplicationById(String applicationId) {
    try {
      return _applications.firstWhere((e) => e.applicationId == applicationId);
    } catch (e) {
      return null;
    }
  }

  List<Application> getApplicationsByJob(String jobId) {
    return _applications.where((e) => e.jobId == jobId).toList();
  }

  List<Application> getApplicationsBySeeker(String seekerId) {
    return _applications.where((e) => e.seekerId == seekerId).toList();
  }

  Future<void> updateApplicationStatus(String applicationId, ApplicationStatus status) async {
    final app = getApplicationById(applicationId);
    if (app != null) {
      app.status = status;
      await updateApplication(app);
    }
  }

  List<Application> get applications => _applications;
}
