import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project/theme/app_theme.dart';
import 'package:project/services/storage_service.dart';

/// A reusable avatar picker widget with upload functionality.
/// 
/// Displays a circular avatar with a camera icon overlay.
/// Tapping opens the image source picker and handles upload to Supabase Storage.
/// 
/// Used in:
/// - Profile tabs (pencil icon on avatar)
/// - Edit profile screens
/// - Onboarding screens
class AvatarPicker extends StatefulWidget {
  /// Current image URL (network image)
  final String? imageUrl;
  
  /// Fallback text when no image (usually initials)
  final String fallbackText;
  
  /// User ID for storage path
  final String userId;
  
  /// Called when upload completes successfully with the new URL
  final ValueChanged<String> onImageUploaded;
  
  /// Avatar radius (default 60)
  final double radius;
  
  /// Whether to show the edit/camera overlay
  final bool showEditOverlay;
  
  /// Custom icon for the overlay (default: camera_alt)
  final IconData overlayIcon;
  
  /// Whether the widget is in a loading state
  final bool isLoading;

  const AvatarPicker({
    super.key,
    this.imageUrl,
    required this.fallbackText,
    required this.userId,
    required this.onImageUploaded,
    this.radius = 60,
    this.showEditOverlay = true,
    this.overlayIcon = Icons.camera_alt,
    this.isLoading = false,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  bool _isUploading = false;

  String _getInitials(String text) {
    if (text.isEmpty) return '?';
    final parts = text.trim().split(' ');
    if (parts.length == 1) return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Future<void> _handleTap() async {
    if (_isUploading || widget.isLoading) return;

    // Show image source picker
    final XFile? image = await StorageService.showImageSourcePicker(context);
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      // Upload to Supabase Storage
      final url = await StorageService.uploadProfilePicture(
        imageFile: image,
        userId: widget.userId,
      );

      if (url != null && mounted) {
        widget.onImageUploaded(url);
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
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = _isUploading || widget.isLoading;
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: widget.showEditOverlay ? _handleTap : null,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Avatar
          CircleAvatar(
            radius: widget.radius,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            backgroundImage: hasImage ? NetworkImage(widget.imageUrl!) : null,
            child: isLoading
                ? SizedBox(
                    width: widget.radius,
                    height: widget.radius,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                : !hasImage
                    ? Text(
                        _getInitials(widget.fallbackText),
                        style: TextStyle(
                          fontSize: widget.radius * 0.6,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : null,
          ),
          
          // Edit overlay
          if (widget.showEditOverlay && !isLoading)
            Container(
              padding: EdgeInsets.all(widget.radius * 0.12),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: widget.radius * 0.05,
                ),
              ),
              child: Icon(
                widget.overlayIcon,
                size: widget.radius * 0.3,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

/// A compact avatar picker for use in onboarding/form contexts.
/// Shows "Tap to add photo" text below the avatar.
class AvatarPickerWithLabel extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final String userId;
  final ValueChanged<String> onImageUploaded;
  final double radius;
  final String? label;
  final bool isLoading;

  const AvatarPickerWithLabel({
    super.key,
    this.imageUrl,
    required this.fallbackText,
    required this.userId,
    required this.onImageUploaded,
    this.radius = 60,
    this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AvatarPicker(
          imageUrl: imageUrl,
          fallbackText: fallbackText,
          userId: userId,
          onImageUploaded: onImageUploaded,
          radius: radius,
          isLoading: isLoading,
        ),
        const SizedBox(height: 8),
        Text(
          label ?? (hasImage ? 'Tap to change photo' : 'Tap to add photo'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
