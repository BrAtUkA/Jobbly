import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:project/providers/providers.dart';
import 'package:project/models/models.dart';
import 'package:project/widgets/primary_button.dart';
import 'package:project/widgets/common/avatar_picker.dart';
import 'package:project/utils/validators.dart';

class EditCompanyProfileScreen extends StatefulWidget {
  const EditCompanyProfileScreen({super.key});

  @override
  State<EditCompanyProfileScreen> createState() => _EditCompanyProfileScreenState();
}

class _EditCompanyProfileScreenState extends State<EditCompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _companyNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _websiteController;
  late TextEditingController _contactNoController;

  bool _isLoading = false;
  Company? _company;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _websiteController = TextEditingController();
    _contactNoController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCompanyData();
    });
  }

  void _loadCompanyData() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    
    if (user is Company) {
      setState(() {
        _company = user;
        _companyNameController.text = user.companyName;
        _descriptionController.text = user.description;
        _websiteController.text = user.website ?? '';
        _contactNoController.text = user.contactNo;
      });
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _contactNoController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_company == null) return;

    setState(() => _isLoading = true);

    try {
      final companyProvider = context.read<CompanyProvider>();
      final authProvider = context.read<AuthProvider>();

      // Update company fields
      _company!.companyName = _companyNameController.text.trim();
      _company!.description = _descriptionController.text.trim();
      _company!.website = _websiteController.text.trim().isEmpty 
          ? null 
          : _websiteController.text.trim();
      _company!.contactNo = _contactNoController.text.trim().isEmpty 
          ? '' 
          : _contactNoController.text.trim();
      // Note: logoUrl is updated separately via AvatarPicker

      await companyProvider.updateCompany(_company!);
      
      // Refresh auth provider's current user with updated data
      authProvider.refreshCurrentUser(_company!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: ${e.toString()}')),
        );
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
          'Edit Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _company == null
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
                            Center(
                              child: AvatarPickerWithLabel(
                                imageUrl: _company!.logoUrl,
                                fallbackText: _companyNameController.text,
                                userId: _company!.userId,
                                onImageUploaded: (url) {
                                  setState(() {
                                    _company!.logoUrl = url;
                                  });
                                },
                                label: 'Tap to change logo',
                              ),
                            ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

                            const SizedBox(height: 32),

                            // Company Name
                            _buildSectionTitle(theme, 'Company Name'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _companyNameController,
                              textInputAction: TextInputAction.next,
                              validator: (v) => Validators.minLength(v, 2, fieldName: 'Company name'),
                              decoration: const InputDecoration(
                                hintText: 'Enter company name',
                                prefixIcon: Icon(Icons.business_rounded, size: 20),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Description
                            _buildSectionTitle(theme, 'About Company'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 4,
                              maxLength: 500,
                              decoration: const InputDecoration(
                                hintText: 'Tell us about your company...',
                                alignLabelWithHint: true,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Website
                            _buildSectionTitle(theme, 'Website'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _websiteController,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.url,
                              validator: (v) {
                                if (v == null || v.isEmpty) return null;
                                return Validators.url(v);
                              },
                              decoration: const InputDecoration(
                                hintText: 'https://yourcompany.com',
                                prefixIcon: Icon(Icons.language_rounded, size: 20),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Contact Number
                            _buildSectionTitle(theme, 'Contact Number'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _contactNoController,
                              textInputAction: TextInputAction.done,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [Validators.phoneInputFormatter],
                              validator: (v) {
                                if (v == null || v.isEmpty) return null;
                                return Validators.phone(v);
                              },
                              decoration: const InputDecoration(
                                hintText: '+92 300 1234567',
                                prefixIcon: Icon(Icons.phone_outlined, size: 20),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Info Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Your company profile is visible to job seekers when they view your job postings.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Bottom Save Button
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: PrimaryButton(
                        text: 'Save Changes',
                        onPressed: _isLoading ? null : _saveProfile,
                        isLoading: _isLoading,
                        icon: Icons.check_rounded,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Colors.black87,
      ),
    );
  }
}
