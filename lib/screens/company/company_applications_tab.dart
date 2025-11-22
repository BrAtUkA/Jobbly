import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/providers/providers.dart';
import 'package:project/models/models.dart';
import 'package:project/widgets/common/user_avatar.dart';

class CompanyApplicationsTab extends StatefulWidget {
  const CompanyApplicationsTab({super.key});

  @override
  State<CompanyApplicationsTab> createState() => _CompanyApplicationsTabState();
}

class _CompanyApplicationsTabState extends State<CompanyApplicationsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all';
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    await context.read<ApplicationProvider>().fetchAllApplicationsFromSupabase();
    if (!mounted) return;
    await context.read<JobProvider>().fetchAllJobsFromSupabase();
    if (!mounted) return;
    await context.read<SeekerProvider>().fetchAllSeekersFromSupabase();
  }

  List<Application> _getFilteredApplications(
    List<Application> allApplications,
    JobProvider jobProvider,
    SeekerProvider seekerProvider,
  ) {
    var filtered = allApplications;

    // Status Filter
    if (_filterStatus != 'all') {
      filtered = filtered.where((a) {
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

    // Search Filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((a) {
        final seeker = seekerProvider.getSeekerById(a.seekerId);
        final job = jobProvider.getJobById(a.jobId);
        
        final seekerName = seeker?.fullName.toLowerCase() ?? '';
        final jobTitle = job?.title.toLowerCase() ?? '';
        
        return seekerName.contains(query) || jobTitle.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final jobProvider = context.watch<JobProvider>();
    final applicationProvider = context.watch<ApplicationProvider>();
    final seekerProvider = context.watch<SeekerProvider>();
    final user = authProvider.currentUser;

    if (user is! Company) return const SizedBox();

    // Get all jobs for this company
    final companyJobs = jobProvider.getJobsByCompany(user.companyId);
    final companyJobIds = companyJobs.map((j) => j.jobId).toSet();

    // Get all applications for company's jobs
    final allApplications = applicationProvider.applications
        .where((a) => companyJobIds.contains(a.jobId))
        .toList();

    final filteredApplications = _getFilteredApplications(
      allApplications,
      jobProvider,
      seekerProvider,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Applications',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
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
                      hintText: 'Search applicants or jobs...',
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
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredApplications.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredApplications.length,
                      itemBuilder: (context, index) {
                        final application = filteredApplications[index];
                        return _buildApplicationCard(
                          context,
                          theme,
                          application,
                          jobProvider,
                          seekerProvider,
                          index,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
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
            'No Applications Found',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Applications will appear here when job seekers apply',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(
    BuildContext context,
    ThemeData theme,
    Application application,
    JobProvider jobProvider,
    SeekerProvider seekerProvider,
    int index,
  ) {
    final job = jobProvider.getJobById(application.jobId);
    final seeker = seekerProvider.getSeekerById(application.seekerId);
    final daysAgo = DateTime.now().difference(application.appliedDate).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showApplicationDetails(context, theme, application, job, seeker),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                UserAvatar(
                  imageUrl: seeker?.pfp,
                  name: seeker?.fullName ?? 'Unknown',
                  radius: 24,
                ),
                const SizedBox(width: 16),
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
                      Text(
                        job?.title ?? 'Unknown Job',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        daysAgo == 0
                            ? 'Applied today'
                            : daysAgo == 1
                                ? 'Applied yesterday'
                                : '$daysAgo days ago',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(theme, application.status),
              ],
            ),
          ),
        ),
      ),
    );
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
        borderRadius: BorderRadius.circular(8),
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

  void _showApplicationDetails(
    BuildContext context,
    ThemeData theme,
    Application application,
    Job? job,
    Seeker? seeker,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
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
                            radius: 32,
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
                      const Divider(),
                      const SizedBox(height: 24),

                      // Job Applied For
                      Text(
                        'Applied For',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.work_outline, color: theme.primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                job?.title ?? 'Unknown Job',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Seeker Details
                      Text(
                        'Applicant Details',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (seeker != null) ...[
                        _buildInfoRow(theme, Icons.email_outlined, seeker.email),
                        if (seeker.phone != null && seeker.phone!.isNotEmpty)
                          _buildInfoRow(theme, Icons.phone_outlined, seeker.phone!),
                        _buildInfoRow(theme, Icons.school_outlined, _getEducationDisplay(seeker.education)),
                        if (seeker.location != null && seeker.location!.isNotEmpty)
                          _buildInfoRow(theme, Icons.location_on_outlined, seeker.location!),
                        if (seeker.experience != null && seeker.experience!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Experience',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            seeker.experience!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ] else
                        Text(
                          'Applicant details not available',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Action Buttons
                      Text(
                        'Update Status',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (application.status != ApplicationStatus.reviewed)
                            _buildActionButton(
                              context,
                              application,
                              'Mark Reviewed',
                              ApplicationStatus.reviewed,
                              Colors.blue,
                            ),
                          if (application.status != ApplicationStatus.shortlisted)
                            _buildActionButton(
                              context,
                              application,
                              'Shortlist',
                              ApplicationStatus.shortlisted,
                              Colors.green,
                            ),
                          if (application.status != ApplicationStatus.rejected)
                            _buildActionButton(
                              context,
                              application,
                              'Reject',
                              ApplicationStatus.rejected,
                              Colors.red,
                            ),
                        ],
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

  Widget _buildInfoRow(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
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
  ) {
    return OutlinedButton(
      onPressed: () async {
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
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
      ),
      child: Text(label),
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
}