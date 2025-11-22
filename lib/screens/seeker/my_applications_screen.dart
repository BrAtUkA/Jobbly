import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/providers/providers.dart';
import 'package:project/models/models.dart';
import 'package:project/theme/app_theme.dart';
import 'package:project/screens/seeker/job_detail_screen.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final applicationProvider = context.watch<ApplicationProvider>();
    final authProvider = context.watch<AuthProvider>();
    final jobProvider = context.watch<JobProvider>();
    final quizAttemptProvider = context.watch<QuizAttemptProvider>();

    final user = authProvider.currentUser;
    if (user is! Seeker) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Get all applications for this seeker
    final myApplications = applicationProvider.getApplicationsBySeeker(user.seekerId);
    
    // Filter by status for tabs
    final pendingApps = myApplications.where((a) => a.status == ApplicationStatus.pending).toList();
    final shortlistedApps = myApplications.where((a) => a.status == ApplicationStatus.shortlisted).toList();
    final rejectedApps = myApplications.where((a) => a.status == ApplicationStatus.rejected).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () => applicationProvider.fetchAllApplicationsFromSupabase(),
        color: AppTheme.primaryColor,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
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
                  'My Applications',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),

            // Stats Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStatsCard(
                  theme,
                  myApplications.length,
                  pendingApps.length,
                  shortlistedApps.length,
                  rejectedApps.length,
                ),
              ),
            ),

            // Tab Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorColor: AppTheme.primaryColor,
                  indicatorWeight: 3,
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: [
                    Tab(text: 'All (${myApplications.length})'),
                    Tab(text: 'Pending (${pendingApps.length})'),
                    Tab(text: 'Shortlisted (${shortlistedApps.length})'),
                    Tab(text: 'Rejected (${rejectedApps.length})'),
                  ],
                  isScrollable: true,
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildApplicationList(context, theme, myApplications, jobProvider, quizAttemptProvider),
              _buildApplicationList(context, theme, pendingApps, jobProvider, quizAttemptProvider),
              _buildApplicationList(context, theme, shortlistedApps, jobProvider, quizAttemptProvider),
              _buildApplicationList(context, theme, rejectedApps, jobProvider, quizAttemptProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(ThemeData theme, int total, int pending, int shortlisted, int rejected) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(theme, total.toString(), 'Total', Colors.white),
          _buildDivider(),
          _buildStatItem(theme, pending.toString(), 'Pending', AppTheme.accentColor),
          _buildDivider(),
          _buildStatItem(theme, shortlisted.toString(), 'Shortlisted', AppTheme.secondaryColor),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  Widget _buildStatItem(ThemeData theme, String value, String label, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationList(
    BuildContext context,
    ThemeData theme,
    List<Application> applications,
    JobProvider jobProvider,
    QuizAttemptProvider quizAttemptProvider,
  ) {
    if (applications.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final application = applications[index];
        final job = jobProvider.getJobById(application.jobId);
        final quizAttempt = application.quizAttemptId != null
            ? quizAttemptProvider.getQuizAttemptById(application.quizAttemptId!)
            : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildApplicationCard(context, theme, application, job, quizAttempt),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No applications yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start applying for jobs to see your applications here',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(
    BuildContext context,
    ThemeData theme,
    Application application,
    Job? job,
    QuizAttempt? quizAttempt,
  ) {
    final companyProvider = context.watch<CompanyProvider>();
    final company = job != null ? companyProvider.getCompanyById(job.companyId) : null;
    final canWithdraw = application.status == ApplicationStatus.pending;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: job != null 
            ? () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
              )
            : null,
        onLongPress: canWithdraw 
            ? () => _showWithdrawDialog(context, application, job)
            : null,
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
                              errorBuilder: (_, __, ___) => _buildCompanyInitial(company),
                            ),
                          )
                        : _buildCompanyInitial(company),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job?.title ?? 'Unknown Position',
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
                  // Status chip
                  _buildStatusChip(theme, application.status),
                  // Withdraw button for pending applications
                  if (canWithdraw) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => _showWithdrawDialog(context, application, job),
                      color: AppTheme.textSecondary,
                      tooltip: 'Withdraw application',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              // Info row
              Row(
                children: [
                  _buildInfoItem(Icons.calendar_today_outlined, 'Applied ${_formatDate(application.appliedDate)}'),
                  if (job != null) ...[
                    const SizedBox(width: 16),
                    _buildInfoItem(Icons.location_on_outlined, job.location),
                  ],
                ],
              ),
              // Withdraw hint for pending
              if (canWithdraw) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.touch_app_outlined, size: 12, color: AppTheme.textSecondary.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(
                      'Long press or tap × to withdraw',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
              // Quiz score if available
              if (quizAttempt != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: quizAttempt.isPassed 
                        ? AppTheme.secondaryColor.withValues(alpha: 0.1)
                        : AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.quiz_rounded,
                        size: 16,
                        color: quizAttempt.isPassed ? AppTheme.secondaryColor : AppTheme.errorColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quiz Score: ${quizAttempt.score}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: quizAttempt.isPassed ? AppTheme.secondaryColor : AppTheme.errorColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: quizAttempt.isPassed 
                              ? AppTheme.secondaryColor.withValues(alpha: 0.2)
                              : AppTheme.errorColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          quizAttempt.isPassed ? 'PASSED' : 'FAILED',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: quizAttempt.isPassed ? AppTheme.secondaryColor : AppTheme.errorColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyInitial(Company? company) {
    return Center(
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
    );
  }

  void _showWithdrawDialog(BuildContext context, Application application, Job? job) {
    final theme = Theme.of(context);
    final applicationProvider = context.read<ApplicationProvider>();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
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
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Warning icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.errorColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Withdraw Application?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        job?.title ?? 'Unknown Position',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Warning message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to withdraw this application?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• This action cannot be undone\n'
                    '• You may need to re-take the quiz if you apply again\n'
                    '• The company will be notified of your withdrawal',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Keep Application'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      
                      try {
                        // Delete the application from Supabase and cache
                        await applicationProvider.deleteApplication(application.applicationId);
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Application withdrawn successfully'),
                              backgroundColor: AppTheme.secondaryColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Error withdrawing application: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to withdraw: $e'),
                              backgroundColor: AppTheme.errorColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Withdraw'),
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

  Widget _buildStatusChip(ThemeData theme, ApplicationStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case ApplicationStatus.pending:
        color = AppTheme.accentColor;
        text = 'Pending';
        break;
      case ApplicationStatus.reviewed:
        color = AppTheme.primaryColor;
        text = 'Reviewed';
        break;
      case ApplicationStatus.shortlisted:
        color = AppTheme.secondaryColor;
        text = 'Shortlisted';
        break;
      case ApplicationStatus.rejected:
        color = AppTheme.errorColor;
        text = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    }
  }
}

// Helper delegate for pinned tab bar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
