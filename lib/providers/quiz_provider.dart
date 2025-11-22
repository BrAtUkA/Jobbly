import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project/models/models.dart';

class QuizProvider with ChangeNotifier {
  Box? _quizBox;
  List<Quiz> _quizzes = [];
  final _supabase = Supabase.instance.client;
  bool _initialized = false;

  List<Quiz> get quizzes => _quizzes;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    
    if (!Hive.isBoxOpen('quizzesBox')) {
      _quizBox = await Hive.openBox('quizzesBox');
    } else {
      _quizBox = Hive.box('quizzesBox');
    }
    getAllQuizzes();
    // Fetch from Supabase (awaited to prevent race conditions)
    await fetchAllQuizzesFromSupabase();
  }

  /// Add quiz: Supabase first (quiz + questions), then Hive cache
  Future<Quiz> addQuiz(Quiz quiz) async {
    if (_quizBox == null) await init();
    
    try {
      // 1. Prepare quiz data for Supabase (without questions - they go in separate table)
      final quizData = {
        'jobId': quiz.jobId,
        'companyId': quiz.companyId,
        'title': quiz.title,
        'duration': quiz.duration,
        'passingScore': quiz.passingScore,
        'createdDate': quiz.createdDate.toIso8601String(),
      };

      // 2. Insert quiz and get back the generated quizId
      final quizResponse = await _supabase
          .from('quizzes')
          .insert(quizData)
          .select()
          .single();

      final quizId = quizResponse['quizId'] as String;

      // 3. Insert questions with the quiz ID
      if (quiz.questions.isNotEmpty) {
        final questionsData = quiz.questions.map((q) => {
          'quizId': quizId,
          'questionText': q.questionText,
          'optionA': q.optionA,
          'optionB': q.optionB,
          'optionC': q.optionC,
          'optionD': q.optionD,
          'correctAnswer': q.correctAnswer,
        }).toList();

        final questionsResponse = await _supabase
            .from('questions')
            .insert(questionsData)
            .select();

        // Update question IDs from response
        final questions = (questionsResponse as List<dynamic>).map((q) =>
          Question.fromMap(Map<String, dynamic>.from(q))
        ).toList();

        quiz.quizId = quizId;
        quiz.questions = questions;
      } else {
        quiz.quizId = quizId;
      }

      // 4. Cache in Hive
      await _quizBox!.put(quiz.quizId, quiz.toMap());

      // 5. Update local state
      _quizzes.add(quiz);
      _quizzes.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      notifyListeners();

      return quiz;
    } catch (e) {
      debugPrint('Error adding quiz: $e');
      rethrow;
    }
  }

  /// Update quiz: Supabase first, then Hive cache
  Future<void> updateQuiz(Quiz quiz) async {
    if (_quizBox == null) await init();
    
    try {
      // 1. Update quiz in Supabase
      final quizData = {
        'title': quiz.title,
        'duration': quiz.duration,
        'passingScore': quiz.passingScore,
      };

      await _supabase
          .from('quizzes')
          .update(quizData)
          .eq('quizId', quiz.quizId);

      // 2. Delete existing questions and re-insert
      await _supabase
          .from('questions')
          .delete()
          .eq('quizId', quiz.quizId);

      if (quiz.questions.isNotEmpty) {
        final questionsData = quiz.questions.map((q) => {
          'quizId': quiz.quizId,
          'questionText': q.questionText,
          'optionA': q.optionA,
          'optionB': q.optionB,
          'optionC': q.optionC,
          'optionD': q.optionD,
          'correctAnswer': q.correctAnswer,
        }).toList();

        final questionsResponse = await _supabase
            .from('questions')
            .insert(questionsData)
            .select();

        quiz.questions = (questionsResponse as List<dynamic>).map((q) =>
          Question.fromMap(Map<String, dynamic>.from(q))
        ).toList();
      }

      // 3. Update Hive cache
      await _quizBox!.put(quiz.quizId, quiz.toMap());

      // 4. Update local state
      final index = _quizzes.indexWhere((e) => e.quizId == quiz.quizId);
      if (index != -1) {
        _quizzes[index] = quiz;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating quiz: $e');
      rethrow;
    }
  }

  /// Delete quiz: Supabase first, then Hive cache
  Future<void> deleteQuiz(String quizId) async {
    if (_quizBox == null) await init();
    
    try {
      // 1. Delete from Supabase (cascade will delete questions)
      await _supabase
          .from('quizzes')
          .delete()
          .eq('quizId', quizId);

      // 2. Delete from Hive cache
      await _quizBox!.delete(quizId);

      // 3. Update local state
      _quizzes.removeWhere((e) => e.quizId == quizId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting quiz: $e');
      rethrow;
    }
  }

  /// Get all quizzes from Hive cache (fast, local)
  void getAllQuizzes() {
    if (_quizBox == null) return;
    _quizzes = _quizBox!.values.map((e) =>
      Quiz.fromMap(Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
    ).toList();
    _quizzes.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    notifyListeners();
  }

  /// Fetch all quizzes from Supabase with their questions
  Future<void> fetchAllQuizzesFromSupabase() async {
    if (_quizBox == null) return;
    
    try {
      // Fetch quizzes
      final quizzesResponse = await _supabase
          .from('quizzes')
          .select()
          .order('createdDate', ascending: false);

      final newQuizzes = <Quiz>[];
      
      for (var quizData in quizzesResponse as List<dynamic>) {
        final quizId = quizData['quizId'];
        
        // Fetch questions for this quiz
        final questionsResponse = await _supabase
            .from('questions')
            .select()
            .eq('quizId', quizId);

        final questions = (questionsResponse as List<dynamic>).map((q) =>
          Question.fromMap(Map<String, dynamic>.from(q))
        ).toList();

        // Create quiz with embedded questions
        final quizMap = Map<String, dynamic>.from(quizData);
        quizMap['questions'] = questions.map((q) => q.toMap()).toList();

        final quiz = Quiz.fromMap(quizMap);
        newQuizzes.add(quiz);
      }

      // Clear and rebuild cache
      await _quizBox!.clear();
      for (final quiz in newQuizzes) {
        await _quizBox!.put(quiz.quizId, quiz.toMap());
      }

      // Replace local state atomically
      _quizzes = newQuizzes;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching quizzes from Supabase: $e');
      // Keep existing cached data on error
    }
  }

  /// Fetch quizzes for a specific company from Supabase
  Future<void> fetchQuizzesByCompany(String companyId) async {
    try {
      final quizzesResponse = await _supabase
          .from('quizzes')
          .select()
          .eq('companyId', companyId)
          .order('createdDate', ascending: false);

      for (var quizData in quizzesResponse as List<dynamic>) {
        final quizId = quizData['quizId'];
        
        final questionsResponse = await _supabase
            .from('questions')
            .select()
            .eq('quizId', quizId);

        final questions = (questionsResponse as List<dynamic>).map((q) =>
          Question.fromMap(Map<String, dynamic>.from(q))
        ).toList();

        final quizMap = Map<String, dynamic>.from(quizData);
        quizMap['questions'] = questions.map((q) => q.toMap()).toList();

        final quiz = Quiz.fromMap(quizMap);
        await _quizBox!.put(quiz.quizId, quiz.toMap());

        // Update or add to local state
        final index = _quizzes.indexWhere((e) => e.quizId == quiz.quizId);
        if (index != -1) {
          _quizzes[index] = quiz;
        } else {
          _quizzes.add(quiz);
        }
      }

      _quizzes.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching company quizzes: $e');
    }
  }

  Quiz? getQuizById(String quizId) {
    try {
      return _quizzes.firstWhere((q) => q.quizId == quizId);
    } catch (e) {
      return null;
    }
  }

  List<Quiz> getQuizzesByJob(String jobId) {
    return _quizzes.where((q) => q.jobId == jobId).toList();
  }

  List<Quiz> getQuizzesByCompany(String companyId) {
    return _quizzes.where((q) => q.companyId == companyId).toList();
  }

  /// Check if a job has any quiz attached
  bool jobHasQuiz(String jobId) {
    return _quizzes.any((q) => q.jobId == jobId);
  }

  /// Get the first quiz for a job (most jobs will have one quiz)
  Quiz? getQuizForJob(String jobId) {
    try {
      return _quizzes.firstWhere((q) => q.jobId == jobId);
    } catch (e) {
      return null;
    }
  }
}
