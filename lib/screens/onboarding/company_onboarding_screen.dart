import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:project/providers/providers.dart';
import 'package:project/models/models.dart';
import 'package:project/widgets/primary_button.dart';
import 'package:project/widgets/common/avatar_picker.dart';
import 'package:project/utils/validators.dart';
import 'package:project/utils/dialogs.dart';

class CompanyOnboardingScreen extends StatefulWidget {
  const CompanyOnboardingScreen({super.key});

  @override
  State<CompanyOnboardingScreen> createState() => _CompanyOnboardingScreenState();
}

class _CompanyOnboardingScreenState extends State<CompanyOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _companyNameController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  
  // Focus Nodes
  final _companyNameFocusNode = FocusNode();
  final _contactNoFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _websiteFocusNode = FocusNode();

  // State
  int _currentStep = 0;
  bool _isForward = true;
  bool _isLoading = false;
  String? _logoUrl;
  
  static const int _totalSteps = 4;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final user = context.read<AuthProvider>().currentUser;
    if (user is Company) {
      _companyNameController.text = user.companyName;
      _contactNoController.text = user.contactNo;
      _descriptionController.text = user.description;
      _websiteController.text = user.website ?? '';
      _logoUrl = user.logoUrl;
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _contactNoController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _companyNameFocusNode.dispose();
    _contactNoFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _websiteFocusNode.dispose();
    super.dispose();
  }

  bool get _isStep1Valid {
    return _companyNameController.text.trim().length >= 2 &&
           Validators.phone(_contactNoController.text) == null;
  }

  bool get _isStep2Valid {
    return _descriptionController.text.trim().length >= 20;
  }

  // Step 3 (online presence) is optional, always valid
  bool get _isStep3Valid => true;

  void _nextStep() {
    // Validate current step
    if (_currentStep == 0 && !_isStep1Valid) {
      _showSnackBar('Please fill in all required fields correctly');
      return;
    }
    if (_currentStep == 1 && !_isStep2Valid) {
      _showSnackBar('Description must be at least 20 characters');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isForward = true;
      _currentStep++;
    });

    // Request focus for next step's first field
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      switch (_currentStep) {
        case 1:
          _descriptionFocusNode.requestFocus();
          break;
        case 2:
          _websiteFocusNode.requestFocus();
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
      final companyProvider = context.read<CompanyProvider>();
      final user = authProvider.currentUser;

      if (user == null || user is! Company) {
        throw Exception('Invalid user state');
      }

      // Update company data
      user.companyName = _companyNameController.text.trim();
      user.contactNo = _contactNoController.text.trim();
      user.description = _descriptionController.text.trim();
      user.website = _websiteController.text.trim().isEmpty 
          ? null 
          : _websiteController.text.trim();
      user.logoUrl = _logoUrl;

      // Save to Supabase and Hive
      await companyProvider.updateCompany(user);
      
      // Update auth provider's current user
      authProvider.refreshCurrentUser(user);
      
      // AuthWrapper will automatically show CompanyMainScreen now that needsOnboarding is false
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
            // Progress Header
            _buildProgressHeader(theme),
            
            // Content
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
            
            // Bottom Navigation
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
          
          // Step info
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
        return 'Basic Information';
      case 1:
        return 'About Your Company';
      case 2:
        return 'Online Presence';
      case 3:
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
        return _buildStep1BasicInfo(theme);
      case 1:
        return _buildStep2About(theme);
      case 2:
        return _buildStep3OnlinePresence(theme);
      case 3:
        return _buildStep4Review(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1BasicInfo(ThemeData theme) {
    return Container(
      key: const ValueKey(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          Text(
            'Company Name',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _companyNameController,
            focusNode: _companyNameFocusNode,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _contactNoFocusNode.requestFocus(),
            validator: (v) => Validators.minLength(v, 2, fieldName: 'Company name'),
            decoration: const InputDecoration(
              hintText: 'e.g., Acme Corporation',
              prefixIcon: Icon(Icons.business_rounded, size: 20),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Contact Number',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _contactNoController,
            focusNode: _contactNoFocusNode,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.phone,
            inputFormatters: [Validators.phoneInputFormatter],
            validator: Validators.phone,
            decoration: const InputDecoration(
              hintText: '+92 300 1234567',
              prefixIcon: Icon(Icons.phone_rounded, size: 20),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Helper text
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
                    'This information will be visible to job seekers.',
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

  Widget _buildStep2About(ThemeData theme) {
    return Container(
      key: const ValueKey(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          Text(
            'Company Description',
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
            maxLength: 500,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'Tell job seekers about your company, culture, and what makes you unique...',
              alignLabelWithHint: true,
            ),
          ),
          
          const SizedBox(height: 8),
          
          ListenableBuilder(
            listenable: _descriptionController,
            builder: (context, _) {
              final length = _descriptionController.text.trim().length;
              final isValid = length >= 20;
              
              return Row(
                children: [
                  Icon(
                    isValid ? Icons.check_circle : Icons.info_outline,
                    size: 16,
                    color: isValid ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isValid 
                        ? 'Great description!' 
                        : 'At least 20 characters (${20 - length} more)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isValid ? Colors.green : Colors.grey.shade600,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep3OnlinePresence(ThemeData theme) {
    return Container(
      key: const ValueKey(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          // Optional badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Optional',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 10,
                height: 1.2,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Website',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _websiteController,
            focusNode: _websiteFocusNode,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.url,
            validator: (v) => Validators.url(v, isRequired: false),
            decoration: const InputDecoration(
              hintText: 'https://www.yourcompany.com',
              prefixIcon: Icon(Icons.language_rounded, size: 20),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Company Logo Upload
          Text(
            'Company Logo',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Builder(
              builder: (context) {
                final user = context.read<AuthProvider>().currentUser;
                return AvatarPickerWithLabel(
                  imageUrl: _logoUrl,
                  fallbackText: _companyNameController.text.isNotEmpty 
                      ? _companyNameController.text 
                      : 'C',
                  userId: user?.userId ?? '',
                  onImageUploaded: (url) {
                    setState(() {
                      _logoUrl = url;
                    });
                  },
                  radius: 50,
                  label: _logoUrl != null ? 'Tap to change logo' : 'Tap to add logo',
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 20,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Companies with logos get 2x more applications!',
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

  Widget _buildStep4Review(ThemeData theme) {
    return Container(
      key: const ValueKey(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          // Success icon
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
              'Almost there!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 8),
          
          Center(
            child: Text(
              'Review your company profile before finishing',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
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
                  Icons.business_rounded,
                  'Company Name',
                  _companyNameController.text.trim(),
                ),
                const Divider(height: 24),
                _buildReviewItem(
                  theme,
                  Icons.phone_rounded,
                  'Contact',
                  _contactNoController.text.trim(),
                ),
                const Divider(height: 24),
                _buildReviewItem(
                  theme,
                  Icons.description_rounded,
                  'About',
                  _descriptionController.text.trim().length > 50
                      ? '${_descriptionController.text.trim().substring(0, 50)}...'
                      : _descriptionController.text.trim(),
                ),
                if (_websiteController.text.trim().isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildReviewItem(
                    theme,
                    Icons.language_rounded,
                    'Website',
                    _websiteController.text.trim(),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
          
          const SizedBox(height: 16),
          
          // Edit hint
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
                listenable: Listenable.merge([
                  _companyNameController,
                  _contactNoController,
                  _descriptionController,
                ]),
                builder: (context, _) {
                  final isValid = _currentStep == 0 
                      ? _isStep1Valid 
                      : _currentStep == 1 
                          ? _isStep2Valid 
                          : _isStep3Valid;
                  
                  return PrimaryButton(
                    text: 'Continue',
                    onPressed: isValid ? _nextStep : null,
                  );
                },
              )
            : PrimaryButton(
                text: 'Complete Setup',
                onPressed: _isLoading ? null : _completeOnboarding,
                isLoading: _isLoading,
                icon: Icons.check_rounded,
              ),
      ),
    );
  }
}
