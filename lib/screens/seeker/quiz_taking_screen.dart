import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:project/providers/providers.dart';
import 'package:project/models/models.dart';
import 'package:project/theme/app_theme.dart';
import 'package:project/widgets/primary_button.dart';

class QuizTakingScreen extends StatefulWidget {
  final Quiz quiz;
  final Job job;

  const QuizTakingScreen({
    super.key,
    required this.quiz,
    required this.job,
  });

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, String> _answers = {}; // questionIndex -> selected answer (A, B, C, D)
  late int _remainingSeconds;
  Timer? _timer;
  bool _isSubmitting = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.quiz.duration * 60; // Convert minutes to seconds
    _startTime = DateTime.now();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        _submitQuiz(autoSubmit: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final questions = widget.quiz.questions;
    final currentQuestion = questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / questions.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitConfirmation(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.black87),
            onPressed: () => _showExitConfirmation(context),
          ),
          title: Text(
            widget.quiz.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            // Timer
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getTimerColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_rounded,
                    size: 18,
                    color: _getTimerColor(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getTimerColor(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question counter
                    Text(
                      'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(duration: 300.ms),

                    const SizedBox(height: 16),

                    // Question card
                    _buildQuestionCard(theme, currentQuestion)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: 0.05, end: 0),

                    const SizedBox(height: 24),

                    // Options
                    ...['A', 'B', 'C', 'D'].asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      final optionText = _getOptionText(currentQuestion, option);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildOptionCard(theme, option, optionText)
                            .animate()
                            .fadeIn(duration: 300.ms, delay: (100 * index).ms)
                            .slideX(begin: 0.05, end: 0),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Question navigation dots
                    _buildQuestionDots(theme, questions.length),
                  ],
                ),
              ),
            ),

            // Bottom navigation
            _buildBottomNavigation(theme, questions.length),
          ],
        ),
      ),
    );
  }

  Color _getTimerColor() {
    final totalSeconds = widget.quiz.duration * 60;
    final percentRemaining = _remainingSeconds / totalSeconds;
    
    if (percentRemaining <= 0.1) return AppTheme.errorColor;
    if (percentRemaining <= 0.25) return AppTheme.accentColor;
    return AppTheme.secondaryColor;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSecs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSecs.toString().padLeft(2, '0')}';
  }

  Widget _buildQuestionCard(ThemeData theme, Question question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        question.questionText,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
      ),
    );
  }

  String _getOptionText(Question question, String option) {
    switch (option) {
      case 'A':
        return question.optionA;
      case 'B':
        return question.optionB;
      case 'C':
        return question.optionC;
      case 'D':
        return question.optionD;
      default:
        return '';
    }
  }

  Widget _buildOptionCard(ThemeData theme, String option, String text) {
    final isSelected = _answers[_currentQuestionIndex] == option;
    
    return Material(
      color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => setState(() => _answers[_currentQuestionIndex] = option),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.primaryColor 
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    option,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionDots(ThemeData theme, int totalQuestions) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(totalQuestions, (index) {
        final isAnswered = _answers.containsKey(index);
        final isCurrent = index == _currentQuestionIndex;
        
        return GestureDetector(
          onTap: () => setState(() => _currentQuestionIndex = index),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCurrent 
                  ? AppTheme.primaryColor 
                  : isAnswered 
                      ? AppTheme.secondaryColor.withValues(alpha: 0.2)
                      : Colors.grey.shade200,
              shape: BoxShape.circle,
              border: isCurrent 
                  ? null 
                  : Border.all(
                      color: isAnswered 
                          ? AppTheme.secondaryColor 
                          : Colors.grey.shade300,
                    ),
            ),
            child: Center(
              child: isAnswered && !isCurrent
                  ? Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppTheme.secondaryColor,
                    )
                  : Text(
                      '${index + 1}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isCurrent ? Colors.white : AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBottomNavigation(ThemeData theme, int totalQuestions) {
    final isFirstQuestion = _currentQuestionIndex == 0;
    final isLastQuestion = _currentQuestionIndex == totalQuestions - 1;
    final answeredCount = _answers.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress text
            Text(
              '$answeredCount of $totalQuestions answered',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Previous button
                Expanded(
                  child: OutlinedButton(
                    onPressed: isFirstQuestion 
                        ? null 
                        : () => setState(() => _currentQuestionIndex--),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 12),
                // Next/Submit button
                Expanded(
                  flex: 2,
                  child: isLastQuestion
                      ? PrimaryButton(
                          text: 'Submit Quiz',
                          onPressed: _isSubmitting ? null : () => _submitQuiz(),
                          isLoading: _isSubmitting,
                        )
                      : ElevatedButton(
                          onPressed: () => setState(() => _currentQuestionIndex++),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Next'),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Exit Quiz?'),
        content: const Text(
          'Your progress will be lost and you won\'t be able to apply for this job without completing the quiz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Quiz'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit quiz
            },
            child: Text(
              'Exit',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitQuiz({bool autoSubmit = false}) async {
    if (autoSubmit) {
      // Show time's up dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Time\'s up! Submitting your answers...'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }

    // Check if all questions are answered
    final unansweredCount = widget.quiz.questions.length - _answers.length;
    if (!autoSubmit && unansweredCount > 0) {
      final shouldSubmit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Submit Quiz?'),
          content: Text(
            'You have $unansweredCount unanswered question${unansweredCount > 1 ? 's' : ''}. '
            'Unanswered questions will be marked as incorrect.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Review Answers'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Submit Anyway'),
            ),
          ],
        ),
      );

      if (shouldSubmit != true) return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Calculate score
      int correctAnswers = 0;
      for (int i = 0; i < widget.quiz.questions.length; i++) {
        final question = widget.quiz.questions[i];
        if (_answers[i] == question.correctAnswer) {
          correctAnswers++;
        }
      }

      final score = ((correctAnswers / widget.quiz.questions.length) * 100).round();
      final isPassed = score >= widget.quiz.passingScore;
      final timeTaken = _startTime != null 
          ? DateTime.now().difference(_startTime!).inMinutes 
          : widget.quiz.duration;

      // Get current user
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;
      if (user is! Seeker) throw Exception('User not found');

      // Create quiz attempt
      final attemptData = {
        'quizId': widget.quiz.quizId,
        'seekerId': user.seekerId,
        'score': score,
        'attemptDate': DateTime.now().toIso8601String(),
        'isPassed': isPassed,
        'timeTaken': timeTaken,
      };

      if (!mounted) return;
      final attempt = await context.read<QuizAttemptProvider>().addQuizAttempt(attemptData);

      // Show results
      if (mounted) {
        await _showResultDialog(score, isPassed, correctAnswers);
        
        // Return the attempt to the job detail screen
        if (mounted) {
          Navigator.pop(context, attempt);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting quiz: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _showResultDialog(int score, bool isPassed, int correctAnswers) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isPassed 
                    ? AppTheme.secondaryColor.withValues(alpha: 0.1)
                    : AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 48,
                color: isPassed ? AppTheme.secondaryColor : AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isPassed ? 'Congratulations!' : 'Quiz Completed',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPassed 
                  ? 'You passed the assessment!'
                  : 'Unfortunately, you didn\'t pass.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Score display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildResultStat('Score', '$score%', isPassed ? AppTheme.secondaryColor : AppTheme.errorColor),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  _buildResultStat('Correct', '$correctAnswers/${widget.quiz.questions.length}', AppTheme.primaryColor),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  _buildResultStat('Passing', '${widget.quiz.passingScore}%', AppTheme.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPassed ? AppTheme.secondaryColor : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(isPassed ? 'Continue to Apply' : 'Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
