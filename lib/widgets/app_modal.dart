import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A reusable animated modal dialog for the app.
/// 
/// Use this for confirmations, alerts, success messages, etc.
class AppModal extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String title;
  final String message;
  final String primaryButtonText;
  final VoidCallback onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;
  final bool showSecondaryButton;

  const AppModal({
    super.key,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    required this.title,
    required this.message,
    required this.primaryButtonText,
    required this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.showSecondaryButton = false,
  });

  /// Shows a success modal (green checkmark)
  factory AppModal.success({
    Key? key,
    required String title,
    required String message,
    String buttonText = 'Got it',
    required VoidCallback onPressed,
  }) {
    return AppModal(
      key: key,
      icon: Icons.check_circle_rounded,
      iconColor: Colors.green,
      iconBackgroundColor: Colors.green.withValues(alpha: 0.1),
      title: title,
      message: message,
      primaryButtonText: buttonText,
      onPrimaryPressed: onPressed,
    );
  }

  /// Shows an error modal (red error icon)
  factory AppModal.error({
    Key? key,
    required String title,
    required String message,
    String buttonText = 'Got it',
    required VoidCallback onPressed,
  }) {
    return AppModal(
      key: key,
      icon: Icons.error_rounded,
      iconColor: Colors.red.shade400,
      iconBackgroundColor: Colors.red.withValues(alpha: 0.1),
      title: title,
      message: message,
      primaryButtonText: buttonText,
      onPrimaryPressed: onPressed,
    );
  }

  /// Shows a warning modal (orange warning icon)
  factory AppModal.warning({
    Key? key,
    required String title,
    required String message,
    String buttonText = 'Got it',
    required VoidCallback onPressed,
  }) {
    return AppModal(
      key: key,
      icon: Icons.warning_rounded,
      iconColor: Colors.orange,
      iconBackgroundColor: Colors.orange.withValues(alpha: 0.1),
      title: title,
      message: message,
      primaryButtonText: buttonText,
      onPrimaryPressed: onPressed,
    );
  }

  /// Shows an info modal (blue info icon)
  factory AppModal.info({
    Key? key,
    required String title,
    required String message,
    String buttonText = 'Got it',
    required VoidCallback onPressed,
  }) {
    return AppModal(
      key: key,
      icon: Icons.info_rounded,
      iconColor: Colors.blue,
      iconBackgroundColor: Colors.blue.withValues(alpha: 0.1),
      title: title,
      message: message,
      primaryButtonText: buttonText,
      onPrimaryPressed: onPressed,
    );
  }

  /// Shows a confirmation modal with two buttons
  factory AppModal.confirm({
    Key? key,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
    IconData icon = Icons.help_outline_rounded,
    Color? iconColor,
  }) {
    return AppModal(
      key: key,
      icon: icon,
      iconColor: iconColor ?? Colors.blue,
      iconBackgroundColor: (iconColor ?? Colors.blue).withValues(alpha: 0.1),
      title: title,
      message: message,
      primaryButtonText: confirmText,
      onPrimaryPressed: onConfirm,
      secondaryButtonText: cancelText,
      onSecondaryPressed: onCancel,
      showSecondaryButton: true,
    );
  }

  /// Shows an email verification modal
  factory AppModal.emailVerification({
    Key? key,
    required VoidCallback onContinue,
  }) {
    return AppModal(
      key: key,
      icon: Icons.mark_email_unread_rounded,
      title: 'Verify your email',
      message: 'We\'ve sent a verification link to your email address. Click the link to activate your account.',
      primaryButtonText: 'Got it',
      onPrimaryPressed: onContinue,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.primaryColor;
    final effectiveIconBgColor = iconBackgroundColor ?? theme.primaryColor.withValues(alpha: 0.1);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: effectiveIconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: effectiveIconColor,
              ),
            ).animate()
             .scale(duration: 400.ms, curve: Curves.easeOutBack)
             .then()
             .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.5)),

            const SizedBox(height: 24),

            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 16),

            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                height: 1.5,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 32),

            // Primary Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onPrimaryPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  primaryButtonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

            // Secondary Button (optional)
            if (showSecondaryButton && secondaryButtonText != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: onSecondaryPressed,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    secondaryButtonText!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.2, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}
