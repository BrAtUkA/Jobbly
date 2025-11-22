import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:project/providers/providers.dart';
import 'package:project/models/models.dart';
import 'package:project/widgets/common/user_avatar.dart';
import 'package:url_launcher/url_launcher.dart';

class JobApplicationsScreen extends StatefulWidget {
  final Job job;

  const JobApplicationsScreen({super.key, required this.job});

  @override
  State<JobApplicationsScreen> createState() => _JobApplicationsScreenState();
}

class _JobApplicationsScreenState extends State<JobApplicationsScreen> {
  String _filterStatus = 'all';
  bool _isRefreshing = false;

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    try {
      if (!mounted) return;
      await context.read<ApplicationProvider>().fetchAllApplicationsFromSupabase();
      if (!mounted) return;
      await context.read<SeekerProvider>().fetchAllSeekersFromSupabase();
      if (!mounted) return;
      await context.read<QuizAttemptProvider>().fetchAllQuizAttemptsFromSupabase();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final applicationProvider = context.watch<ApplicationProvider>();
    final seekerProvider = context.watch<SeekerProvider>();
    final quizAttemptProvider = context.watch<QuizAttemptProvider>();
    final quizProvider = context.watch<QuizProvider>();

    // Check if job has a quiz
    final jobQuiz = quizProvider.getQuizForJob(widget.job.jobId);

    final applications = applicationProvider.getApplicationsByJob(widget.job.jobId);
    final filteredApplications = _filterApplications(applications);

    // Stats
    final pendingCount = applications.where((a) => a.status == ApplicationStatus.pending).length;
    final shortlistedCount = applications.where((a) => a.status == ApplicationStatus.shortlisted).length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Applications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.job.title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primaryColor,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _isRefreshing ? null : _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      theme,
                      icon: Icons.inbox_rounded,
                      label: 'Total',
                      value: applications.length.toString(),
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      theme,
                      icon: Icons.hourglass_empty_rounded,
                      label: 'Pending',
                      value: pendingCount.toString(),
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      theme,
                      icon: Icons.star_rounded,
                      label: 'Shortlisted',
                      value: shortlistedCount.toString(),
                      color: Colors.green,
                    ),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),

              const SizedBox(height: 24),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(theme, 'All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip(theme, 'Pending', 'pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip(theme, 'Reviewed', 'reviewed'),
                    const SizedBox(width: 8),
                    _buildFilterChip(theme, 'Shortlisted', 'shortlisted'),
                    const SizedBox(width: 8),
                    _buildFilterChip(theme, 'Rejected', 'rejected'),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 24),

              // Applications list
              if (filteredApplications.isEmpty)
                _buildEmptyState(theme)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredApplications.length,
                  itemBuilder: (context, index) {
                    final application = filteredApplications[index];
                    final seeker = seekerProvider.getSeekerById(application.seekerId);
                    
                    // Get quiz attempt if available
                    QuizAttempt? quizAttempt;
                    if (application.quizAttemptId != null) {
                      quizAttempt = quizAttemptProvider.getQuizAttemptById(application.quizAttemptId!);
                    }
                    
                    return _buildApplicationCard(
                      context,
                      theme,
                      application,
                      seeker,
                      quizAttempt,
                      jobQuiz,
                      index,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Application> _filterApplications(List<Application> applications) {
    if (_filterStatus == 'all') return applications;

    return applications.where((a) {
      switch (_filterStatus) {
        case 'pending':
          return a.status == ApplicationStatus.pending;
        case 'reviewed':
          return a.status == ApplicationStatus.reviewed;
        case 'shortlisted':
          return a.status == ApplicationStatus.shortlisted;
        case 'rejected':
          return a.status == ApplicationStatus.rejected;
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ThemeData theme, String label, String value) {
    final isSelected = _filterStatus == value;
    return InkWell(
      onTap: () => setState(() => _filterStatus = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Applications',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filterStatus == 'all'
                ? 'No one has applied to this job yet'
                : 'No $_filterStatus applications',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildApplicationCard(
    BuildContext context,
    ThemeData theme,
    Application application,
    Seeker? seeker,
    QuizAttempt? quizAttempt,
    Quiz? jobQuiz,
    int index,
  ) {
    final daysAgo = DateTime.now().difference(application.appliedDate).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showApplicationDetails(context, theme, application, seeker, quizAttempt, jobQuiz),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Seeker Avatar
                UserAvatar(
                  imageUrl: seeker?.pfp,
                  name: seeker?.fullName ?? 'Unknown',
                  radius: 28,
                  fontSize: 18,
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seeker?.fullName ?? 'Unknown Applicant',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (seeker != null)
                        Row(
                          children: [
                            Icon(Icons.school_outlined,
                                size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              _getEducationDisplay(seeker.education),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            daysAgo == 0
                                ? 'Applied today'
                                : daysAgo == 1
                                    ? 'Applied yesterday'
                                    : 'Applied $daysAgo days ago',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                          // Quiz score badge
                          if (quizAttempt != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: quizAttempt.isPassed
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    quizAttempt.isPassed
                                        ? Icons.check_circle_outline
                                        : Icons.cancel_outlined,
                                    size: 10,
                                    color: quizAttempt.isPassed
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${quizAttempt.score}%',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: quizAttempt.isPassed
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (jobQuiz != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Quiz pending',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Status Badge
                _buildStatusBadge(theme, application.status),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildStatusBadge(ThemeData theme, ApplicationStatus status) {
    Color color;
    String label;

    switch (status) {
      case ApplicationStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case ApplicationStatus.reviewed:
        color = Colors.blue;
        label = 'Reviewed';
        break;
      case ApplicationStatus.shortlisted:
        color = Colors.green;
        label = 'Shortlisted';
        break;
      case ApplicationStatus.rejected:
        color = Colors.red;
        label = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildQuizScoreSection(ThemeData theme, QuizAttempt? attempt, Quiz quiz) {
    if (attempt == null) {
      // Quiz not taken yet
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.quiz_outlined, color: Colors.orange.shade700, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiz Not Taken',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Applicant has not completed the assessment for "${quiz.title}"',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Quiz taken - show results
    final isPassed = attempt.isPassed;
    final color = isPassed ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPassed ? Icons.check_circle_outline : Icons.cancel_outlined,
                  color: color.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPassed ? 'Quiz Passed' : 'Quiz Failed',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quiz.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${attempt.score}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: color.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: attempt.score / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildQuizStat(theme, Icons.access_time, '${attempt.timeTaken} min', 'Time Taken'),
              const SizedBox(width: 24),
              _buildQuizStat(theme, Icons.percent, '${quiz.passingScore}%', 'Passing Score'),
              const SizedBox(width: 24),
              _buildQuizStat(
                theme,
                Icons.calendar_today_outlined,
                _formatDate(attempt.attemptDate),
                'Completed',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuizStat(ThemeData theme, IconData icon, String value, String label) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _getEducationDisplay(EducationLevel level) {
    switch (level) {
      case EducationLevel.matric:
        return 'Matriculation';
      case EducationLevel.inter:
        return 'Intermediate';
      case EducationLevel.bs:
        return "Bachelor's";
      case EducationLevel.ms:
        return "Master's";
      case EducationLevel.phd:
        return 'PhD';
    }
  }

  void _showApplicationDetails(
    BuildContext context,
    ThemeData theme,
    Application application,
    Seeker? seeker,
    QuizAttempt? quizAttempt,
    Quiz? jobQuiz,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          UserAvatar(
                            imageUrl: seeker?.pfp,
                            name: seeker?.fullName ?? 'Unknown',
                            radius: 36,
                            fontSize: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  seeker?.fullName ?? 'Unknown',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildStatusBadge(theme, application.status),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      
                      // Quiz Score Section
                      if (jobQuiz != null) ...[
                        _buildQuizScoreSection(theme, quizAttempt, jobQuiz),
                        const SizedBox(height: 16),
                      ],
                      
                      const Divider(),
                      const SizedBox(height: 24),

                      // Seeker Details
                      Text(
                        'Applicant Details',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (seeker != null) ...[
                        _buildInfoRow(theme, Icons.email_outlined, 'Email', seeker.email),
                        if (seeker.phone != null && seeker.phone!.isNotEmpty)
                          _buildInfoRow(theme, Icons.phone_outlined, 'Phone', seeker.phone!),
                        _buildInfoRow(theme, Icons.school_outlined, 'Education',
                            _getEducationDisplay(seeker.education)),
                        if (seeker.location != null && seeker.location!.isNotEmpty)
                          _buildInfoRow(
                              theme, Icons.location_on_outlined, 'Location', seeker.location!),

                        // Resume Section
                        if (seeker.resumeUrl != null && seeker.resumeUrl!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildResumeRow(theme, seeker.resumeUrl!),
                        ],

                        // Skills Section
                        Builder(
                          builder: (context) {
                            final seekerSkillProvider = context.read<SeekerSkillProvider>();
                            final skillProvider = context.read<SkillProvider>();
                            final seekerSkills = seekerSkillProvider.getSkillsForSeeker(seeker.seekerId);
                            
                            if (seekerSkills.isEmpty) return const SizedBox.shrink();
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                Text(
                                  'Skills',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: seekerSkills.map((seekerSkill) {
                                    final skill = skillProvider.getSkillById(seekerSkill.skillId);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: theme.primaryColor.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        skill?.skillName ?? 'Unknown Skill',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            );
                          },
                        ),

                        if (seeker.experience != null && seeker.experience!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Experience',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              seeker.experience!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ] else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey.shade600),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Applicant details not available',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Action Buttons
                      Text(
                        'Update Status',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          if (application.status != ApplicationStatus.reviewed)
                            Expanded(
                              child: _buildActionButton(
                                context,
                                application,
                                'Review',
                                ApplicationStatus.reviewed,
                                Colors.blue,
                                Icons.visibility_outlined,
                                seeker?.fullName ?? 'Unknown',
                              ),
                            ),
                          if (application.status != ApplicationStatus.reviewed)
                            const SizedBox(width: 12),
                          if (application.status != ApplicationStatus.shortlisted)
                            Expanded(
                              child: _buildActionButton(
                                context,
                                application,
                                'Shortlist',
                                ApplicationStatus.shortlisted,
                                Colors.green,
                                Icons.star_outline,
                                seeker?.fullName ?? 'Unknown',
                              ),
                            ),
                        ],
                      ),
                      if (application.status != ApplicationStatus.rejected) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: _buildActionButton(
                            context,
                            application,
                            'Reject Application',
                            ApplicationStatus.rejected,
                            Colors.red,
                            Icons.close_rounded,
                            seeker?.fullName ?? 'Unknown',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: theme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeRow(ThemeData theme, String resumeUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.description_rounded, size: 18, color: Colors.green.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resume',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          Builder(
            builder: (buttonContext) => TextButton.icon(
              onPressed: () async {
                try {
                  final uri = Uri.parse(resumeUrl);
                  debugPrint('Attempting to launch resume URL: $resumeUrl');
                  
                  // Try to launch directly without checking canLaunchUrl
                  // canLaunchUrl can return false even when launch works
                  await launchUrl(
                    uri, 
                    mode: LaunchMode.externalApplication,
                  );
                } catch (e) {
                  debugPrint('Error launching resume: $e');
                  if (buttonContext.mounted) {
                    ScaffoldMessenger.of(buttonContext).showSnackBar(
                      SnackBar(
                        content: Text('Could not open resume: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('View'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    Application application,
    String label,
    ApplicationStatus newStatus,
    Color color,
    IconData icon,
    String seekerName,
  ) {
    return OutlinedButton.icon(
      onPressed: () async {
        // Update application status
        await context.read<ApplicationProvider>().updateApplicationStatus(
              application.applicationId,
              newStatus,
            );
        
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Application marked as ${newStatus.name}')),
          );
        }
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }
}
