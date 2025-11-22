import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/providers/providers.dart';
import 'package:project/models/models.dart';
import 'package:project/theme/app_theme.dart';
import 'package:project/screens/company/edit_company_profile_screen.dart';
import 'package:project/widgets/common/common_widgets.dart';
import 'package:project/screens/shared/settings_dialogs.dart';
import 'package:project/services/storage_service.dart';

class CompanyProfileTab extends StatefulWidget {
  const CompanyProfileTab({super.key});

  @override
  State<CompanyProfileTab> createState() => _CompanyProfileTabState();
}

class _CompanyProfileTabState extends State<CompanyProfileTab> {
  bool _isUploadingImage = false;

  Future<void> _handleImageUpload(Company user) async {
    final image = await StorageService.showImageSourcePicker(context);
    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final url = await StorageService.uploadProfilePicture(
        imageFile: image,
        userId: user.userId,
      );

      if (url != null && mounted) {
        // Update user model and save to Supabase
        user.logoUrl = url;
        await context.read<CompanyProvider>().updateCompany(user);
        if (!mounted) return;
        context.read<AuthProvider>().refreshCurrentUser(user);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logo updated successfully!'),
            backgroundColor: AppTheme.secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload logo: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final jobProvider = context.watch<JobProvider>();
    final user = authProvider.currentUser;

    if (user is! Company) return const SizedBox();

    final jobs = jobProvider.getJobsByCompany(user.companyId);
    final activeJobs = jobs.where((j) => j.status == JobStatus.active).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
            ProfileHeader(
              name: user.companyName,
              email: user.email,
              imageUrl: user.logoUrl,
              isImageLoading: _isUploadingImage,
              onImageTap: () => _handleImageUpload(user),
            ),

            const SizedBox(height: 24),

            // Stats Row
            ProfileStatsRow(
              stats: [
                ProfileStatData(
                  value: jobs.length.toString(),
                  label: 'Total Jobs',
                  icon: Icons.work_outline,
                  color: AppTheme.primaryColor,
                ),
                ProfileStatData(
                  value: activeJobs.toString(),
                  label: 'Active',
                  icon: Icons.check_circle_outline,
                  color: AppTheme.secondaryColor,
                ),
                ProfileStatData(
                  value: '0',
                  label: 'Views',
                  icon: Icons.visibility_outlined,
                  color: AppTheme.accentColor,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Company Description
            if (user.description.isNotEmpty) ...[
              ContentSection(
                title: 'About',
                content: Text(
                  user.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Menu Options
            MenuSection(
              items: [
                AppMenuItem(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditCompanyProfileScreen()),
                  ),
                ),
                AppMenuItem(
                  icon: Icons.lock_outline,
                  title: 'Privacy & Security',
                  onTap: () => SettingsDialogs.showPrivacyPolicyDialog(context),
                ),
                AppMenuItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () => SettingsDialogs.showHelpSupportDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Logout Button
            LogoutButton(
              onLogout: () => context.read<AuthProvider>().signOut(),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
