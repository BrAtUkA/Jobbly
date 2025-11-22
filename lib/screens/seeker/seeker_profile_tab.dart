import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/providers/providers.dart';
import 'package:project/models/models.dart';
import 'package:project/theme/app_theme.dart';
import 'package:project/screens/seeker/edit_seeker_profile_screen.dart';
import 'package:project/screens/shared/settings_screen.dart';
import 'package:project/screens/shared/settings_dialogs.dart';
import 'package:project/widgets/common/common_widgets.dart';
import 'package:project/services/storage_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SeekerProfileTab extends StatefulWidget {
  const SeekerProfileTab({super.key});

  @override
  State<SeekerProfileTab> createState() => _SeekerProfileTabState();
}

class _SeekerProfileTabState extends State<SeekerProfileTab> {
  bool _isUploadingImage = false;

  Future<void> _handleImageUpload(Seeker user) async {
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
        user.pfp = url;
        await context.read<SeekerProvider>().updateSeeker(user);
        if (!mounted) return;
        context.read<AuthProvider>().refreshCurrentUser(user);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile picture updated!'),
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
            content: Text('Failed to upload image: $e'),
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
    final skillProvider = context.watch<SkillProvider>();
    final seekerSkillProvider = context.watch<SeekerSkillProvider>();
    final applicationProvider = context.watch<ApplicationProvider>();
    final user = authProvider.currentUser;

    if (user is! Seeker) return const SizedBox();

    // Get seeker's skills
    final seekerSkills = seekerSkillProvider.getSkillsForSeeker(user.seekerId);
    final skills = seekerSkills.map((ss) => skillProvider.getSkillById(ss.skillId)).whereType<Skill>().toList();

    // Get application stats
    final applications = applicationProvider.getApplicationsBySeeker(user.seekerId);
    final shortlistedCount = applications.where((a) => a.status == ApplicationStatus.shortlisted).length;

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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
            ProfileHeader(
              name: user.fullName,
              email: user.email,
              imageUrl: user.pfp,
              subtitle: user.location,
              subtitleIcon: Icons.location_on_outlined,
              isImageLoading: _isUploadingImage,
              onImageTap: () => _handleImageUpload(user),
            ),

            const SizedBox(height: 24),

            // Stats Row
            ProfileStatsRow(
              stats: [
                ProfileStatData(
                  value: applications.length.toString(),
                  label: 'Applications',
                  icon: Icons.description_outlined,
                  color: AppTheme.primaryColor,
                ),
                ProfileStatData(
                  value: shortlistedCount.toString(),
                  label: 'Shortlisted',
                  icon: Icons.star_outline_rounded,
                  color: AppTheme.secondaryColor,
                ),
                ProfileStatData(
                  value: skills.length.toString(),
                  label: 'Skills',
                  icon: Icons.lightbulb_outline,
                  color: AppTheme.accentColor,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Skills Section
            _buildSkillsSection(context, theme, skills),

            const SizedBox(height: 24),

            // Profile Details Section
            _buildDetailsSection(theme, user),

            const SizedBox(height: 24),

            // Menu Options
            MenuSection(
              items: [
                AppMenuItem(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditSeekerProfileScreen()),
                  ),
                ),
                AppMenuItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () => SettingsDialogs.showHelpSupportDialog(context),
                ),
                AppMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => SettingsDialogs.showPrivacyPolicyDialog(context),
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

  Widget _buildSkillsSection(BuildContext context, ThemeData theme, List<Skill> skills) {
    return ContentSection(
      title: 'My Skills',
      trailing: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditSeekerProfileScreen()),
        ),
        child: const Text('Edit'),
      ),
      content: skills.isEmpty
          ? _buildEmptySkills(theme)
          : SkillChipWrap(
              skills: skills.map((s) => s.skillName).toList(),
            ),
    );
  }

  Widget _buildEmptySkills(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.lightbulb_outline, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No skills added yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add your skills to get better job matches',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(ThemeData theme, Seeker user) {
    return ContentSection(
      title: 'Profile Details',
      content: Column(
        children: [
          DetailItem(
            icon: Icons.school_outlined,
            label: 'Education',
            value: _formatEducation(user.education),
          ),
          if (user.experience != null && user.experience!.isNotEmpty)
            DetailItem(
              icon: Icons.work_outline,
              label: 'Experience',
              value: user.experience!,
            ),
          if (user.phone != null && user.phone!.isNotEmpty)
            DetailItem(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: user.phone!,
            ),
          if (user.resumeUrl != null && user.resumeUrl!.isNotEmpty)
            DetailItem(
              icon: Icons.description_outlined,
              label: 'Resume',
              value: 'View Resume',
              isLink: true,
              onTap: () async {
                final uri = Uri.parse(user.resumeUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
        ],
      ),
    );
  }

  String _formatEducation(EducationLevel level) {
    switch (level) {
      case EducationLevel.matric:
        return 'Matriculation';
      case EducationLevel.inter:
        return 'Intermediate';
      case EducationLevel.bs:
        return 'Bachelor\'s Degree';
      case EducationLevel.ms:
        return 'Master\'s Degree';
      case EducationLevel.phd:
        return 'PhD';
    }
  }
}
