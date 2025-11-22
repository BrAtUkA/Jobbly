import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project/models/models.dart';

class JobProvider with ChangeNotifier {
  Box? _jobBox;
  List<Job> _jobs = [];
  final _supabase = Supabase.instance.client;

  Future<void> init() async {
    if (_jobBox != null && _jobBox!.isOpen) return;
    if (!Hive.isBoxOpen('jobsBox')) {
      _jobBox = await Hive.openBox('jobsBox');
    } else {
      _jobBox = Hive.box('jobsBox');
    }
    // Load from cache first for fast UI
    getAllJobs();
    // Then sync with Supabase (awaited to prevent race conditions)
    await fetchAllJobsFromSupabase();
  }

  /// Add job: Supabase first, then Hive cache
  /// Returns the created Job with generated jobId
  Future<Job> addJob(Map<String, dynamic> jobData) async {
    if (_jobBox == null) await init();
    try {
      // 1. Save to Supabase (returns the created job with UUID)
      final response = await _supabase
          .from('jobs')
          .insert(jobData)
          .select()
          .single();
      
      final job = Job.fromMap(Map<String, dynamic>.from(response));
      
      // 2. Cache in Hive
      await _jobBox!.put(job.jobId, job.toMap());
      
      // 3. Update local state
      _jobs.add(job);
      _jobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));
      notifyListeners();
      
      return job;
    } catch (e) {
      debugPrint('Error adding job: $e');
      rethrow;
    }
  }

  /// Update job: Supabase first, then Hive cache
  Future<void> updateJob(Job job) async {
    if (_jobBox == null) await init();
    try {
      // 1. Update in Supabase
      await _supabase
          .from('jobs')
          .update(job.toMap())
          .eq('jobId', job.jobId);
      
      // 2. Update Hive cache
      await _jobBox!.put(job.jobId, job.toMap());
      
      // 3. Update local state
      final index = _jobs.indexWhere((e) => e.jobId == job.jobId);
      if (index != -1) {
        _jobs[index] = job;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating job: $e');
      rethrow;
    }
  }

  /// Delete job: Supabase first, then Hive cache
  Future<void> deleteJob(String jobId) async {
    if (_jobBox == null) await init();
    try {
      // 1. Delete from Supabase
      await _supabase
          .from('jobs')
          .delete()
          .eq('jobId', jobId);
      
      // 2. Delete from Hive cache
      await _jobBox!.delete(jobId);
      
      // 3. Update local state
      _jobs.removeWhere((e) => e.jobId == jobId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting job: $e');
      rethrow;
    }
  }

  /// Get all jobs from Hive cache (fast, local)
  void getAllJobs() {
    if (_jobBox == null) return;
    _jobs = _jobBox!.values.map((e) =>
      Job.fromMap(Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
    ).toList();
    // Sort by posted date descending (newest first)
    _jobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));
    notifyListeners();
  }

  /// Fetch all jobs from Supabase and update cache (background sync)
  Future<void> fetchAllJobsFromSupabase() async {
    try {
      final response = await _supabase
          .from('jobs')
          .select()
          .order('postedDate', ascending: false);
      
      final newJobs = (response as List<dynamic>)
          .map((e) => Job.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      
      // Clear and rebuild cache
      await _jobBox!.clear();
      for (final job in newJobs) {
        await _jobBox!.put(job.jobId, job.toMap());
      }
      
      // Replace local state atomically
      _jobs = newJobs;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching jobs from Supabase: $e');
      // Keep existing cached data on error
    }
  }

  /// Fetch single job by ID from Supabase
  Future<Job?> fetchJobById(String jobId) async {
    try {
      final response = await _supabase
          .from('jobs')
          .select()
          .eq('jobId', jobId)
          .maybeSingle();
      
      if (response != null) {
        final job = Job.fromMap(Map<String, dynamic>.from(response));
        
        // Update cache
        await _jobBox!.put(job.jobId, job.toMap());
        
        // Update local state if exists
        final index = _jobs.indexWhere((e) => e.jobId == jobId);
        if (index != -1) {
          _jobs[index] = job;
        } else {
          _jobs.add(job);
          _jobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));
        }
        notifyListeners();
        
        return job;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching job by ID: $e');
      // Fallback to cached version
      return getJobById(jobId);
    }
  }

  /// Get job from local cache (no network call)
  Job? getJobById(String jobId) {
    try {
      return _jobs.firstWhere((e) => e.jobId == jobId);
    } catch (e) {
      return null;
    }
  }

  /// Get jobs by company from local cache
  List<Job> getJobsByCompany(String companyId) {
    return _jobs.where((e) => e.companyId == companyId).toList();
  }

  /// Get active jobs only
  List<Job> get activeJobs => _jobs.where((e) => e.status == JobStatus.active).toList();

  /// Get all jobs
  List<Job> get jobs => _jobs;
}

