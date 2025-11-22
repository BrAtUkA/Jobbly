import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project/models/models.dart';

class QuizAttemptProvider with ChangeNotifier {
  Box? _quizAttemptBox;
  List<QuizAttempt> _quizAttempts = [];
  final _supabase = Supabase.instance.client;
  bool _initialized = false;

  List<QuizAttempt> get quizAttempts => _quizAttempts;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    
    if (!Hive.isBoxOpen('quizAttemptsBox')) {
      _quizAttemptBox = await Hive.openBox('quizAttemptsBox');
    } else {
      _quizAttemptBox = Hive.box('quizAttemptsBox');
    }
    await getAllQuizAttempts();
    // Fetch from Supabase (awaited to prevent race conditions)
    await fetchAllQuizAttemptsFromSupabase();
  }

  /// Fetch all quiz attempts from Supabase
  Future<void> fetchAllQuizAttemptsFromSupabase() async {
    try {
      final response = await _supabase
          .from('quiz_attempts')
          .select()
          .order('attemptDate', ascending: false);

      _quizAttempts = (response as List<dynamic>)
          .map((e) => QuizAttempt.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      // Update Hive cache
      await _quizAttemptBox?.clear();
      for (final attempt in _quizAttempts) {
        await _quizAttemptBox?.put(attempt.attemptId, attempt.toMap());
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching quiz attempts from Supabase: $e');
      // Fall back to local cache
      await getAllQuizAttempts();
    }
  }

  /// Add quiz attempt: Supabase first, then Hive cache
  Future<QuizAttempt> addQuizAttempt(Map<String, dynamic> attemptData) async {
    if (_quizAttemptBox == null) await init();
    
    try {
      // 1. Insert into Supabase
      final response = await _supabase
          .from('quiz_attempts')
          .insert(attemptData)
          .select()
          .single();

      final attempt = QuizAttempt.fromMap(Map<String, dynamic>.from(response));

      // 2. Cache in Hive
      await _quizAttemptBox!.put(attempt.attemptId, attempt.toMap());

      // 3. Update local state
      _quizAttempts.add(attempt);
      _quizAttempts.sort((a, b) => b.attemptDate.compareTo(a.attemptDate));
      notifyListeners();

      return attempt;
    } catch (e) {
      debugPrint('Error adding quiz attempt: $e');
      rethrow;
    }
  }

  Future<void> updateQuizAttempt(QuizAttempt quizAttempt) async {
    if (_quizAttemptBox == null) await init();
    
    try {
      // 1. Update in Supabase
      await _supabase
          .from('quiz_attempts')
          .update(quizAttempt.toMap())
          .eq('attemptId', quizAttempt.attemptId);

      // 2. Update Hive cache
      await _quizAttemptBox!.put(quizAttempt.attemptId, quizAttempt.toMap());
      
      // 3. Update local state
      final index = _quizAttempts.indexWhere((e) => e.attemptId == quizAttempt.attemptId);
      if (index != -1) {
        _quizAttempts[index] = quizAttempt;
      } else {
        _quizAttempts.add(quizAttempt);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating quiz attempt: $e');
      rethrow;
    }
  }

  Future<void> deleteQuizAttempt(String attemptId) async {
    if (_quizAttemptBox == null) await init();
    
    try {
      // 1. Delete from Supabase
      await _supabase
          .from('quiz_attempts')
          .delete()
          .eq('attemptId', attemptId);

      // 2. Delete from Hive
      await _quizAttemptBox!.delete(attemptId);
      
      // 3. Update local state
      _quizAttempts.removeWhere((e) => e.attemptId == attemptId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting quiz attempt: $e');
      rethrow;
    }
  }

  Future<void> getAllQuizAttempts() async {
    if (_quizAttemptBox == null) return;
    _quizAttempts = _quizAttemptBox!.values.map((e) =>
      QuizAttempt.fromMap(Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
    ).toList();
    // Sort by attempt date descending
    _quizAttempts.sort((a, b) => b.attemptDate.compareTo(a.attemptDate));
    notifyListeners();
  }

  QuizAttempt? getQuizAttemptById(String attemptId) {
    try {
      return _quizAttempts.firstWhere((q) => q.attemptId == attemptId);
    } catch (e) {
      return null;
    }
  }

  List<QuizAttempt> getAttemptsForSeeker(String seekerId) {
    return _quizAttempts.where((q) => q.seekerId == seekerId).toList();
  }

  List<QuizAttempt> getAttemptsForQuiz(String quizId) {
    return _quizAttempts.where((q) => q.quizId == quizId).toList();
  }

  List<QuizAttempt> getPassedAttemptsForSeeker(String seekerId) {
    return _quizAttempts.where((q) => q.seekerId == seekerId && q.isPassed).toList();
  }
}
