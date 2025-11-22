import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:project/providers/providers.dart';
import 'package:project/models/models.dart';
import 'package:project/theme/app_theme.dart';
import 'package:project/widgets/primary_button.dart';
import 'package:project/widgets/common/skill_selector.dart';
import 'package:project/widgets/common/avatar_picker.dart';
import 'package:project/services/storage_service.dart';
import 'package:project/utils/validators.dart';
import 'package:url_launcher/url_launcher.dart';

class EditSeekerProfileScreen extends StatefulWidget {
  const EditSeekerProfileScreen({super.key});

  @override
  State<EditSeekerProfileScreen> createState() => _EditSeekerProfileScreenState();
}

class _EditSeekerProfileScreenState extends State<EditSeekerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _experienceController;
  
  EducationLevel _selectedEducation = EducationLevel.bs;
  Set<String> _selectedSkillIds = {};
  
  bool _isLoading = false;
  bool _isUploadingResume = false;
  Seeker? _seeker;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _experienceController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSeekerData();
    });
  }

  void _loadSeekerData() {
    final authProvider = context.read<AuthProvider>();
    final seekerSkillProvider = context.read<SeekerSkillProvider>();
    final user = authProvider.currentUser;
    
    if (user is Seeker) {
      final seekerSkills = seekerSkillProvider.getSkillsForSeeker(user.seekerId);
      setState(() {
        _seeker = user;
        _fullNameController.text = user.fullName;
        _phoneController.text = user.phone ?? '';
        _locationController.text = user.location ?? '';
        _experienceController.text = user.experience ?? '';
        _selectedEducation = user.education;
        _selectedSkillIds = seekerSkills.map((s) => s.skillId).toSet();
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_seeker == null) return;

    setState(() => _isLoading = true);

    try {
      final seekerProvider = context.read<SeekerProvider>();
      final authProvider = context.read<AuthProvider>();
      final seekerSkillProvider = context.read<SeekerSkillProvider>();

      // Update seeker fields
      _seeker!.fullName = _fullNameController.text.trim();
      _seeker!.phone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
      _seeker!.location = _locationController.text.trim().isEmpty ? null : _locationController.text.trim();
      _seeker!.experience = _experienceController.text.trim().isEmpty ? null : _experienceController.text.trim();
      // Note: resumeUrl is updated separately via _pickAndUploadResume
      // Note: pfp is updated separately via AvatarPicker
      _seeker!.education = _selectedEducation;

      await seekerProvider.updateSeeker(_seeker!);

      // Update skills
      // First, get current skills
      final currentSkills = seekerSkillProvider.getSkillsForSeeker(_seeker!.seekerId);
      final currentSkillIds = currentSkills.map((s) => s.skillId).toSet();

      // Remove skills that were deselected
      for (final skillId in currentSkillIds) {
        if (!_selectedSkillIds.contains(skillId)) {
          await seekerSkillProvider.deleteSeekerSkill(_seeker!.seekerId, skillId);
        }
      }

      // Add new skills
      for (final skillId in _selectedSkillIds) {
        if (!currentSkillIds.contains(skillId)) {
          final seekerSkill = SeekerSkill(
            seekerId: _seeker!.seekerId,
            skillId: skillId,
          );
          await seekerSkillProvider.addSeekerSkill(seekerSkill);
        }
      }
      
      // Refresh auth provider's current user with updated data
      authProvider.refreshCurrentUser(_seeker!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: AppTheme.secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skillProvider = context.watch<SkillProvider>();
    final allSkills = skillProvider.skills;

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
          'Edit Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _seeker == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Picture Section
                            _buildProfilePictureSection(theme)
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

                            const SizedBox(height: 32),

                            // Full Name
                            _buildSectionTitle(theme, 'Full Name'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _fullNameController,
                              decoration: const InputDecoration(
                                hintText: 'Enter your full name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // Education Level
                            _buildSectionTitle(theme, 'Education Level'),
                            const SizedBox(height: 8),
                            _buildEducationDropdown(theme),

                            const SizedBox(height: 24),

                            // Phone
                            _buildSectionTitle(theme, 'Phone Number'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [Validators.phoneInputFormatter],
                              decoration: const InputDecoration(
                                hintText: 'Enter your phone number',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Location
                            _buildSectionTitle(theme, 'Location'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                hintText: 'Enter your location',
                                prefixIcon: Icon(Icons.location_on_outlined),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Experience
                            _buildSectionTitle(theme, 'Experience'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _experienceController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Describe your experience',
                                alignLabelWithHint: true,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Skills Section
                            _buildSectionTitle(theme, 'Skills'),
                            const SizedBox(height: 8),
                            SkillSelector(
                              skills: allSkills,
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

                            const SizedBox(height: 24),

                            // Resume Upload
                            _buildSectionTitle(theme, 'Resume (Optional)'),
                            const SizedBox(height: 8),
                            _buildResumeUploadSection(theme),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Save Button
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: PrimaryButton(
                      text: 'Save Changes',
                      onPressed: _isLoading ? null : _saveProfile,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfilePictureSection(ThemeData theme) {
    return Center(
      child: AvatarPickerWithLabel(
        imageUrl: _seeker?.pfp,
        fallbackText: _fullNameController.text,
        userId: _seeker?.userId ?? '',
        onImageUploaded: (url) {
          setState(() {
            _seeker?.pfp = url;
          });
        },
        label: 'Tap to change photo',
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildEducationDropdown(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<EducationLevel>(
          value: _selectedEducation,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: EducationLevel.values.map((level) {
            return DropdownMenuItem(
              value: level,
              child: Text(_formatEducation(level)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedEducation = value);
            }
          },
        ),
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

  Widget _buildResumeUploadSection(ThemeData theme) {
    final hasResume = _seeker?.resumeUrl != null && _seeker!.resumeUrl!.isNotEmpty;
    final fileName = hasResume 
        ? StorageService.getResumeFileName(_seeker!.resumeUrl!)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current resume info or placeholder
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasResume ? AppTheme.secondaryColor.withValues(alpha: 0.1) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasResume ? Icons.description_rounded : Icons.upload_file_rounded,
                  color: hasResume ? AppTheme.secondaryColor : Colors.grey.shade500,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasResume ? (fileName ?? 'Resume uploaded') : 'No resume uploaded',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: hasResume ? AppTheme.textPrimary : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasResume ? 'Tap to replace' : 'PDF, DOC, or DOCX',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isUploadingResume)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploadingResume ? null : _pickAndUploadResume,
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  label: Text(hasResume ? 'Replace' : 'Upload Resume'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              if (hasResume) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isUploadingResume ? null : _viewResume,
                  icon: const Icon(Icons.open_in_new_rounded),
                  tooltip: 'View Resume',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _isUploadingResume ? null : _deleteResume,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Remove Resume',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadResume() async {
    if (_seeker == null) return;

    final resumeFile = await StorageService.pickResume();
    if (resumeFile == null) return;

    setState(() => _isUploadingResume = true);

    try {
      final url = await StorageService.uploadResume(
        resumeFile: resumeFile,
        seekerId: _seeker!.seekerId,
      );

      if (url != null && mounted) {
        // Update local state
        setState(() {
          _seeker!.resumeUrl = url;
        });

        // Save to database immediately
        if (!mounted) return;
        final seekerProvider = context.read<SeekerProvider>();
        await seekerProvider.updateSeeker(_seeker!);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Resume uploaded successfully!'),
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
            content: Text('Failed to upload resume: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingResume = false);
    }
  }

  Future<void> _viewResume() async {
    if (_seeker?.resumeUrl == null) return;

    final uri = Uri.parse(_seeker!.resumeUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open resume'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _deleteResume() async {
    if (_seeker == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Resume?'),
        content: const Text('Are you sure you want to remove your resume?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUploadingResume = true);

    try {
      // Delete from storage
      await StorageService.deleteResume(seekerId: _seeker!.seekerId);

      // Update local state
      setState(() {
        _seeker!.resumeUrl = null;
      });

      // Save to database
      if (!mounted) return;
      final seekerProvider = context.read<SeekerProvider>();
      await seekerProvider.updateSeeker(_seeker!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Resume removed'),
            backgroundColor: Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove resume: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingResume = false);
    }
  }
}
