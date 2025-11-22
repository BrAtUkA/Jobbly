import 'package:flutter/material.dart';
import 'package:project/theme/app_theme.dart';

/// A gradient welcome card with user greeting, name, tagline, and avatar.
/// 
/// Supports both text initials and network image avatars.
/// 
/// Usage:
/// ```dart
/// WelcomeCard(
///   userName: 'John Doe',
///   tagline: 'Find your dream job today',
///   avatarUrl: user.pfp, // optional
/// )
/// ```
class WelcomeCard extends StatelessWidget {
  final String userName;
  final String tagline;
  final String? avatarUrl;
  final Color? gradientStart;
  final Color? gradientEnd;

  const WelcomeCard({
    super.key,
    required this.userName,
    required this.tagline,
    this.avatarUrl,
    this.gradientStart,
    this.gradientEnd,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String get _initial => userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startColor = gradientStart ?? AppTheme.primaryColor;
    final endColor = gradientEnd ?? AppTheme.primaryColor.withValues(alpha: 0.85);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tagline,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: avatarUrl != null && avatarUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                avatarUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildInitialText(),
              ),
            )
          : _buildInitialText(),
    );
  }

  Widget _buildInitialText() {
    return Text(
      _initial,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 28,
      ),
    );
  }
}
