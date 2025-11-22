import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/providers/providers.dart';
import 'package:project/models/models.dart';
import 'package:project/theme/app_theme.dart';
import 'package:project/screens/seeker/job_detail_screen.dart';

class JobListingScreen extends StatefulWidget {
  const JobListingScreen({super.key});

  @override
  State<JobListingScreen> createState() => _JobListingScreenState();
}

class _JobListingScreenState extends State<JobListingScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  JobType? _selectedJobType;
  EducationLevel? _selectedEducation;
  String? _selectedLocation;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobProvider = context.watch<JobProvider>();
    final jobSkillProvider = context.watch<JobSkillProvider>();
    final skillProvider = context.watch<SkillProvider>();
    final applicationProvider = context.watch<ApplicationProvider>();
    final authProvider = context.watch<AuthProvider>();
    final seekerSkillProvider = context.watch<SeekerSkillProvider>();

    final user = authProvider.currentUser;
    if (user is! Seeker) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Get all active jobs
    final activeJobs = jobProvider.jobs.where((j) => j.status == JobStatus.active).toList();
    
    // Get applied job IDs
    final myApplications = applicationProvider.getApplicationsBySeeker(user.seekerId);
    final appliedJobIds = myApplications.map((a) => a.jobId).toSet();

    // Get seeker's skills for match calculation
    final seekerSkills = seekerSkillProvider.getSkillsForSeeker(user.seekerId);
    final seekerSkillIds = seekerSkills.map((s) => s.skillId).toSet();

    // Get unique locations for filter (case-insensitive deduplication)
    final locationMap = <String, String>{};
    for (final job in activeJobs) {
      final key = job.location.toLowerCase();
      if (!locationMap.containsKey(key)) {
        locationMap[key] = job.location;
      }
    }
    final locations = locationMap.values.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // Apply filters
    var filteredJobs = activeJobs.where((job) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = job.title.toLowerCase().contains(query);
        final matchesLocation = job.location.toLowerCase().contains(query);
        final matchesDescription = job.description.toLowerCase().contains(query);
        if (!matchesTitle && !matchesLocation && !matchesDescription) {
          return false;
        }
      }

      // Job type filter
      if (_selectedJobType != null && job.jobType != _selectedJobType) {
        return false;
      }

      // Education filter - show jobs with required education at or below selected level
      if (_selectedEducation != null && 
          job.requiredEducation.index > _selectedEducation!.index) {
        return false;
      }

      // Location filter (case-insensitive)
      if (_selectedLocation != null && 
          job.location.toLowerCase() != _selectedLocation!.toLowerCase()) {
        return false;
      }

      return true;
    }).toList();

    // Sort by posted date (newest first)
    filteredJobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () => jobProvider.fetchAllJobsFromSupabase(),
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
                  'Find Jobs',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),

            // Search and Filters
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Search Bar
                    _buildSearchBar(theme),
                    const SizedBox(height: 16),
                    // Filters
                    _buildFilters(theme, locations),
                    const SizedBox(height: 16),
                    // Results count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${filteredJobs.length} jobs found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (_hasActiveFilters())
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear Filters'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Job List
            if (filteredJobs.isEmpty)
              SliverToBoxAdapter(
                child: _buildEmptyState(theme),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final job = filteredJobs[index];
                      final isApplied = appliedJobIds.contains(job.jobId);
                      
                      // Calculate match percentage
                      final jobSkills = jobSkillProvider.getSkillsForJob(job.jobId);
                      final jobSkillIds = jobSkills.map((s) => s.skillId).toSet();
                      double matchPercentage = 100.0;
                      if (jobSkillIds.isNotEmpty) {
                        final matchingSkills = seekerSkillIds.intersection(jobSkillIds);
                        matchPercentage = (matchingSkills.length / jobSkillIds.length) * 100;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildJobCard(
                          context,
                          theme,
                          job,
                          matchPercentage,
                          isApplied,
                          jobSkillProvider,
                          skillProvider,
                        ),
                      );
                    },
                    childCount: filteredJobs.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
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
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search jobs, companies, or locations...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilters(ThemeData theme, List<String> locations) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            theme,
            'Job Type',
            _selectedJobType != null ? _formatJobType(_selectedJobType!) : null,
            () => _showJobTypeFilter(theme),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            theme,
            'Education',
            _selectedEducation != null ? _formatEducation(_selectedEducation!) : null,
            () => _showEducationFilter(theme),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            theme,
            'Location',
            _selectedLocation,
            () => _showLocationFilter(theme, locations),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    ThemeData theme,
    String label,
    String? selectedValue,
    VoidCallback onTap,
  ) {
    final isSelected = selectedValue != null;
    return Material(
      color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedValue ?? label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJobTypeFilter(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(
        theme,
        'Job Type',
        [null, ...JobType.values],
        _selectedJobType,
        (value) {
          setState(() => _selectedJobType = value);
          Navigator.pop(context);
        },
        (value) => value == null ? 'All Types' : _formatJobType(value),
      ),
    );
  }

  void _showEducationFilter(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(
        theme,
        'Education Level',
        [null, ...EducationLevel.values],
        _selectedEducation,
        (value) {
          setState(() => _selectedEducation = value);
          Navigator.pop(context);
        },
        (value) => value == null ? 'All Levels' : _formatEducation(value),
      ),
    );
  }

  void _showLocationFilter(ThemeData theme, List<String> locations) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _LocationFilterSheet(
        locations: locations,
        selectedLocation: _selectedLocation,
        onSelect: (value) {
          setState(() => _selectedLocation = value);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildFilterSheet<T>(
    ThemeData theme,
    String title,
    List<T?> options,
    T? selected,
    Function(T?) onSelect,
    String Function(T?) labelBuilder,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...options.map((option) => ListTile(
            title: Text(labelBuilder(option)),
            trailing: selected == option
                ? Icon(Icons.check_rounded, color: AppTheme.primaryColor)
                : null,
            onTap: () => onSelect(option),
          )),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty ||
        _selectedJobType != null ||
        _selectedEducation != null ||
        _selectedLocation != null;
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedJobType = null;
      _selectedEducation = null;
      _selectedLocation = null;
    });
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No jobs found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(
    BuildContext context,
    ThemeData theme,
    Job job,
    double matchPercentage,
    bool isApplied,
    JobSkillProvider jobSkillProvider,
    SkillProvider skillProvider,
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
                  // Status badge
                  if (isApplied)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Applied',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    )
                  else
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
                  if (job.minSalary != null || job.maxSalary != null) ...[
                    const SizedBox(width: 12),
                    _buildInfoChip(Icons.attach_money_rounded, _formatSalary(job)),
                  ],
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
              const SizedBox(height: 12),
              // Posted date
              Text(
                'Posted ${_formatDate(job.postedDate)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                ),
              ),
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

  String _formatEducation(EducationLevel level) {
    switch (level) {
      case EducationLevel.matric:
        return 'Matric';
      case EducationLevel.inter:
        return 'Intermediate';
      case EducationLevel.bs:
        return 'Bachelor\'s';
      case EducationLevel.ms:
        return 'Master\'s';
      case EducationLevel.phd:
        return 'PhD';
    }
  }

  String _formatSalary(Job job) {
    if (job.minSalary != null && job.maxSalary != null) {
      return '${_formatNumber(job.minSalary!)} - ${_formatNumber(job.maxSalary!)}';
    } else if (job.minSalary != null) {
      return '${_formatNumber(job.minSalary!)}+';
    } else if (job.maxSalary != null) {
      return 'Up to ${_formatNumber(job.maxSalary!)}';
    }
    return '';
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toStringAsFixed(0);
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
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
  }
}

/// Separate stateful widget for location filter with search
class _LocationFilterSheet extends StatefulWidget {
  final List<String> locations;
  final String? selectedLocation;
  final Function(String?) onSelect;

  const _LocationFilterSheet({
    required this.locations,
    required this.selectedLocation,
    required this.onSelect,
  });

  @override
  State<_LocationFilterSheet> createState() => _LocationFilterSheetState();
}

class _LocationFilterSheetState extends State<_LocationFilterSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Filter locations based on search query (case-insensitive)
    final filteredLocations = widget.locations
        .where((loc) => loc.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search location...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 8),
          // Location list - fixed height to prevent resizing during search
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // "All Locations" option (always show if no search or matches "all")
                if (_searchQuery.isEmpty || 'all locations'.contains(_searchQuery.toLowerCase()))
                  ListTile(
                    title: const Text('All Locations'),
                    trailing: widget.selectedLocation == null
                        ? Icon(Icons.check_rounded, color: AppTheme.primaryColor)
                        : null,
                    onTap: () => widget.onSelect(null),
                  ),
                // Filtered locations
                ...filteredLocations.map((location) => ListTile(
                  title: Text(location),
                  trailing: widget.selectedLocation?.toLowerCase() == location.toLowerCase()
                      ? Icon(Icons.check_rounded, color: AppTheme.primaryColor)
                      : null,
                  onTap: () => widget.onSelect(location),
                )),
                // Empty state
                if (filteredLocations.isEmpty && _searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No locations found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
