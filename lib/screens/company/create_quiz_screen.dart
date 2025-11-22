import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:project/providers/providers.dart';
import 'package:project/models/models.dart';
import 'package:project/widgets/primary_button.dart';
import 'package:project/widgets/question_editor_card.dart';

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _passingScoreController = TextEditingController(text: '60');

  // State
  int _currentStep = 0;
  bool _isForward = true;
  bool _isLoading = false;
  final List<Question> _questions = [];
  int? _expandedQuestionIndex;

  // Edit mode
  Quiz? _editingQuiz;
  bool get _isEditMode => _editingQuiz != null;

  // Job reference (passed as argument)
  Job? _linkedJob;

  static const int _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        if (args['quiz'] is Quiz) {
          _initEditMode(args['quiz'] as Quiz);
        }
        if (args['job'] is Job) {
          _linkedJob = args['job'] as Job;
        }
      } else if (args is Job) {
        _linkedJob = args;
      } else if (args is Quiz) {
        _initEditMode(args);
      }
    });
  }

  void _initEditMode(Quiz quiz) {
    setState(() {
      _editingQuiz = quiz;
      _titleController.text = quiz.title;
      _durationController.text = quiz.duration.toString();
      _passingScoreController.text = quiz.passingScore.toString();
      _questions.clear();
      _questions.addAll(quiz.questions);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _passingScoreController.dispose();
    super.dispose();
  }

  bool get _isStep1Valid {
    return _titleController.text.trim().length >= 3 &&
        _durationController.text.trim().isNotEmpty &&
        _passingScoreController.text.trim().isNotEmpty &&
        (int.tryParse(_durationController.text) ?? 0) > 0 &&
        (int.tryParse(_passingScoreController.text) ?? 0) >= 0 &&
        (int.tryParse(_passingScoreController.text) ?? 101) <= 100;
  }

  bool get _isStep2Valid {
    return _questions.isNotEmpty && _questions.every(_isQuestionComplete);
  }

  bool _isQuestionComplete(Question q) {
    return q.questionText.isNotEmpty &&
        q.optionA.isNotEmpty &&
        q.optionB.isNotEmpty &&
        q.optionC.isNotEmpty &&
        q.optionD.isNotEmpty;
  }

  void _nextStep() {
    if (_currentStep == 0 && !_isStep1Valid) {
      _showSnackBar('Please fill in all fields correctly');
      return;
    }
    if (_currentStep == 1 && !_isStep2Valid) {
      _showSnackBar('Please add at least one complete question');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isForward = true;
      _currentStep++;
      _expandedQuestionIndex = null;
    });
  }

  void _previousStep() {
    if (_currentStep == 0) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isForward = false;
      _currentStep--;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _addQuestion() {
    setState(() {
      _questions.add(Question(
        questionId: DateTime.now().millisecondsSinceEpoch.toString(),
        questionText: '',
        optionA: '',
        optionB: '',
        optionC: '',
        optionD: '',
        correctAnswer: 'A',
      ));
      _expandedQuestionIndex = _questions.length - 1;
    });
  }

  void _updateQuestion(int index, Question question) {
    setState(() {
      _questions[index] = question;
    });
  }

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
      if (_expandedQuestionIndex == index) {
        _expandedQuestionIndex = null;
      } else if (_expandedQuestionIndex != null && _expandedQuestionIndex! > index) {
        _expandedQuestionIndex = _expandedQuestionIndex! - 1;
      }
    });
  }

  Future<void> _saveQuiz() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final quizProvider = context.read<QuizProvider>();
      final user = authProvider.currentUser;

      if (user == null || user is! Company) {
        throw Exception('Invalid user state');
      }

      final duration = int.tryParse(_durationController.text) ?? 30;
      final passingScore = int.tryParse(_passingScoreController.text) ?? 60;

      if (_isEditMode) {
        // Update existing quiz
        _editingQuiz!.title = _titleController.text.trim();
        _editingQuiz!.duration = duration;
        _editingQuiz!.passingScore = passingScore;
        _editingQuiz!.questions = _questions;

        await quizProvider.updateQuiz(_editingQuiz!);

        if (mounted) {
          Navigator.pop(context, _editingQuiz);
          _showSnackBar('Quiz updated successfully!');
        }
      } else {
        // Validate that we have a job to link the quiz to
        if (_linkedJob == null) {
          throw Exception('No job selected. Please create the quiz from a job listing.');
        }
        
        // Create new quiz
        final quiz = Quiz(
          quizId: '', // Will be set by Supabase
          jobId: _linkedJob!.jobId,
          companyId: user.companyId,
          title: _titleController.text.trim(),
          duration: duration,
          passingScore: passingScore,
          createdDate: DateTime.now(),
          questions: _questions,
        );

        await quizProvider.addQuiz(quiz);

        if (mounted) {
          Navigator.pop(context, quiz);
          _showSnackBar('Quiz created successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error ${_isEditMode ? 'updating' : 'creating'} quiz: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? 'Edit Quiz' : 'Create Quiz',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_linkedJob != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                avatar: Icon(Icons.work_outline, size: 16, color: theme.primaryColor),
                label: Text(
                  _linkedJob!.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor,
                  ),
                ),
                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                side: BorderSide.none,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressHeader(theme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: _buildSlideTransition,
                    child: _buildCurrentStep(theme),
                  ),
                ),
              ),
            ),
            _buildBottomNav(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isCompleted || isCurrent
                        ? theme.primaryColor
                        : Colors.grey.shade200,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            _getStepTitle(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05, end: 0),
          const SizedBox(height: 4),
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ).animate().fadeIn(delay: 150.ms),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Quiz Details';
      case 1:
        return 'Add Questions';
      case 2:
        return 'Review & Save';
      default:
        return '';
    }
  }

  Widget _buildSlideTransition(Widget child, Animation<double> animation) {
    final offsetAnimation = Tween<Offset>(
      begin: _isForward ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    return SlideTransition(
      position: offsetAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }

  Widget _buildCurrentStep(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildStep1QuizDetails(theme);
      case 1:
        return _buildStep2Questions(theme);
      case 2:
        return _buildStep3Review(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1QuizDetails(ThemeData theme) {
    return Container(
      key: const ValueKey(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Quiz Title
          Text(
            'Quiz Title',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'e.g., Flutter Developer Assessment',
              prefixIcon: Icon(Icons.quiz_outlined, size: 20),
            ),
          ),

          const SizedBox(height: 24),

          // Duration
          Text(
            'Time Limit (minutes)',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'e.g., 30',
              prefixIcon: Icon(Icons.timer_outlined, size: 20),
              suffixText: 'min',
            ),
          ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Candidates will have this time to complete all questions',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Passing Score
          Text(
            'Passing Score (%)',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passingScoreController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'e.g., 60',
              prefixIcon: Icon(Icons.percent_outlined, size: 20),
              suffixText: '%',
            ),
          ),

          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: _passingScoreController,
            builder: (context, _) {
              final score = int.tryParse(_passingScoreController.text) ?? 0;
              String message;
              Color color;

              if (score < 50) {
                message = 'Low threshold - most candidates will pass';
                color = Colors.green;
              } else if (score < 70) {
                message = 'Moderate difficulty';
                color = Colors.orange;
              } else {
                message = 'High threshold - only top performers will pass';
                color = Colors.red;
              }

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, size: 18, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: theme.textTheme.bodySmall?.copyWith(color: color),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Linked Job Info
          if (_linkedJob != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.link, color: theme.primaryColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Linked to Job',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          _linkedJob!.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStep2Questions(ThemeData theme) {
    return Container(
      key: const ValueKey(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Stats row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildQuestionStat(
                  theme,
                  Icons.help_outline,
                  '${_questions.length}',
                  'Questions',
                  theme.primaryColor,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                _buildQuestionStat(
                  theme,
                  Icons.check_circle_outline,
                  '${_questions.where(_isQuestionComplete).length}',
                  'Complete',
                  Colors.green,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                _buildQuestionStat(
                  theme,
                  Icons.timer_outlined,
                  _durationController.text,
                  'Minutes',
                  Colors.orange,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Questions List
          if (_questions.isEmpty)
            _buildEmptyQuestionsState(theme)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                return QuestionEditorCard(
                  question: _questions[index],
                  questionNumber: index + 1,
                  isExpanded: _expandedQuestionIndex == index,
                  onToggleExpand: () {
                    setState(() {
                      _expandedQuestionIndex =
                          _expandedQuestionIndex == index ? null : index;
                    });
                  },
                  onSave: (q) => _updateQuestion(index, q),
                  onDelete: () => _deleteQuestion(index),
                );
              },
            ),

          const SizedBox(height: 16),

          // Add Question Button
          OutlinedButton.icon(
            onPressed: _addQuestion,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Question'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              side: BorderSide(color: theme.primaryColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuestionStat(
    ThemeData theme,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyQuestionsState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              Icons.quiz_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Questions Yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add questions to test candidates\' knowledge and skills',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildStep3Review(ThemeData theme) {
    final completeQuestions = _questions.where(_isQuestionComplete).length;

    return Container(
      key: const ValueKey(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.preview_rounded,
                size: 48,
                color: theme.primaryColor,
              ),
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child: Text(
              'Review Your Quiz',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Center(
            child: Text(
              'Make sure everything looks good before saving',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 32),

          // Review Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quiz Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.quiz, color: theme.primaryColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleController.text.trim(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_linkedJob != null)
                            Text(
                              'For: ${_linkedJob!.title}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 32),

                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildReviewStat(
                        theme,
                        Icons.help_outline,
                        '$completeQuestions',
                        'Questions',
                      ),
                    ),
                    Expanded(
                      child: _buildReviewStat(
                        theme,
                        Icons.timer_outlined,
                        '${_durationController.text} min',
                        'Time Limit',
                      ),
                    ),
                    Expanded(
                      child: _buildReviewStat(
                        theme,
                        Icons.percent,
                        '${_passingScoreController.text}%',
                        'Pass Score',
                      ),
                    ),
                  ],
                ),

                const Divider(height: 32),

                // Questions Preview
                Text(
                  'Questions Preview',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                ...List.generate(
                  _questions.length > 3 ? 3 : _questions.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _questions[index].questionText,
                            style: theme.textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          _isQuestionComplete(_questions[index])
                              ? Icons.check_circle
                              : Icons.warning,
                          size: 18,
                          color: _isQuestionComplete(_questions[index])
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_questions.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+${_questions.length - 3} more questions',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _isForward = false;
                  _currentStep = 0;
                });
              },
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Edit quiz details'),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildReviewStat(
    ThemeData theme,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, color: theme.primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: theme.primaryColor),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(color: theme.primaryColor),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              flex: _currentStep > 0 ? 2 : 1,
              child: _currentStep < _totalSteps - 1
                  ? ListenableBuilder(
                      listenable: Listenable.merge([
                        _titleController,
                        _durationController,
                        _passingScoreController,
                      ]),
                      builder: (context, _) {
                        final isValid =
                            _currentStep == 0 ? _isStep1Valid : _isStep2Valid;

                        return PrimaryButton(
                          text: 'Continue',
                          onPressed: isValid ? _nextStep : null,
                        );
                      },
                    )
                  : PrimaryButton(
                      text: _isEditMode ? 'Update Quiz' : 'Save Quiz',
                      onPressed: _isLoading ? null : _saveQuiz,
                      isLoading: _isLoading,
                      icon: Icons.check_rounded,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
