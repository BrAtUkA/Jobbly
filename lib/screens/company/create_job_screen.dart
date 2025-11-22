import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:project/providers/providers.dart';
import 'package:project/models/models.dart';
import 'package:project/widgets/primary_button.dart';
import 'package:project/widgets/common/skill_selector.dart';
import 'package:project/utils/validators.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _minSalaryController = TextEditingController();
  final _maxSalaryController = TextEditingController();
  
  // Focus Nodes
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _locationFocusNode = FocusNode();
  final _minSalaryFocusNode = FocusNode();
  final _maxSalaryFocusNode = FocusNode();

  // State
  int _currentStep = 0;
  bool _isForward = true;
  bool _isLoading = false;
  JobType _selectedJobType = JobType.fullTime;
  EducationLevel _selectedEducation = EducationLevel.bs;
  
  // Edit mode
  Job? _editingJob;
  bool get _isEditMode => _editingJob != null;
  
  // Skills state - now stores skillId
  Set<String> _selectedSkillIds = {};
  
  static const int _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    // Check for edit mode after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Job) {
        _initEditMode(args);
      }
    });
  }

  void _initEditMode(Job job) {
    setState(() {
      _editingJob = job;
      _titleController.text = job.title;
      _descriptionController.text = job.description;
      _locationController.text = job.location;
      if (job.minSalary != null) {
        _minSalaryController.text = job.minSalary!.toStringAsFixed(0);
      }
      if (job.maxSalary != null) {
        _maxSalaryController.text = job.maxSalary!.toStringAsFixed(0);
      }
      _selectedJobType = job.jobType;
      _selectedEducation = job.requiredEducation;
    });
    
    // Load existing job skills
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final jobSkillProvider = context.read<JobSkillProvider>();
      final existingSkills = jobSkillProvider.getSkillsForJob(job.jobId);
      setState(() {
        _selectedSkillIds = existingSkills.map((js) => js.skillId).toSet();
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _locationFocusNode.dispose();
    _minSalaryFocusNode.dispose();
    _maxSalaryFocusNode.dispose();
    super.dispose();
  }

  bool get _isStep1Valid {
    return _titleController.text.trim().length >= 3 &&
           _descriptionController.text.trim().length >= 50 &&
           _locationController.text.trim().isNotEmpty;
  }

  void _nextStep() {
    if (_currentStep == 0 && !_isStep1Valid) {
      _showSnackBar('Please fill in all required fields correctly');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isForward = true;
      _currentStep++;
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

  Future<void> _saveJob() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final jobProvider = context.read<JobProvider>();
      final jobSkillProvider = context.read<JobSkillProvider>();
      final user = authProvider.currentUser;

      if (user == null || user is! Company) {
        throw Exception('Invalid user state');
      }

      // Parse salary values
      double? minSalary;
      double? maxSalary;
      
      if (_minSalaryController.text.trim().isNotEmpty) {
        minSalary = double.tryParse(_minSalaryController.text.trim());
      }
      if (_maxSalaryController.text.trim().isNotEmpty) {
        maxSalary = double.tryParse(_maxSalaryController.text.trim());
      }

      // Validate salary range
      if (minSalary != null && maxSalary != null && minSalary > maxSalary) {
        _showSnackBar('Minimum salary cannot be greater than maximum salary');
        setState(() => _isLoading = false);
        return;
      }

      if (_isEditMode) {
        // Update existing job
        _editingJob!.title = _titleController.text.trim();
        _editingJob!.description = _descriptionController.text.trim();
        _editingJob!.location = _locationController.text.trim();
        _editingJob!.minSalary = minSalary;
        _editingJob!.maxSalary = maxSalary;
        _editingJob!.jobType = _selectedJobType;
        _editingJob!.requiredEducation = _selectedEducation;

        await jobProvider.updateJob(_editingJob!);
        
        // Update job skills
        if (_selectedSkillIds.isNotEmpty) {
          final newJobSkills = _selectedSkillIds.map((skillId) => JobSkill(
            jobId: _editingJob!.jobId,
            skillId: skillId,
          )).toList();
          await jobSkillProvider.updateJobSkills(
            _editingJob!.jobId,
            newJobSkills,
          );
        } else {
          await jobSkillProvider.deleteAllSkillsForJob(_editingJob!.jobId);
        }
        
        if (mounted) {
          Navigator.pop(context, true);
          _showSnackBar('Job updated successfully!');
        }
      } else {
        // Create new job
        final jobData = {
          'companyId': user.companyId,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'location': _locationController.text.trim(),
          'minSalary': minSalary,
          'maxSalary': maxSalary,
          'jobType': _selectedJobType.name,
          'requiredEducation': _selectedEducation.name,
          'postedDate': DateTime.now().toIso8601String(),
          'status': JobStatus.active.name,
        };

        final createdJob = await jobProvider.addJob(jobData);
        
        // Save job skills
        if (_selectedSkillIds.isNotEmpty) {
          final jobSkills = _selectedSkillIds.map((skillId) => JobSkill(
            jobId: createdJob.jobId,
            skillId: skillId,
          )).toList();
          await jobSkillProvider.addJobSkills(jobSkills);
        }
        
        if (mounted) {
          Navigator.pop(context, true);
          _showSnackBar('Job posted successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error ${_isEditMode ? 'updating' : 'posting'} job: ${e.toString()}');
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
          _isEditMode ? 'Edit Job' : 'Post a Job',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
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
          // Progress bar
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
        return 'Job Details';
      case 1:
        return 'Requirements & Skills';
      case 2:
        return 'Review & Post';
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
        return _buildStep1JobDetails(theme);
      case 1:
        return _buildStep2Requirements(theme);
      case 2:
        return _buildStep3Review(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1JobDetails(ThemeData theme) {
    return Container(
      key: const ValueKey(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          Text(
            'Job Title',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _descriptionFocusNode.requestFocus(),
            validator: (v) => Validators.minLength(v, 3, fieldName: 'Job title'),
            decoration: const InputDecoration(
              hintText: 'e.g., Senior Flutter Developer',
              prefixIcon: Icon(Icons.work_outline_rounded, size: 20),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Job Description',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            focusNode: _descriptionFocusNode,
            maxLines: 6,
            maxLength: 2000,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'Describe the role, responsibilities, and what makes this opportunity great...',
              alignLabelWithHint: true,
              counterText: "",
            ),
          ),
          
          const SizedBox(height: 8),
          
          ListenableBuilder(
            listenable: _descriptionController,
            builder: (context, _) {
              final text = _descriptionController.text;
              final length = text.trim().length;
              final rawLength = text.length;
              final isValid = length >= 50;
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          isValid ? Icons.check_circle : Icons.info_outline,
                          size: 16,
                          color: isValid ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isValid 
                                ? 'Great description!' 
                                : 'At least 50 characters (${50 - length} more)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isValid ? Colors.green : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$rawLength/2000',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Location',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _locationController,
            focusNode: _locationFocusNode,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _minSalaryFocusNode.requestFocus(),
            validator: Validators.required,
            decoration: const InputDecoration(
              hintText: 'e.g., Lahore, Pakistan (Remote options available)',
              prefixIcon: Icon(Icons.location_on_outlined, size: 20),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Job Type',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: JobType.values.map((type) {
              final isSelected = _selectedJobType == type;
              return ChoiceChip(
                label: Text(_getJobTypeDisplay(type)),
                selected: isSelected,
                showCheckmark: false,
                onSelected: (selected) {
                  setState(() => _selectedJobType = type);
                },
                selectedColor: theme.primaryColor.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: isSelected ? theme.primaryColor : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? theme.primaryColor : Colors.grey.shade300,
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Salary Range',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _minSalaryController,
                  focusNode: _minSalaryFocusNode,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (_) => _maxSalaryFocusNode.requestFocus(),
                  decoration: InputDecoration(
                    hintText: 'Min (PKR)',
                    prefixIcon: Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        'Rs.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _maxSalaryController,
                  focusNode: _maxSalaryFocusNode,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Max (PKR)',
                    prefixIcon: Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        'Rs.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildStep2Requirements(ThemeData theme) {
    return Container(
      key: const ValueKey(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          Text(
            'Minimum Education Required',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          
          ..._buildEducationOptions(theme),
          
          const SizedBox(height: 32),
          
          Text(
            'Required Skills',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select skills candidates must have for this role',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          
          Consumer<SkillProvider>(
            builder: (context, skillProvider, _) {
              return SkillSelector(
                skills: skillProvider.skills,
                selectedSkillIds: _selectedSkillIds,
                onSkillToggled: (skillId, selected) {
                  setState(() {
                    if (selected) {
                      _selectedSkillIds.add(skillId);
                    } else {
                      _selectedSkillIds.remove(skillId);
                    }
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEducationOptions(ThemeData theme) {
    final educationLevels = [
      {'level': EducationLevel.matric, 'title': 'Matriculation', 'subtitle': 'Secondary School'},
      {'level': EducationLevel.inter, 'title': 'Intermediate', 'subtitle': 'Higher Secondary'},
      {'level': EducationLevel.bs, 'title': "Bachelor's Degree", 'subtitle': 'BS / BA / BBA'},
      {'level': EducationLevel.ms, 'title': "Master's Degree", 'subtitle': 'MS / MA / MBA'},
      {'level': EducationLevel.phd, 'title': 'Doctorate', 'subtitle': 'PhD'},
    ];

    return educationLevels.map((edu) {
      final level = edu['level'] as EducationLevel;
      final isSelected = _selectedEducation == level;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => setState(() => _selectedEducation = level),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? theme.primaryColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected 
                  ? theme.primaryColor.withValues(alpha: 0.05) 
                  : Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? theme.primaryColor : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: isSelected ? theme.primaryColor : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        edu['title'] as String,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        edu['subtitle'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildStep3Review(ThemeData theme) {
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
              'Review Your Job Posting',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Center(
            child: Text(
              'Make sure everything looks good before posting',
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
                // Title and Type Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _titleController.text.trim(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getJobTypeDisplay(_selectedJobType),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                _buildReviewItem(
                  theme,
                  Icons.location_on_outlined,
                  _locationController.text.trim(),
                ),
                
                const SizedBox(height: 8),
                
                if (_minSalaryController.text.trim().isNotEmpty || 
                    _maxSalaryController.text.trim().isNotEmpty)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PKR',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getSalaryDisplay(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                
                const Divider(height: 32),
                
                Text(
                  'Description',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _descriptionController.text.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const Divider(height: 32),
                
                Text(
                  'Requirements',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                
                _buildReviewItem(
                  theme,
                  Icons.school_outlined,
                  'Min. ${_getEducationDisplay(_selectedEducation)}',
                ),
                
                if (_selectedSkillIds.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Required Skills (${_selectedSkillIds.length})',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<SkillProvider>(
                    builder: (context, skillProvider, _) {
                      final selectedSkills = skillProvider.skills
                          .where((s) => _selectedSkillIds.contains(s.skillId))
                          .toList();
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: selectedSkills.take(5).map((skill) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  skill.skillName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (selectedSkills.length > 5)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '+${selectedSkills.length - 5} more',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
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
              label: const Text('Edit job details'),
            ),
          ),
        ],
      ),
    );
  }

  String _getSalaryDisplay() {
    final min = _minSalaryController.text.trim();
    final max = _maxSalaryController.text.trim();
    
    if (min.isNotEmpty && max.isNotEmpty) {
      return '$min - $max';
    } else if (min.isNotEmpty) {
      return 'From $min';
    } else if (max.isNotEmpty) {
      return 'Up to $max';
    }
    return '';
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

  Widget _buildReviewItem(ThemeData theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
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
                        _descriptionController,
                        _locationController,
                      ]),
                      builder: (context, _) {
                        final isValid = _currentStep == 0 ? _isStep1Valid : true;
                        
                        return PrimaryButton(
                          text: 'Continue',
                          onPressed: isValid ? _nextStep : null,
                        );
                      },
                    )
                  : PrimaryButton(
                      text: _isEditMode ? 'Update Job' : 'Post Job',
                      onPressed: _isLoading ? null : _saveJob,
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
