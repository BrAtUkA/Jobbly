import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/providers/providers.dart';
import 'package:project/theme/app_theme.dart';
import 'package:project/screens/shared/settings_dialogs.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            _buildSectionTitle(theme, 'Account'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              theme,
              children: [
                _buildSettingsItem(
                  theme,
                  Icons.person_outline,
                  'Email',
                  subtitle: user?.email ?? 'Not logged in',
                ),
                _buildDivider(),
                _buildSettingsItem(
                  theme,
                  Icons.delete_outline,
                  'Delete Account',
                  textColor: AppTheme.errorColor,
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // App Section
            _buildSectionTitle(theme, 'App'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              theme,
              children: [
                _buildSettingsItem(
                  theme,
                  Icons.info_outline,
                  'About',
                  onTap: () => SettingsDialogs.showAboutDialog(context),
                ),
                _buildDivider(),
                _buildSettingsItem(
                  theme,
                  Icons.description_outlined,
                  'Terms of Service',
                  onTap: () => SettingsDialogs.showTermsOfServiceDialog(context),
                ),
                _buildDivider(),
                _buildSettingsItem(
                  theme,
                  Icons.privacy_tip_outlined,
                  'Privacy Policy',
                  onTap: () => SettingsDialogs.showPrivacyPolicyDialog(context),
                ),
                _buildDivider(),
                _buildSettingsItem(
                  theme,
                  Icons.help_outline,
                  'Help & Support',
                  onTap: () => SettingsDialogs.showHelpSupportDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // App Version
            Center(
              child: Text(
                'Version 1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildSettingsCard(ThemeData theme, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade100, indent: 56);
  }

  Widget _buildSettingsItem(
    ThemeData theme,
    IconData icon,
    String title, {
    String? subtitle,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: textColor ?? AppTheme.textSecondary, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final TextEditingController confirmController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            const Text('Delete Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action is permanent and cannot be undone. All your data, including:',
            ),
            const SizedBox(height: 12),
            _buildDeleteWarningItem('Your profile information'),
            _buildDeleteWarningItem('All your job postings or applications'),
            _buildDeleteWarningItem('Your quiz results and history'),
            const SizedBox(height: 16),
            const Text(
              'Type "DELETE" to confirm:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                hintText: 'DELETE',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (confirmController.text.toUpperCase() == 'DELETE') {
                // Close the confirmation dialog first
                Navigator.pop(context);
                
                // Get the root navigator context before any async operations
                final rootNavigator = Navigator.of(context, rootNavigator: true);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                
                // Show loading indicator using root navigator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  useRootNavigator: true,
                  builder: (dialogContext) => const PopScope(
                    canPop: false,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
                
                try {
                  await authProvider.deleteAccount();
                  
                  // Close loading dialog using root navigator
                  rootNavigator.pop();
                  
                  // Navigate to welcome screen and clear entire stack
                  // AuthWrapper will automatically show WelcomeScreen since user is no longer authenticated
                  rootNavigator.pushNamedAndRemoveUntil('/welcome', (route) => false);
                  
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: const Text('Account deleted successfully'),
                      backgroundColor: AppTheme.secondaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                } catch (e) {
                  // Close loading dialog
                  rootNavigator.pop();
                  
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error deleting account: $e'),
                      backgroundColor: AppTheme.errorColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please type DELETE to confirm'),
                    backgroundColor: AppTheme.accentColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.remove, size: 16, color: AppTheme.errorColor),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
