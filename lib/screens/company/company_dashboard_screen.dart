import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:project/providers/providers.dart';
import 'package:project/models/models.dart';
import 'package:project/theme/app_theme.dart';
import 'package:project/widgets/dashboard/dashboard_widgets.dart';

class CompanyDashboardScreen extends StatefulWidget {
  final void Function(int)? onNavigateToTab;
  
  const CompanyDashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  static bool _hasAnimated = false;
  
  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    await Future.wait([
      context.read<JobProvider>().fetchAllJobsFromSupabase(),
      context.read<ApplicationProvider>().fetchAllApplicationsFromSupabase(),
      context.read<QuizProvider>().fetchAllQuizzesFromSupabase(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final jobProvider = context.watch<JobProvider>();
    final applicationProvider = context.watch<ApplicationProvider>();
    final quizProvider = context.watch<QuizProvider>();
    final user = authProvider.currentUser;

    if (user is! Company) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final companyJobs = jobProvider.getJobsByCompany(user.companyId);
    final activeJobs = companyJobs.where((j) => j.status == JobStatus.active).toList();

    // Get applications for company's jobs
    final companyApplications = applicationProvider.applications.where((app) {
      return companyJobs.any((job) => job.jobId == app.jobId);
    }).toList();

    final pendingApplications = companyApplications
        .where((a) => a.status == ApplicationStatus.pending)
        .toList();

    // Get quizzes count
    final companyQuizzes = quizProvider.quizzes.where((quiz) {
      return companyJobs.any((job) => job.jobId == quiz.jobId);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          slivers: [
            // Clean App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.backgroundColor,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'Dashboard',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              actions: [
                const SizedBox(width: 8),
              ],
            ),

            // Main Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Builder(
                      builder: (context) {
                        final widget = WelcomeCard(
                          userName: user.companyName,
                          tagline: 'Find your next great hire',
                          avatarUrl: user.logoUrl,
                        );
                        if (_hasAnimated) return widget;
                        return widget.animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Stats Section
                    Builder(
                      builder: (context) {
                        final widget = StatsCard(
                          title: 'Overview',
                          stats: [
                            StatData(
                              value: activeJobs.length.toString(),
                              label: 'Active Jobs',
                              color: AppTheme.primaryColor,
                            ),
                            StatData(
                              value: companyApplications.length.toString(),
                              label: 'Applications',
                              color: AppTheme.secondaryColor,
                            ),
                            StatData(
                              value: pendingApplications.length.toString(),
                              label: 'Pending',
                              color: AppTheme.accentColor,
                            ),
                            StatData(
                              value: companyQuizzes.length.toString(),
                              label: 'Quizzes',
                              color: const Color(0xFF8B5CF6),
                            ),
                          ],
                        );
                        if (_hasAnimated) return widget;
                        return widget.animate()
                            .fadeIn(duration: 400.ms, delay: 100.ms)
                            .slideY(begin: 0.1, end: 0);
                      },
                    ),

                    const SizedBox(height: 28),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final actionsWidget = QuickActionsRow(
                          actions: [
                            QuickActionData(
                              label: 'Post Job',
                              icon: Icons.add_rounded,
                              color: AppTheme.primaryColor,
                              onTap: () => Navigator.pushNamed(context, '/company/create-job'),
                            ),
                            QuickActionData(
                              label: 'Quizzes',
                              icon: Icons.quiz_rounded,
                              color: const Color(0xFF8B5CF6),
                              onTap: () => _showQuizManagementSheet(context, theme),
                            ),
                            QuickActionData(
                              label: 'Profile',
                              icon: Icons.business_rounded,
                              color: AppTheme.secondaryColor,
                              onTap: () => widget.onNavigateToTab?.call(3),
                            ),
                          ],
                        );
                        if (_hasAnimated) return actionsWidget;
                        return actionsWidget.animate()
                            .fadeIn(duration: 400.ms, delay: 200.ms)
                            .slideY(begin: 0.1, end: 0);
                      },
                    ),

                    const SizedBox(height: 28),

                    // Active Jobs Preview
                    Builder(
                      builder: (context) {
                        final jobsWidget = _buildActiveJobsSection(context, theme, activeJobs);
                        if (_hasAnimated) return jobsWidget;
                        // Mark as animated after building
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _hasAnimated = true;
                        });
                        return jobsWidget.animate()
                            .fadeIn(duration: 400.ms, delay: 300.ms)
                            .slideY(begin: 0.1, end: 0);
                      },
                    ),

                    const SizedBox(height: 100), // Bottom padding for nav bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveJobsSection(BuildContext context, ThemeData theme, List<Job> activeJobs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Active Jobs',
          showSeeAll: activeJobs.isNotEmpty,
          onSeeAll: () {
            // Navigate to jobs tab
          },
        ),
        const SizedBox(height: 12),
        if (activeJobs.isEmpty)
          EmptyStateCard(
            icon: Icons.work_outline_rounded,
            title: 'No active jobs',
            subtitle: 'Post your first job to start\nreceiving applications',
            actionLabel: 'Post a Job',
            actionIcon: Icons.add_rounded,
            onAction: () => Navigator.pushNamed(context, '/company/create-job'),
          )
        else
          ...activeJobs.take(3).map((job) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildJobPreviewCard(context, theme, job),
              )),
      ],
    );
  }

  Widget _buildJobPreviewCard(BuildContext context, ThemeData theme, Job job) {
    final applicationProvider = context.watch<ApplicationProvider>();
    final appCount = applicationProvider.getApplicationsByJob(job.jobId).length;
    final quizProvider = context.watch<QuizProvider>();
    final hasQuiz = quizProvider.jobHasQuiz(job.jobId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.work_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job.location,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$appCount applicant${appCount == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              if (hasQuiz) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.quiz_rounded, size: 12, color: Colors.purple.shade400),
                    const SizedBox(width: 4),
                    Text(
                      'Quiz',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.purple.shade400,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showQuizManagementSheet(BuildContext context, ThemeData theme) {
    final authProvider = context.read<AuthProvider>();
    final quizProvider = context.read<QuizProvider>();
    final jobProvider = context.read<JobProvider>();
    final user = authProvider.currentUser;

    if (user is! Company) return;

    final companyJobs = jobProvider.getJobsByCompany(user.companyId);
    final companyQuizzes = quizProvider.quizzes.where((quiz) {
      return companyJobs.any((job) => job.jobId == quiz.jobId);
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Quizzes',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${companyQuizzes.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.purple.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: companyQuizzes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.quiz_rounded,
                                  size: 40, color: Colors.purple.shade300),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No quizzes yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a quiz from your job listings\nto screen candidates',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: companyQuizzes.length,
                        itemBuilder: (context, index) {
                          final quiz = companyQuizzes[index];
                          final job = companyJobs.firstWhere(
                            (j) => j.jobId == quiz.jobId,
                            orElse: () => Job(
                              jobId: '',
                              companyId: '',
                              title: 'Unknown Job',
                              description: '',
                              location: '',
                              jobType: JobType.fullTime,
                              requiredEducation: EducationLevel.bs,
                              postedDate: DateTime.now(),
                              status: JobStatus.closed,
                            ),
                          );
                          return _buildQuizListItem(context, theme, quiz, job);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizListItem(BuildContext context, ThemeData theme, Quiz quiz, Job job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(
              context,
              '/company/create-quiz',
              arguments: {'job': job, 'quiz': quiz},
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.quiz_rounded,
                    color: Colors.purple.shade400,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${quiz.questions.length} Q',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${quiz.passingScore}% pass',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
