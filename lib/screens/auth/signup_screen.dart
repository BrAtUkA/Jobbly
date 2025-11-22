import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:project/providers/providers.dart';
import 'package:project/models/models.dart';
import 'package:project/widgets/primary_button.dart';
import 'package:project/widgets/user_type_toggle.dart';
import 'package:project/widgets/app_modal.dart';
import 'package:project/utils/validators.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Focus Nodes
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  // State
  UserType _selectedType = UserType.seeker;
  bool _isLoading = false;
  bool _obscurePassword = true;
  int _currentStep = 0;
  bool _isForward = true;

  // Regex for password validation (Optimization: compiled once)
  static final _letterRegex = RegExp(r'[a-zA-Z]');
  static final _numberSpecialRegex = RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]');

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  bool get _isStep1Valid {
    return _nameController.text.trim().isNotEmpty &&
           _nameController.text.trim().length >= 2 &&
           _emailController.text.trim().isNotEmpty &&
           Validators.email(_emailController.text) == null;
  }

  bool get _isStep2Valid {
    return Validators.password(_passwordController.text, isSignup: true) == null &&
           _passwordController.text.isNotEmpty &&
           _confirmPasswordController.text.isNotEmpty &&
           _confirmPasswordController.text == _passwordController.text;
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await context.read<AuthProvider>().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        userType: _selectedType,
        name: _nameController.text.trim(),
        // Optional fields skipped for now (Onboarding flow later)
        description: null,
        contactNo: null,
        education: null,
      );

      if (success && mounted) {
        Navigator.pop(context); // Go back to login/welcome
        
        // Show custom verification modal
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AppModal.emailVerification(
            onContinue: () => Navigator.pop(context),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        
        // Check if it's a duplicate email error
        if (errorMessage.contains('already exists')) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => AppModal.error(
              title: 'Email Already Exists',
              message: 'An account with this email address already exists. Please sign in instead or use a different email.',
              buttonText: 'Got it',
              onPressed: () => Navigator.pop(context),
            ),
          );
        } else {
          // Show generic error modal for other errors
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => AppModal.error(
              title: 'Signup Failed',
              message: errorMessage.replaceAll('Exception: ', ''),
              buttonText: 'Try Again',
              onPressed: () => Navigator.pop(context),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_isStep1Valid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields correctly')),
        );
        return;
      }

      // Optimization: Unfocus first to prevent keyboard resize lag during animation
      FocusScope.of(context).unfocus();

      setState(() {
        _isForward = true;
        _currentStep = 1;
      });
      
      // Optimization: Delay focus request until animation completes
      // This prevents frame drops caused by simultaneous layout animation and keyboard appearance
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && _currentStep == 1) {
          _passwordFocusNode.requestFocus();
        }
      });
    }
  }

  Widget _buildStep1(ThemeData theme) {
    return Container(
      color: Colors.white,
      child: Column(
        key: const ValueKey(0),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedType == UserType.company ? 'Company Name' : 'Full Name',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
            validator: (value) => Validators.minLength(
              value, 
              2, 
              fieldName: _selectedType == UserType.company ? 'Company name' : 'Full name'
            ),
            decoration: InputDecoration(
              hintText: _selectedType == UserType.company ? 'Acme Corp' : 'John Doe',
              prefixIcon: Icon(
                _selectedType == UserType.company ? Icons.business : Icons.person_outline,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'Email Address',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: Listenable.merge([_nameController, _emailController]),
            builder: (context, _) {
              return TextFormField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                textInputAction: _isStep1Valid ? TextInputAction.next : TextInputAction.none,
                onFieldSubmitted: _isStep1Valid ? (_) => _nextStep() : null,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                decoration: const InputDecoration(
                  hintText: 'hello@example.com',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return Container(
      color: Colors.white,
      child: Column(
        key: const ValueKey(1),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: _passwordController,
            builder: (context, _) {
              final password = _passwordController.text;
              
              // Criteria
              final hasMinLength = password.length >= 8;
              final hasLetters = _letterRegex.hasMatch(password);
              final hasNumberOrSpecial = _numberSpecialRegex.hasMatch(password);
              
              // Calculate score (0-3)
              int score = 0;
              if (password.isNotEmpty) {
                if (hasMinLength) score++;
                if (hasLetters) score++;
                if (hasNumberOrSpecial) score++;
              }

              // Determine color and text
              Color statusColor;
              String statusText;

              if (score == 3) {
                statusColor = const Color(0xFF4CAF50); // Green
                statusText = 'Strong password';
              } else if (score == 2) {
                statusColor = const Color(0xFFFF9800); // Orange
                List<String> missing = [];
                if (!hasMinLength) missing.add("at least 8 characters");
                if (!hasLetters) missing.add("letters");
                if (!hasNumberOrSpecial) missing.add("number/symbol");
                statusText = 'Add ${missing.join(", ")}';
              } else {
                statusColor = const Color(0xFFEF5350); // Red
                List<String> missing = [];
                if (!hasMinLength) missing.add("at least 8 characters");
                if (!hasLetters) missing.add("letters");
                if (!hasNumberOrSpecial) missing.add("number/symbol");
                statusText = 'Add ${missing.join(", ")}';
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
                    obscureText: _obscurePassword,
                    validator: (value) => Validators.password(value, isSignup: true),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: password.isEmpty ? const SizedBox(width: double.infinity, height: 0) : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        // Password strength bars
                        Row(
                          children: [
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: score >= 1 ? statusColor : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: score >= 2 ? statusColor : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: score >= 3 ? statusColor : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Feedback text
                        Text(
                          statusText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          Text(
            'Confirm Password',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: Listenable.merge([_passwordController, _confirmPasswordController]),
            builder: (context, _) {
              return TextFormField(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocusNode,
                textInputAction: _isStep2Valid ? TextInputAction.done : TextInputAction.none,
                onFieldSubmitted: (_isStep2Valid && !_isLoading) ? (_) => _signup() : null,
                obscureText: _obscurePassword,
                validator: (value) => Validators.confirmPassword(value, _passwordController.text),
                decoration: const InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: Icon(Icons.lock_outline, size: 20),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              Text(
                'Create Account',
                style: theme.textTheme.displayMedium,
              ).animate().fadeIn().slideX(begin: -0.1, end: 0),
              
              const SizedBox(height: 8),
              
              Text(
                'Join Jobbly to find your dream job or candidate',
                style: theme.textTheme.bodyMedium,
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
              
              const SizedBox(height: 12),
              
              // Progress Indicator
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: _currentStep >= 1 ? theme.primaryColor : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.05, end: 0),
              
              const SizedBox(height: 8),
              
              Text(
                _currentStep == 0 ? 'Step 1 of 2 • Basic Info' : 'Step 2 of 2 • Set Password',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 28),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // User Type Toggle (Animated)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: SizedBox(
                        height: _currentStep == 0 ? null : 0,
                        child: Column(
                          children: [
                            UserTypeToggle(
                              selectedType: _selectedType,
                              onTypeChanged: (type) => setState(() => _selectedType = type),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),

                    // Animated Step Content
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                        return Stack(
                          alignment: Alignment.topLeft,
                          children: <Widget>[
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        final offsetAnimation = Tween<Offset>(
                          begin: _isForward 
                              ? (child.key == const ValueKey(1) ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0))
                              : (child.key == const ValueKey(0) ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0)),
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
                      },
                      child: _currentStep == 0 
                        ? _buildStep1(theme) 
                        : _buildStep2(theme),
                    ),
                    
                    const SizedBox(height: 32),

                    // Navigation Buttons
                    if (_currentStep == 0)
                      ListenableBuilder(
                        listenable: Listenable.merge([_nameController, _emailController]),
                        builder: (context, _) {
                          return PrimaryButton(
                            text: 'Next',
                            onPressed: _isStep1Valid ? _nextStep : null,
                            isLoading: false,
                          );
                        },
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0)
                    else
                      Column(
                        children: [
                          ListenableBuilder(
                            listenable: Listenable.merge([_passwordController, _confirmPasswordController]),
                            builder: (context, _) {
                              return PrimaryButton(
                                text: 'Create Account',
                                onPressed: (_isStep2Valid && !_isLoading) ? _signup : null,
                                isLoading: _isLoading,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => setState(() {
                              _isForward = false;
                              _currentStep = 0;
                            }),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_back, size: 16, color: theme.primaryColor),
                                const SizedBox(width: 4),
                                Text('Back to Basic Info', style: TextStyle(color: theme.primaryColor)),
                              ],
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Removed _UserTypeButton as it is replaced by AnimatedToggleSwitch
