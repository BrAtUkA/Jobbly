import 'package:flutter/material.dart';

/// A reusable avatar widget that displays a user's profile picture or initials.
///
/// Handles null/empty image URLs gracefully with fallback to initials.
/// Includes error handling for broken image URLs.
///
/// Usage:
/// ```dart
/// UserAvatar(
///   imageUrl: seeker?.pfp,
///   name: seeker?.fullName ?? 'Unknown',
///   radius: 28,
/// )
/// ```
class UserAvatar extends StatelessWidget {
  /// The URL of the profile picture. Can be null or empty.
  final String? imageUrl;

  /// The name used to generate initials as fallback.
  final String name;

  /// The radius of the avatar (default: 24).
  final double radius;

  /// Background color when showing initials (default: primary color with 0.1 alpha).
  final Color? backgroundColor;

  /// Text color for initials (default: primary color).
  final Color? foregroundColor;

  /// Font size for initials. If null, calculated based on radius.
  final double? fontSize;

  /// Font weight for initials (default: FontWeight.bold).
  final FontWeight fontWeight;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    this.radius = 24,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize,
    this.fontWeight = FontWeight.bold,
  });

  /// Extracts initials from a name.
  /// Returns first letter of first and last word, or single letter if one word.
  /// Returns '?' if name is empty.
  static String getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  bool get _hasValidImage => imageUrl != null && imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.primaryColor.withValues(alpha: 0.1);
    final fgColor = foregroundColor ?? theme.primaryColor;
    final textSize = fontSize ?? (radius * 0.7);

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      backgroundImage: _hasValidImage ? NetworkImage(imageUrl!) : null,
      onBackgroundImageError: _hasValidImage
          ? (exception, stackTrace) {
              // Silently handle image load errors - will show initials instead
              debugPrint('Failed to load avatar image: $exception');
            }
          : null,
      child: _hasValidImage
          ? null
          : Text(
              getInitials(name),
              style: TextStyle(
                color: fgColor,
                fontWeight: fontWeight,
                fontSize: textSize,
              ),
            ),
    );
  }
}

/// A light-themed avatar variant for use on dark backgrounds.
///
/// Uses white with transparency for background and white text.
class UserAvatarLight extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final double? fontSize;

  const UserAvatarLight({
    super.key,
    required this.imageUrl,
    required this.name,
    this.radius = 24,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return UserAvatar(
      imageUrl: imageUrl,
      name: name,
      radius: radius,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      foregroundColor: Colors.white,
      fontSize: fontSize,
    );
  }
}
