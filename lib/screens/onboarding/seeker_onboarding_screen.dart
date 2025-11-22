import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:project/providers/providers.dart';
import 'package:project/models/models.dart';
import 'package:project/widgets/primary_button.dart';
import 'package:project/widgets/common/avatar_picker.dart';
import 'package:project/widgets/common/skill_selector.dart';
import 'package:project/utils/validators.dart';
import 'package:project/utils/dialogs.dart';

class SeekerOnboardingScreen extends StatefulWidget {
  const SeekerOnboardingScreen({super.key});

  @override
  State<SeekerOnboardingScreen> createState() => _SeekerOnboardingScreenState();
}

class _SeekerOnboardingScreenState extends State<SeekerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _experienceController = TextEditingController();
  
  // Focus Nodes
  final _fullNameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _locationFocusNode = FocusNode();
  final _experienceFocusNode = FocusNode();

  // State
  int _currentStep = 0;
  bool _isForward = true;
  bool _isLoading = false;
  EducationLevel _selectedEducation = EducationLevel.bs;
  String? _pfpUrl;
  
  // Skills state - set of skill IDs (using the standardized skill selector)
  final Set<String> _selectedSkillIds = {};
  
  static const int _totalSteps = 5;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final user = context.read<AuthProvider>().currentUser;
    if (user is Seeker) {
      _fullNameController.text = user.fullName;
      _phoneController.text = user.phone ?? '';
      _locationController.text = user.location ?? '';
      _experienceController.text = user.experience ?? '';
      _selectedEducation = user.education;
      _pfpUrl = user.pfp;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _experienceController.dispose();
    _fullNameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _locationFocusNode.dispose();
    _experienceFocusNode.dispose();
    super.dispose();
  }

  bool get _isStep1Valid {
    return _fullNameController.text.trim().length >= 2 &&
           Validators.phone(_phoneController.text) == null;
  }

  void _nextStep() {
    if (_currentStep == 0 && !_isStep1Valid) {
      _showSnackBar('Please enter your full name');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isForward = true;
      _currentStep++;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      switch (_currentStep) {
        case 3:
          _experienceFocusNode.requestFocus();
          break;
      }
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

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final seekerProvider = context.read<SeekerProvider>();
      final seekerSkillProvider = context.read<SeekerSkillProvider>();
      final user = authProvider.currentUser;

      if (user == null || user is! Seeker) {
        throw Exception('Invalid user state');
      }

      // Update seeker data
      user.fullName = _fullNameController.text.trim();
      user.phone = _phoneController.text.trim();
      user.location = _locationController.text.trim().isEmpty 
          ? null 
          : _locationController.text.trim();
      user.education = _selectedEducation;
      user.experience = _experienceController.text.trim().isEmpty 
          ? null 
          : _experienceController.text.trim();
      user.pfp = _pfpUrl;

      // Save to Supabase and Hive
      await seekerProvider.updateSeeker(user);
      
      // Save skills - using skill IDs directly from the skill selector
      if (_selectedSkillIds.isNotEmpty) {
        final seekerSkillsToAdd = _selectedSkillIds.map((skillId) => SeekerSkill(
          seekerId: user.seekerId,
          skillId: skillId,
          proficiencyLevel: ProficiencyLevel.intermediate, // Default proficiency
        )).toList();
        
        await seekerSkillProvider.addSeekerSkills(seekerSkillsToAdd);
      }
      
      // Update auth provider's current user
      authProvider.refreshCurrentUser(user);
      
      // AuthWrapper will automatically show SeekerMainScreen now that needsOnboarding is false
      // No navigation needed - this keeps AuthWrapper in the widget tree for proper logout handling
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error saving profile: ${e.toString()}');
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
          // Header row with back button and logout
          Row(
            children: [
              if (_currentStep > 0)
                IconButton(
                  onPressed: _previousStep,
                  icon: const Icon(Icons.arrow_back_rounded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ).animate().fadeIn()
              else
                const SizedBox(width: 40),
              const Spacer(),
              TextButton.icon(
                onPressed: () => AppDialogs.showLogoutDialog(context),
                icon: Icon(Icons.logout_rounded, size: 18, color: Colors.grey.shade600),
                label: Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
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
        return 'Personal Information';
      case 1:
        return 'Education Level';
      case 2:
        return 'Your Experience';
      case 3:
        return 'Skills & Expertise';
      case 4:
        return 'Review & Finish';
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
        return _buildStep1PersonalInfo(theme);
      case 1:
        return _buildStep2Education(theme);
      case 2:
        return _buildStep3Experience(theme);
      case 3:
        return _buildStep4Skills(theme);
      case 4:
        return _buildStep5Review(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1PersonalInfo(ThemeData theme) {
    return Container(
      key: const ValueKey(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          // Profile Picture
          Center(
            child: Builder(
              builder: (context) {
                final user = context.read<AuthProvider>().currentUser;
                return AvatarPickerWithLabel(
                  imageUrl: _pfpUrl,
                  fallbackText: _fullNameController.text.isNotEmpty 
                      ? _fullNameController.text 
                      : 'U',
                  userId: user?.userId ?? '',
                  onImageUploaded: (url) {
                    setState(() {
                      _pfpUrl = url;
                    });
                  },
                  radius: 50,
                  label: _pfpUrl != null ? 'Tap to change photo' : 'Tap to add photo',
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Full Name',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _fullNameController,
            focusNode: _fullNameFocusNode,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _phoneFocusNode.requestFocus(),
            validator: (v) => Validators.minLength(v, 2, fieldName: 'Full name'),
            decoration: const InputDecoration(
              hintText: 'e.g., John Doe',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Phone Number',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            focusNode: _phoneFocusNode,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.phone,
            inputFormatters: [Validators.phoneInputFormatter],
            onFieldSubmitted: (_) => _locationFocusNode.requestFocus(),
            validator: Validators.phone,
            decoration: const InputDecoration(
              hintText: '+92 300 1234567',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Text(
                'Location',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              _buildOptionalBadge(theme),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _locationController,
            focusNode: _locationFocusNode,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'e.g., Lahore, Pakistan',
              prefixIcon: Icon(Icons.location_on_outlined, size: 20),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Companies will use your phone number to contact you for interviews.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.primaryColor,
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

  Widget _buildOptionalBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Optional',
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade600,
          fontSize: 9,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildStep2Education(ThemeData theme) {
    return Container(
      key: const ValueKey(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          Text(
            'Select your highest education level',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          
          const SizedBox(height: 24),
          
          ..._buildEducationOptions(theme),
        ],
      ),
    );
  }

  List<Widget> _buildEducationOptions(ThemeData theme) {
    final educationLevels = [
      {'level': EducationLevel.matric, 'title': 'Matriculation', 'subtitle': 'Secondary School Certificate'},
      {'level': EducationLevel.inter, 'title': 'Intermediate', 'subtitle': 'Higher Secondary Certificate'},
      {'level': EducationLevel.bs, 'title': "Bachelor's Degree", 'subtitle': 'BS / BA / BBA / etc.'},
      {'level': EducationLevel.ms, 'title': "Master's Degree", 'subtitle': 'MS / MA / MBA / etc.'},
      {'level': EducationLevel.phd, 'title': 'Doctorate (PhD)', 'subtitle': 'Doctor of Philosophy'},
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

  Widget _buildStep3Experience(ThemeData theme) {
    return Container(
      key: const ValueKey(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          Row(
            children: [
              Text(
                'Work Experience',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              _buildOptionalBadge(theme),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _experienceController,
            focusNode: _experienceFocusNode,
            maxLines: 6,
            maxLength: 1000,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'Describe your work experience, previous roles, achievements, and key responsibilities...',
              alignLabelWithHint: true,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Tips for a great experience summary:',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          
          _buildTip(theme, '• Mention years of experience in your field'),
          _buildTip(theme, '• List notable companies you\'ve worked with'),
          _buildTip(theme, '• Highlight key achievements with numbers'),
          _buildTip(theme, '• Keep it concise but informative'),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, size: 20, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Fresh graduate? No worries! You can mention internships, projects, or volunteer work.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.amber.shade800,
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

  Widget _buildTip(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildStep4Skills(ThemeData theme) {
    final skills = context.watch<SkillProvider>().skills;

    return Container(
      key: const ValueKey(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          Text(
            'Select skills that match your expertise',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          
          const SizedBox(height: 16),
          
          SkillSelector(
            skills: skills,
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
          ),
        ],
      ),
    );
  }

  Widget _buildStep5Review(ThemeData theme) {
    return Container(
      key: const ValueKey(4),
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
                Icons.check_circle_outline_rounded,
                size: 48,
                color: theme.primaryColor,
              ),
            ),
          ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.elasticOut),
          
          const SizedBox(height: 24),
          
          Center(
            child: Text(
              'You\'re all set!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 8),
          
          Center(
            child: Text(
              'Review your profile before starting your job search',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(delay: 250.ms),
          
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
              children: [
                _buildReviewItem(
                  theme,
                  Icons.person_outline_rounded,
                  'Full Name',
                  _fullNameController.text.trim(),
                ),
                const Divider(height: 24),
                _buildReviewItem(
                  theme,
                  Icons.phone_outlined,
                  'Phone',
                  _phoneController.text.trim(),
                ),
                const Divider(height: 24),
                _buildReviewItem(
                  theme,
                  Icons.school_outlined,
                  'Education',
                  _getEducationDisplayName(_selectedEducation),
                ),
                if (_locationController.text.trim().isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildReviewItem(
                    theme,
                    Icons.location_on_outlined,
                    'Location',
                    _locationController.text.trim(),
                  ),
                ],
                if (_experienceController.text.trim().isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildReviewItem(
                    theme,
                    Icons.work_outline_rounded,
                    'Experience',
                    _experienceController.text.trim().length > 50
                        ? '${_experienceController.text.trim().substring(0, 50)}...'
                        : _experienceController.text.trim(),
                  ),
                ],
                if (_selectedSkillIds.isNotEmpty) ...[
                  const Divider(height: 24),
                  Builder(
                    builder: (context) {
                      final skills = context.read<SkillProvider>().skills;
                      final selectedNames = _selectedSkillIds
                          .map((id) => skills.firstWhere(
                                (s) => s.skillId == id,
                                orElse: () => Skill(skillId: '', skillName: 'Unknown', category: SkillCategory.other),
                              ).skillName)
                          .where((name) => name != 'Unknown')
                          .toList();
                      return _buildReviewItem(
                        theme,
                        Icons.star_outline_rounded,
                        'Skills',
                        selectedNames.take(3).join(', ') +
                            (selectedNames.length > 3 ? ' +${selectedNames.length - 3} more' : ''),
                      );
                    },
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
          
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
              label: const Text('Edit information'),
            ),
          ),
        ],
      ),
    );
  }

  String _getEducationDisplayName(EducationLevel level) {
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
        return 'Doctorate (PhD)';
    }
  }

  Widget _buildReviewItem(ThemeData theme, IconData icon, String label, String value) {
    return Row(
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
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? '-' : value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _currentStep < _totalSteps - 1
            ? ListenableBuilder(
                listenable: Listenable.merge([_fullNameController, _phoneController]),
                builder: (context, _) {
                  final isValid = _currentStep == 0 ? _isStep1Valid : true;
                  
                  return PrimaryButton(
                    text: 'Continue',
                    onPressed: isValid ? _nextStep : null,
                  );
                },
              )
            : PrimaryButton(
                text: 'Start Job Search',
                onPressed: _isLoading ? null : _completeOnboarding,
                isLoading: _isLoading,
                icon: Icons.search_rounded,
              ),
      ),
    );
  }
}
