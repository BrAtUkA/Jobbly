import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/providers/providers.dart';
import 'package:project/models/models.dart';

class CompanyJobsTab extends StatefulWidget {
  const CompanyJobsTab({super.key});

  @override
  State<CompanyJobsTab> createState() => _CompanyJobsTabState();
}

class _CompanyJobsTabState extends State<CompanyJobsTab> {
  String _filterStatus = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshJobs() async {
    await Future.wait([
      context.read<JobProvider>().fetchAllJobsFromSupabase(),
      context.read<QuizProvider>().fetchAllQuizzesFromSupabase(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final jobProvider = context.watch<JobProvider>();
    final user = authProvider.currentUser;

    if (user is! Company) return const SizedBox();

    final companyJobs = jobProvider.getJobsByCompany(user.companyId);
    final filteredJobs = _getFilteredJobs(companyJobs);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Jobs',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.black87),
            onPressed: () => Navigator.pushNamed(context, '/company/create-job'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshJobs,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search jobs...',
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(theme, 'All Jobs', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip(theme, 'Active', 'active'),
                        const SizedBox(width: 8),
                        _buildFilterChip(theme, 'Closed', 'closed'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredJobs.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredJobs.length,
                      itemBuilder: (context, index) {
                        final job = filteredJobs[index];
                        return _buildJobCard(context, theme, job, user, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Job> _getFilteredJobs(List<Job> jobs) {
    var filtered = jobs;
    
    // Apply status filter
    if (_filterStatus == 'active') {
      filtered = filtered.where((j) => j.status == JobStatus.active).toList();
    } else if (_filterStatus == 'closed') {
      filtered = filtered.where((j) => j.status == JobStatus.closed).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((j) => 
        j.title.toLowerCase().contains(query) || 
        j.description.toLowerCase().contains(query)
      ).toList();
    }

    return filtered;
  }


  Widget _buildFilterChip(ThemeData theme, String label, String value) {
    final isSelected = _filterStatus == value;
    return InkWell(
      onTap: () => setState(() => _filterStatus = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
    String message;
    String subtitle;

    switch (_filterStatus) {
      case 'active':
        message = 'No Active Jobs';
        subtitle = "You don't have any active job postings";
        break;
      case 'closed':
        message = 'No Closed Jobs';
        subtitle = "You haven't closed any job postings yet";
        break;
      default:
        message = 'No Jobs Posted Yet';
        subtitle = 'Start by creating your first job posting';
    }

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
              Icons.work_outline_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(
    BuildContext context,
    ThemeData theme,
    Job job,
    Company company,
    int index,
  ) {
    final isActive = job.status == JobStatus.active;
    final daysAgo = DateTime.now().difference(job.postedDate).inDays;
    final applicationProvider = context.watch<ApplicationProvider>();
    final quizProvider = context.watch<QuizProvider>();
    final applicationCount = applicationProvider.getApplicationsByJob(job.jobId).length;
    final hasQuiz = quizProvider.jobHasQuiz(job.jobId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showJobActions(context, theme, job),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            company.companyName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Quiz indicator
                    if (hasQuiz)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.quiz_outlined, size: 12, color: Colors.purple.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'QUIZ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.purple.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActive ? 'ACTIVE' : 'CLOSED',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isActive ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Job Details - compact chips
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _buildInfoChip(theme, Icons.work_outline, _getJobTypeDisplay(job.jobType)),
                    _buildInfoChip(theme, Icons.location_on_outlined, job.location),
                    if (job.minSalary != null || job.maxSalary != null)
                      _buildInfoChip(theme, Icons.payments_outlined, _getSalaryDisplay(job)),
                  ],
                ),

                const SizedBox(height: 10),

                // Footer Row - simplified
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      daysAgo == 0
                          ? 'Today'
                          : daysAgo == 1
                              ? 'Yesterday'
                              : '${daysAgo}d ago',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Icon(Icons.people_outline_rounded, size: 13, color: theme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '$applicationCount applicant${applicationCount == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getJobTypeDisplay(JobType type) {
    switch (type) {
      case JobType.fullTime:
        return 'Full Time';
      case JobType.partTime:
        return 'Part Time';
      case JobType.internship:
        return 'Internship';
      case JobType.contract:
        return 'Contract';
    }
  }

  String _getSalaryDisplay(Job job) {
    if (job.minSalary != null && job.maxSalary != null) {
      return 'Rs. ${job.minSalary!.toStringAsFixed(0)} - ${job.maxSalary!.toStringAsFixed(0)}';
    } else if (job.minSalary != null) {
      return 'From Rs. ${job.minSalary!.toStringAsFixed(0)}';
    } else if (job.maxSalary != null) {
      return 'Up to Rs. ${job.maxSalary!.toStringAsFixed(0)}';
    }
    return 'Salary not specified';
  }

  void _showJobActions(BuildContext context, ThemeData theme, Job job) {
    final quizProvider = context.read<QuizProvider>();
    final hasQuiz = quizProvider.jobHasQuiz(job.jobId);
    final quiz = quizProvider.getQuizForJob(job.jobId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: SingleChildScrollView(
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
              const SizedBox(height: 20),

              Text(
                job.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose an action',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 24),

              // Action: View Details
              _buildActionTile(
                context,
                icon: Icons.visibility_outlined,
                title: 'View Details',
                subtitle: 'See full job information',
                color: theme.primaryColor,
                onTap: () {
                  Navigator.pop(context);
                  _showJobDetails(context, theme, job);
                },
              ),

              const Divider(height: 24),

              // Action: View Applications
              _buildActionTile(
                context,
                icon: Icons.people_outline_rounded,
                title: 'View Applications',
                subtitle: 'See who applied for this job',
                color: Colors.indigo,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/company/job-applications', arguments: job);
                },
              ),

              const Divider(height: 24),

              // Action: Quiz (Add or View/Edit)
              _buildActionTile(
                context,
                icon: hasQuiz ? Icons.quiz : Icons.add_circle_outline,
                title: hasQuiz ? 'Manage Quiz' : 'Add Quiz',
                subtitle: hasQuiz 
                    ? '${quiz?.questions.length ?? 0} questions • ${quiz?.duration ?? 0} min'
                    : 'Create a screening quiz for applicants',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                  if (hasQuiz && quiz != null) {
                    Navigator.pushNamed(
                      context,
                      '/company/create-quiz',
                      arguments: {'quiz': quiz, 'job': job},
                    ).then((result) {
                      if (result != null && mounted) {
                        _refreshJobs();
                      }
                    });
                  } else {
                    Navigator.pushNamed(
                      context,
                      '/company/create-quiz',
                      arguments: job,
                    ).then((result) {
                      if (result != null && mounted) {
                        _refreshJobs();
                      }
                    });
                  }
                },
              ),

              const Divider(height: 24),

              // Action: Edit
              _buildActionTile(
                context,
                icon: Icons.edit_outlined,
                title: 'Edit Job',
                subtitle: 'Update job details',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _editJob(context, job);
                },
              ),

              const Divider(height: 24),

              // Action: Toggle Status
              _buildActionTile(
                context,
                icon: job.status == JobStatus.active
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                title: job.status == JobStatus.active ? 'Close Job' : 'Reopen Job',
                subtitle: job.status == JobStatus.active
                    ? 'Stop accepting applications'
                    : 'Start accepting applications again',
                color: job.status == JobStatus.active ? Colors.orange : Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _toggleJobStatus(context, job);
                },
              ),

              const Divider(height: 24),

              // Action: Delete
              _buildActionTile(
                context,
                icon: Icons.delete_outline,
                title: 'Delete Job',
                subtitle: 'Permanently remove this job',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _deleteJob(context, job);
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showJobDetails(BuildContext context, ThemeData theme, Job job) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
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
                      Text(
                        job.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildDetailRow(theme, Icons.work_outline, 'Job Type', _getJobTypeDisplay(job.jobType)),
                      const SizedBox(height: 12),
                      _buildDetailRow(theme, Icons.location_on_outlined, 'Location', job.location),
                      const SizedBox(height: 12),
                      _buildDetailRow(theme, Icons.school_outlined, 'Education', _getEducationDisplay(job.requiredEducation)),
                      if (job.minSalary != null || job.maxSalary != null) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(theme, Icons.attach_money_rounded, 'Salary', _getSalaryDisplay(job)),
                      ],
                      const SizedBox(height: 12),
                      _buildDetailRow(theme, Icons.calendar_today_outlined, 'Posted', _formatDate(job.postedDate)),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      Text(
                        'Description',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        job.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
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

  Widget _buildDetailRow(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _getEducationDisplay(EducationLevel level) {
    switch (level) {
      case EducationLevel.matric:
        return 'Matriculation';
      case EducationLevel.inter:
        return 'Intermediate';
      case EducationLevel.bs:
        return "Bachelor's Degree";
      case EducationLevel.ms:
        return "Master's Degree";
      case EducationLevel.phd:
        return 'PhD';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editJob(BuildContext context, Job job) {
    Navigator.pushNamed(
      context,
      '/company/create-job',
      arguments: job,
    ).then((result) {
      if (result == true && mounted) {
        _refreshJobs();
      }
    });
  }

  Future<void> _toggleJobStatus(BuildContext context, Job job) async {
    final newStatus = job.status == JobStatus.active ? JobStatus.closed : JobStatus.active;
    final statusText = newStatus == JobStatus.active ? 'reopened' : 'closed';

    try {
      job.status = newStatus;
      await context.read<JobProvider>().updateJob(job);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job $statusText successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteJob(BuildContext context, Job job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job?'),
        content: Text(
          'Are you sure you want to permanently delete "${job.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<JobProvider>().deleteJob(job.jobId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }
}
