import 'package:flutter/material.dart';
import 'package:project/theme/app_theme.dart';
import 'package:project/models/models.dart';

/// Company info section showing company details
class CompanyCard extends StatelessWidget {
  final Company company;
  final String? title;

  const CompanyCard({
    super.key,
    required this.company,
    this.title = 'About the Company',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              _CompanyLogo(company: company),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.companyName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (company.website != null && company.website!.isNotEmpty)
                      Text(
                        company.website!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (company.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              company.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  final Company company;

  const _CompanyLogo({required this.company});

  static const double _size = 48;
  static const double _borderRadius = 12;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      child: company.logoUrl != null && company.logoUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(_borderRadius),
              child: Image.network(
                company.logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildInitial(),
              ),
            )
          : _buildInitial(),
    );
  }

  Widget _buildInitial() {
    return Center(
      child: Text(
        company.companyName.isNotEmpty 
            ? company.companyName[0].toUpperCase() 
            : 'C',
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: _size * 0.5,
        ),
      ),
    );
  }
}

/// Large company logo for headers
class CompanyLogoLarge extends StatelessWidget {
  final Company? company;
  final double size;

  const CompanyLogoLarge({
    super.key,
    this.company,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: company?.logoUrl != null && company!.logoUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                company!.logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildInitial(),
              ),
            )
          : _buildInitial(),
    );
  }

  Widget _buildInitial() {
    return Center(
      child: Text(
        company?.companyName.isNotEmpty == true
            ? company!.companyName[0].toUpperCase()
            : 'C',
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
    );
  }
}
