// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:project/providers/providers.dart';
import 'package:project/models/models.dart';
import 'package:project/theme/app_theme.dart';
import 'package:project/widgets/primary_button.dart';
import 'package:project/widgets/common/common_widgets.dart';
import 'package:project/screens/seeker/quiz_taking_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;
  
  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isApplying = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final companyProvider = context.watch<CompanyProvider>();
    final jobSkillProvider = context.watch<JobSkillProvider>();
    final skillProvider = context.watch<SkillProvider>();
    final applicationProvider = context.watch<ApplicationProvider>();
    final quizProvider = context.watch<QuizProvider>();
    final authProvider = context.watch<AuthProvider>();
    final seekerSkillProvider = context.watch<SeekerSkillProvider>();

    final user = authProvider.currentUser;
    if (user is! Seeker) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final company = companyProvider.getCompanyById(widget.job.companyId);
    final jobSkills = jobSkillProvider.getSkillsForJob(widget.job.jobId);
    final skills = jobSkills.map((js) => skillProvider.getSkillById(js.skillId)).whereType<Skill>().toList();
    
    // Check if already applied
    final myApplications = applicationProvider.getApplicationsBySeeker(user.seekerId);
    final existingApplication = myApplications.where((a) => a.jobId == widget.job.jobId).firstOrNull;
    final hasApplied = existingApplication != null;

    // Get seeker's skills for match calculation
    final seekerSkills = seekerSkillProvider.getSkillsForSeeker(user.seekerId);
    final seekerSkillIds = seekerSkills.map((s) => s.skillId).toSet();
    final jobSkillIds = jobSkills.map((s) => s.skillId).toSet();
    
    double matchPercentage = 100.0;
    if (jobSkillIds.isNotEmpty) {
      final matchingSkills = seekerSkillIds.intersection(jobSkillIds);
      matchPercentage = (matchingSkills.length / jobSkillIds.length) * 100;
    }

    // Check if job has quiz
    final hasQuiz = quizProvider.jobHasQuiz(widget.job.jobId);
    final quiz = hasQuiz ? quizProvider.getQuizForJob(widget.job.jobId) : null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildAppBar(theme, company, matchPercentage),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Job Info Grid
                  JobInfoGrid.fromJob(job: widget.job, companyName: company?.companyName)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // Description
                  TextSection(
                    title: 'Job Description',
                    content: widget.job.description,
                  ).animate()
                      .fadeIn(duration: 400.ms, delay: 100.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // Required Skills
                  if (skills.isNotEmpty) ...[
                    _buildSkillsSection(theme, skills, seekerSkillIds)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 24),
                  ],

                  // Quiz Info
                  if (hasQuiz && quiz != null) ...[
                    QuizInfoCard(quiz: quiz)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 300.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 24),
                  ],

                  // Company Info
                  if (company != null)
                    CompanyCard(company: company)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 400.ms)
                        .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(
        context,
        theme,
        hasApplied,
        existingApplication,
        hasQuiz,
        quiz,
        user,
      ),
    );
  }

  SliverAppBar _buildAppBar(ThemeData theme, Company? company, double matchPercentage) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CompanyLogoLarge(company: company),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.job.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              company?.companyName ?? 'Company',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${matchPercentage.round()}% skill match',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkillsSection(ThemeData theme, List<Skill> skills, Set<String> seekerSkillIds) {
    final matchedCount = skills.where((s) => seekerSkillIds.contains(s.skillId)).length;
    
    return ContentSection(
      title: 'Required Skills',
      trailing: Text(
        '$matchedCount/${skills.length} matched',
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppTheme.secondaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SkillChipWrap(
        skills: skills.map((s) => s.skillName).toList(),
        matchedSkills: skills
            .where((s) => seekerSkillIds.contains(s.skillId))
            .map((s) => s.skillName)
            .toSet(),
        showMatchIndicator: true,
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ThemeData theme,
    bool hasApplied,
    Application? existingApplication,
    bool hasQuiz,
    Quiz? quiz,
    Seeker user,
  ) {
    Widget buttonContent;
    
    if (hasApplied) {
      buttonContent = _buildAppliedStatus(theme, existingApplication!);
    } else if (widget.job.status == JobStatus.closed) {
      buttonContent = _buildClosedStatus(theme);
    } else {
      buttonContent = SizedBox(
        height: 56,
        child: PrimaryButton(
          text: hasQuiz ? 'Apply & Take Quiz' : 'Apply Now',
          onPressed: _isApplying 
              ? null 
              : () => _applyForJob(context, hasQuiz, quiz, user),
          isLoading: _isApplying,
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
        top: false,
        maintainBottomViewPadding: true,
        child: buttonContent,
      ),
    );
  }

  Widget _buildAppliedStatus(ThemeData theme, Application application) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: AppTheme.secondaryColor),
          const SizedBox(width: 8),
          Text(
            'Applied - ${_formatApplicationStatus(application.status)}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.secondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedStatus(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block_rounded, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            'This position is no longer accepting applications',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyForJob(BuildContext context, bool hasQuiz, Quiz? quiz, Seeker user) async {
    if (hasQuiz && quiz != null) {
      final shouldStart = await _showQuizConfirmationSheet(context, quiz);
      if (shouldStart != true) return;
      
      if (!mounted) return;
      final result = await Navigator.push<QuizAttempt?>(
        context,
        MaterialPageRoute(
          builder: (_) => QuizTakingScreen(quiz: quiz, job: widget.job),
        ),
      );

      if (result != null && mounted) {
        await _createApplication(context, user.seekerId, result.attemptId);
      }
    } else {
      await _createApplication(context, user.seekerId, null);
    }
  }

  Future<bool?> _showQuizConfirmationSheet(BuildContext context, Quiz quiz) {
    final theme = Theme.of(context);
    const quizColor = Color(0xFF8B5CF6);
    
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Quiz header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: quizColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.quiz_rounded, color: quizColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assessment Required',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        quiz.title,
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Quiz stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  QuizStatIcon(value: '${quiz.questions.length}', label: 'Questions', icon: Icons.help_outline_rounded),
                  QuizStatIcon(value: '${quiz.duration} min', label: 'Duration', icon: Icons.timer_outlined),
                  QuizStatIcon(value: '${quiz.passingScore}%', label: 'To Pass', icon: Icons.check_circle_outline),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Important notes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.accentColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Before you start',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...[
                    'You cannot pause once you begin',
                    'Timer will start immediately',
                    'Ensure stable internet connection',
                    'Auto-submits when time runs out',
                  ].map((text) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            text,
                            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: quizColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _createApplication(BuildContext context, String seekerId, String? quizAttemptId) async {
    setState(() => _isApplying = true);

    try {
      final application = Application(
        applicationId: '',
        jobId: widget.job.jobId,
        seekerId: seekerId,
        quizAttemptId: quizAttemptId,
        appliedDate: DateTime.now(),
        status: ApplicationStatus.pending,
      );

      if (!mounted) return;
      await context.read<ApplicationProvider>().addApplication(application);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Application submitted successfully!'),
            backgroundColor: AppTheme.secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit application: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  String _formatApplicationStatus(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Pending Review';
      case ApplicationStatus.reviewed:
        return 'Under Review';
      case ApplicationStatus.shortlisted:
        return 'Shortlisted';
      case ApplicationStatus.rejected:
        return 'Not Selected';
    }
  }
}
