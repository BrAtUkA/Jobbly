import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:project/providers/providers.dart';
import 'package:project/models/models.dart';
import 'package:project/theme/app_theme.dart';
import 'package:project/screens/seeker/job_detail_screen.dart';
import 'package:project/widgets/dashboard/dashboard_widgets.dart';

class SeekerDashboardScreen extends StatefulWidget {
  final void Function(int)? onNavigateToTab;
  
  const SeekerDashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<SeekerDashboardScreen> createState() => _SeekerDashboardScreenState();
}

class _SeekerDashboardScreenState extends State<SeekerDashboardScreen> {
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
      context.read<SkillProvider>().fetchAllSkillsFromSupabase(),
      context.read<JobSkillProvider>().fetchAllJobSkillsFromSupabase(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final jobProvider = context.watch<JobProvider>();
    final applicationProvider = context.watch<ApplicationProvider>();
    final skillProvider = context.watch<SkillProvider>();
    final jobSkillProvider = context.watch<JobSkillProvider>();
    final seekerSkillProvider = context.watch<SeekerSkillProvider>();
    final user = authProvider.currentUser;

    if (user is! Seeker) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Get seeker's applications
    final myApplications = applicationProvider.getApplicationsBySeeker(user.seekerId);
    final pendingApps = myApplications.where((a) => a.status == ApplicationStatus.pending).length;
    final shortlistedApps = myApplications.where((a) => a.status == ApplicationStatus.shortlisted).length;
    
    // Get active jobs
    final activeJobs = jobProvider.jobs.where((j) => j.status == JobStatus.active).toList();
    
    // Get seeker's skills
    final seekerSkills = seekerSkillProvider.getSkillsForSeeker(user.seekerId);
    final seekerSkillIds = seekerSkills.map((s) => s.skillId).toSet();

    // Calculate job recommendations with match percentage
    final recommendedJobs = _getRecommendedJobs(
      activeJobs, 
      seekerSkillIds, 
      jobSkillProvider, 
      myApplications,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          slivers: [
            // App Bar
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
                  'Home',
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
                          userName: user.fullName,
                          tagline: 'Find your dream job today',
                          avatarUrl: user.pfp,
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
                          title: 'Your Stats',
                          stats: [
                            StatData(
                              value: myApplications.length.toString(),
                              label: 'Applications',
                              color: AppTheme.primaryColor,
                            ),
                            StatData(
                              value: pendingApps.toString(),
                              label: 'Pending',
                              color: AppTheme.accentColor,
                            ),
                            StatData(
                              value: shortlistedApps.toString(),
                              label: 'Shortlisted',
                              color: AppTheme.secondaryColor,
                            ),
                            StatData(
                              value: seekerSkills.length.toString(),
                              label: 'Skills',
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
                        final actionsRow = QuickActionsRow(
                          actions: [
                            QuickActionData(
                              label: 'Browse Jobs',
                              icon: Icons.search_rounded,
                              color: AppTheme.primaryColor,
                              onTap: () => widget.onNavigateToTab?.call(1),
                            ),
                            QuickActionData(
                              label: 'Applications',
                              icon: Icons.description_rounded,
                              color: AppTheme.secondaryColor,
                              onTap: () => widget.onNavigateToTab?.call(2),
                            ),
                            QuickActionData(
                              label: 'Profile',
                              icon: Icons.person_rounded,
                              color: const Color(0xFF8B5CF6),
                              onTap: () => widget.onNavigateToTab?.call(3),
                            ),
                          ],
                        );
                        if (_hasAnimated) return actionsRow;
                        return actionsRow.animate()
                            .fadeIn(duration: 400.ms, delay: 200.ms)
                            .slideY(begin: 0.1, end: 0);
                      },
                    ),

                    const SizedBox(height: 28),

                    // Recommended Jobs Section
                    Builder(
                      builder: (context) {
                        final widget = _buildRecommendedJobsSection(
                          context, 
                          theme, 
                          recommendedJobs,
                          jobSkillProvider,
                          skillProvider,
                          seekerSkillIds,
                        );
                        if (_hasAnimated) return widget;
                        // Mark as animated after building
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _hasAnimated = true;
                        });
                        return widget.animate()
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

  List<MapEntry<Job, double>> _getRecommendedJobs(
    List<Job> activeJobs,
    Set<String> seekerSkillIds,
    JobSkillProvider jobSkillProvider,
    List<Application> myApplications,
  ) {
    // Filter out jobs already applied to
    final appliedJobIds = myApplications.map((a) => a.jobId).toSet();
    final availableJobs = activeJobs.where((j) => !appliedJobIds.contains(j.jobId)).toList();

    // Calculate match percentage for each job
    final jobsWithMatch = <MapEntry<Job, double>>[];
    
    for (final job in availableJobs) {
      final jobSkills = jobSkillProvider.getSkillsForJob(job.jobId);
      final jobSkillIds = jobSkills.map((s) => s.skillId).toSet();
      
      if (jobSkillIds.isEmpty) {
        // Jobs with no skill requirements - show with 100% match
        jobsWithMatch.add(MapEntry(job, 100.0));
      } else {
        final matchingSkills = seekerSkillIds.intersection(jobSkillIds);
        final matchPercentage = (matchingSkills.length / jobSkillIds.length) * 100;
        jobsWithMatch.add(MapEntry(job, matchPercentage));
      }
    }

    // Sort by match percentage (highest first), then by posted date
    jobsWithMatch.sort((a, b) {
      final matchCompare = b.value.compareTo(a.value);
      if (matchCompare != 0) return matchCompare;
      return b.key.postedDate.compareTo(a.key.postedDate);
    });

    // Return top 5 recommendations
    return jobsWithMatch.take(5).toList();
  }

  Widget _buildRecommendedJobsSection(
    BuildContext context,
    ThemeData theme,
    List<MapEntry<Job, double>> recommendedJobs,
    JobSkillProvider jobSkillProvider,
    SkillProvider skillProvider,
    Set<String> seekerSkillIds,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Recommended for You',
          showSeeAll: true,
          onSeeAll: () => widget.onNavigateToTab?.call(1),
        ),
        const SizedBox(height: 12),
        if (recommendedJobs.isEmpty)
          EmptyStateCard(
            icon: Icons.work_outline_rounded,
            title: 'No recommendations yet',
            subtitle: 'Add more skills to your profile to get personalized job recommendations',
          )
        else
          ...recommendedJobs.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildJobCard(
              context, 
              theme, 
              entry.key, 
              entry.value,
              jobSkillProvider,
              skillProvider,
              seekerSkillIds,
            ),
          )),
      ],
    );
  }

  Widget _buildJobCard(
    BuildContext context,
    ThemeData theme,
    Job job,
    double matchPercentage,
    JobSkillProvider jobSkillProvider,
    SkillProvider skillProvider,
    Set<String> seekerSkillIds,
  ) {
    final companyProvider = context.watch<CompanyProvider>();
    final company = companyProvider.getCompanyById(job.companyId);
    
    // Get job skills for display
    final jobSkills = jobSkillProvider.getSkillsForJob(job.jobId);
    final skillNames = jobSkills.take(3).map((js) {
      final skill = skillProvider.getSkillById(js.skillId);
      return skill?.skillName ?? '';
    }).where((name) => name.isNotEmpty).toList();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JobDetailScreen(job: job),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Company logo/initial
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: company?.logoUrl != null && company!.logoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              company.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  company.companyName.isNotEmpty 
                                      ? company.companyName[0].toUpperCase() 
                                      : 'C',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              company?.companyName.isNotEmpty == true
                                  ? company!.companyName[0].toUpperCase()
                                  : 'C',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          company?.companyName ?? 'Company',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Match percentage badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getMatchColor(matchPercentage).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${matchPercentage.round()}% match',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getMatchColor(matchPercentage),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Job info row
              Row(
                children: [
                  _buildInfoChip(Icons.location_on_outlined, job.location),
                  const SizedBox(width: 12),
                  _buildInfoChip(Icons.work_outline_rounded, _formatJobType(job.jobType)),
                ],
              ),
              if (skillNames.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skillNames.map((name) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getMatchColor(double percentage) {
    if (percentage >= 80) return AppTheme.secondaryColor;
    if (percentage >= 50) return AppTheme.accentColor;
    return Colors.grey.shade600;
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatJobType(JobType type) {
    switch (type) {
      case JobType.fullTime:
        return 'Full-time';
      case JobType.partTime:
        return 'Part-time';
      case JobType.internship:
        return 'Internship';
      case JobType.contract:
        return 'Contract';
    }
  }
}
