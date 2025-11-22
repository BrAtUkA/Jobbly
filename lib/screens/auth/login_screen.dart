import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:page_transition/page_transition.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project/providers/providers.dart';
import 'package:project/widgets/primary_button.dart';
import 'package:project/screens/auth/signup_screen.dart';
import 'package:project/screens/auth/forgot_password_screen.dart';
import 'package:project/utils/dialogs.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final ValueNotifier<bool> _obscurePassword = ValueNotifier(true);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _obscurePassword.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().signIn(
            _emailController.text.trim(),
            _passwordController.text,
          );
      
      if (mounted) {
        // Pop all screens to return to the AuthWrapper which will show the Home screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showAuthError(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showAuthError(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Shows a special dialog for unverified emails with a resend option
  void _showEmailNotVerifiedDialog() {
    bool isResending = false;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.mark_email_unread_rounded,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Email Not Verified',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please check your inbox and click the verification link we sent you.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Check your spam folder if you don\'t see it. Verification links expire after 24 hours.',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'OK',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            FilledButton.icon(
              onPressed: isResending
                  ? null
                  : () async {
                      final email = _emailController.text.trim();
                      // Capture before async gap
                      final scaffoldMessenger = ScaffoldMessenger.of(this.context);
                      final authProvider = this.context.read<AuthProvider>();
                      
                      if (email.isEmpty) {
                        Navigator.pop(dialogContext);
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Please enter your email first'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isResending = true);

                      try {
                        await authProvider.resendVerificationEmail(email);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: const Text('Verification email sent! Check your inbox.'),
                            backgroundColor: Colors.green.shade600,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isResending = false);
                        String errorMsg = 'Failed to resend email';
                        if (e.toString().contains('rate') || e.toString().contains('limit')) {
                          errorMsg = 'Please wait before requesting another email';
                        }
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(errorMsg),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              icon: isResending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(isResending ? 'Sending...' : 'Resend Email'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAuthError(String errorMessage) {
    String title;
    String message;
    
    // Map common error messages to user-friendly text
    final lowerError = errorMessage.toLowerCase();
    
    if (lowerError.contains('email not confirmed') || 
        lowerError.contains('verify your email')) {
      // Show special dialog with resend option for unverified emails
      _showEmailNotVerifiedDialog();
      return;
    } else if (lowerError.contains('invalid login credentials') || 
               lowerError.contains('invalid_credentials')) {
      title = 'Invalid Credentials';
      message = 'The email or password you entered is incorrect. Please try again or reset your password.';
    } else if (lowerError.contains('user not found')) {
      title = 'Account Not Found';
      message = 'No account exists with this email address. Please check your email or create a new account.';
    } else if (lowerError.contains('too many requests') || 
               lowerError.contains('rate limit')) {
      title = 'Too Many Attempts';
      message = 'You\'ve made too many login attempts. Please wait a few minutes before trying again.';
    } else if (lowerError.contains('network') || 
               lowerError.contains('connection') ||
               lowerError.contains('socket')) {
      title = 'Connection Error';
      message = 'Unable to connect to the server. Please check your internet connection and try again.';
    } else if (lowerError.contains('database error')) {
      title = 'Server Error';
      message = 'We\'re experiencing technical difficulties. Please try again in a few moments.';
    } else {
      title = 'Login Failed';
      message = 'Something went wrong while signing in. Please try again.';
    }
    
    AppDialogs.showErrorDialog(
      context,
      title: title,
      message: message,
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
              
              // Header
              Text(
                'Welcome Back! 👋',
                style: theme.textTheme.displayMedium,
              ).animate().fadeIn().slideX(begin: -0.1, end: 0),
              
              const SizedBox(height: 8),
              
              Text(
                'Enter your credentials to continue',
                style: theme.textTheme.bodyMedium,
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),

              const SizedBox(height: 48),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email Address',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'hello@example.com',
                            prefixIcon: Icon(Icons.email_outlined, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
                    
                    const SizedBox(height: 20),
                    
                    // Password Field
                    Column(
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
                        ValueListenableBuilder<bool>(
                          valueListenable: _obscurePassword,
                          builder: (context, obscure, _) {
                            return TextFormField(
                              controller: _passwordController,
                              obscureText: obscure,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _obscurePassword.value = !obscure;
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
                    
                    const SizedBox(height: 8),
                    
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageTransition(
                              type: PageTransitionType.rightToLeft,
                              child: const ForgotPasswordScreen(),
                              duration: const Duration(milliseconds: 400),
                              reverseDuration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOutCubic,
                            ),
                          );
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                    
                    const SizedBox(height: 32),
                    
                    PrimaryButton(
                      text: 'Login',
                      onPressed: _isLoading ? null : _login,
                      isLoading: _isLoading,
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 24),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              PageTransition(
                                type: PageTransitionType.rightToLeft,
                                child: const SignupScreen(),
                                duration: const Duration(milliseconds: 400),
                                reverseDuration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOutCubic,
                              ),
                            );
                          },
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ).animate().fadeIn(delay: 600.ms),
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
