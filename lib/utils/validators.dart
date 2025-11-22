import 'package:flutter/services.dart';

/// Validation utilities for form inputs
class Validators {
  // Pre-compiled regex patterns for performance
  // RFC 5322 compliant email regex (matches Supabase validation)
  static final _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
  );
  // Phone: only allows digits, +, -, and spaces
  static final _phoneAllowedRegex = RegExp(r'^[0-9+\- ]*$');
  static final _phoneDigitsRegex = RegExp(r'[0-9]');
  
  /// Input formatter for phone fields - only allows digits, +, -, and spaces
  static final phoneInputFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'));
  static final _urlRegex = RegExp(r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$');
  static final _upperCaseRegex = RegExp(r'[A-Z]');
  static final _lowerCaseRegex = RegExp(r'[a-z]');
  static final _numberRegex = RegExp(r'[0-9]');
  static final _specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  // Email validation with proper regex (RFC 5322 compliant, matches Supabase)
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final trimmed = value.trim();
    
    // Supabase max email length is 255 characters
    if (trimmed.length > 255) {
      return 'Email is too long (max 255 characters)';
    }
    
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    
    // Disallow dots before @ to prevent duplicate accounts
    // (mail services like Gmail ignore dots, causing Supabase issues)
    final localPart = trimmed.split('@').first;
    if (localPart.contains('.')) {
      return 'Dots (.) are not allowed before the @ symbol';
    }
    
    return null;
  }

  // Password validation with strength requirements
  static String? password(String? value, {bool isSignup = false}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    // Supabase default minimum is 6 characters
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    if (isSignup) {
      // Recommend stronger passwords for better security
      if (value.length < 8) {
        return 'Password should be at least 8 characters for better security';
      }
      if (!_lowerCaseRegex.hasMatch(value) && !_upperCaseRegex.hasMatch(value)) {
        return 'Password must contain at least one letter';
      }
    }
    
    return null;
  }

  // Confirm password validation
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Required field validation
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? "This field"} is required';
    }
    return null;
  }

  // Phone number validation
  static String? phone(String? value, {bool isRequired = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Phone number is required' : null;
    }
    
    // Only allow digits, +, -, and spaces
    if (!_phoneAllowedRegex.hasMatch(value.trim())) {
      return 'Only digits, +, - and spaces are allowed';
    }
    
    // Count only digits for validation (not +, -, or spaces)
    final digitCount = _phoneDigitsRegex.allMatches(value).length;
    if (digitCount < 10) {
      return 'Phone number must have at least 10 digits';
    }
    
    return null;
  }

  // Name validation
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    return null;
  }

  // URL validation (optional)
  static String? url(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'URL is required' : null;
    }
    
    if (!_urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  // Minimum length validation
  static String? minLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? "This field"} is required';
    }
    
    if (value.trim().length < minLength) {
      return '${fieldName ?? "This field"} must be at least $minLength characters';
    }
    
    return null;
  }
}

/// Helper to get password strength indicator
class PasswordStrength {
  static double getStrength(String password) {
    if (password.isEmpty) return 0;
    
    double strength = 0;
    
    // Length
    if (password.length >= 8) strength += 0.2;
    if (password.length >= 12) strength += 0.2;
    
    // Has uppercase
    if (Validators._upperCaseRegex.hasMatch(password)) strength += 0.2;
    
    // Has lowercase
    if (Validators._lowerCaseRegex.hasMatch(password)) strength += 0.2;
    
    // Has number
    if (Validators._numberRegex.hasMatch(password)) strength += 0.1;
    
    // Has special char
    if (Validators._specialCharRegex.hasMatch(password)) strength += 0.1;
    
    return strength.clamp(0, 1);
  }
  
  static String getStrengthText(double strength) {
    if (strength < 0.3) return 'Weak';
    if (strength < 0.6) return 'Fair';
    if (strength < 0.8) return 'Good';
    return 'Strong';
  }
  
  static Color getStrengthColor(double strength) {
    if (strength < 0.3) return const Color(0xFFEF5350);
    if (strength < 0.6) return const Color(0xFFFF9800);
    if (strength < 0.8) return const Color(0xFF66BB6A);
    return const Color(0xFF4CAF50);
  }
}
