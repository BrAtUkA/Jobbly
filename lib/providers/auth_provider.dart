import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class AuthProvider with ChangeNotifier {
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  
  User? _currentUser;
  User? get currentUser => _currentUser;
  
  bool _isProfileLoading = false;
  bool get isProfileLoading => _isProfileLoading;
  
  // Flag to prevent auth listener from interfering during account deletion
  bool _isAccountDeleted = false;
  
  // Flag to prevent auth listener from interfering during sign out
  bool _isSigningOut = false;

  bool get isAuthenticated => _supabase.auth.currentUser != null && _currentUser != null;
  
  Future<void> init() async {
    _isProfileLoading = true;
    notifyListeners();

    // Ensure boxes are open
    if (!Hive.isBoxOpen('companiesBox')) await Hive.openBox('companiesBox');
    if (!Hive.isBoxOpen('seekersBox')) await Hive.openBox('seekersBox');

    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen(
      (data) async {
        // Ignore events if we are in the process of signing out
        if (_isSigningOut) return;

        final event = data.event;
        final session = data.session;

        if (event == supabase.AuthChangeEvent.signedOut) {
          _currentUser = null;
          _isProfileLoading = false;
          notifyListeners();
        } else if (session != null && (event == supabase.AuthChangeEvent.signedIn || 
                   event == supabase.AuthChangeEvent.tokenRefreshed || 
                   event == supabase.AuthChangeEvent.initialSession)) {
          // Set loading state while fetching user data
          _isProfileLoading = true;
          notifyListeners();
          
          try {
            await _loadUserFromHive(session.user.id);
          } finally {
            _isProfileLoading = false;
            notifyListeners();
          }
        }
      },
      onError: (error, stackTrace) async {
        // Handle auth errors gracefully (e.g., session refresh failures)
        debugPrint('Auth state change error: $error');
        
        // Skip handling if account was intentionally deleted
        if (_isAccountDeleted) {
          debugPrint('Ignoring auth error - account was deleted');
          return;
        }
        
        // If session recovery fails, sign out the user to allow fresh login
        if (error is supabase.AuthException || 
            error.toString().contains('AuthRetryableFetchException')) {
          debugPrint('Session recovery failed, signing out user');
          _currentUser = null;
          // Clear the corrupted session locally only to avoid hanging
          try {
            await _supabase.auth.signOut(scope: supabase.SignOutScope.local);
          } catch (e) {
            debugPrint('Error during sign out after auth failure: $e');
          }
          notifyListeners();
        }
      },
    );

    // Initial check with error handling
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        // Verify the session is still valid by checking expiry
        final expiresAt = session.expiresAt;
        if (expiresAt != null) {
          final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
          if (expiryTime.isBefore(DateTime.now())) {
            // Session expired, try to refresh
            debugPrint('Session expired, attempting refresh...');
            try {
              await _supabase.auth.refreshSession();
              final refreshedSession = _supabase.auth.currentSession;
              if (refreshedSession != null) {
                await _loadUserFromHive(refreshedSession.user.id);
              }
            } catch (e) {
              debugPrint('Session refresh failed: $e');
              // Clear expired session
              await _supabase.auth.signOut();
              _currentUser = null;
            }
          } else {
            await _loadUserFromHive(session.user.id);
          }
        } else {
          await _loadUserFromHive(session.user.id);
        }
      }
    } catch (e) {
      debugPrint('Error during initial session check: $e');
      // Clear potentially corrupted session
      try {
        await _supabase.auth.signOut();
      } catch (signOutError) {
        debugPrint('Error signing out: $signOutError');
      }
      _currentUser = null;
    }
    
    _isProfileLoading = false;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    _isProfileLoading = true;
    notifyListeners();
    
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        if (response.user!.emailConfirmedAt == null) {
          await _supabase.auth.signOut();
          throw const supabase.AuthException('Please verify your email before signing in.');
        }
        await _loadUserFromHive(response.user!.id);
      }
    } catch (e) {
      rethrow;
    } finally {
      _isProfileLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required UserType userType,
    // Common fields
    required String name, // Company Name or Full Name
    // Company specific
    String? description,
    String? contactNo,
    // Seeker specific
    EducationLevel? education,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'https://jobbly-app.web.app/email_verified.html',
        data: {
          'user_type': userType.name,
          'name': name,
          'description': description,
          'contact_no': contactNo,
          'education': education?.name,
        },
      );

      // Check if signup was actually successful
      // Supabase returns a user even for duplicate emails, but identities will be empty
      if (response.user == null) {
        return false;
      }
      
      // If identities is empty, the email already exists
      if (response.user!.identities == null || response.user!.identities!.isEmpty) {
        throw Exception('An account with this email already exists. Please sign in instead.');
      }

      final userId = response.user!.id;
      final createdAt = DateTime.now();

        // Create local data regardless of session state (email verification might be pending)
        if (userType == UserType.company) {
          final company = Company(
            userId: userId,
            email: email,
            password: 'secured_by_supabase', // Placeholder
            createdAt: createdAt,
            companyId: userId, // Using same ID for simplicity
            companyName: name,
            description: description ?? '',
            contactNo: contactNo ?? '',
          );
          
          final box = Hive.box('companiesBox');
          await box.put(userId, company.toMap());

          // Note: Supabase insertion is now handled by a Database Trigger on auth.users
          
          // Only set current user if session is active (no email verification required)
          if (response.session != null) {
            _currentUser = company;
            notifyListeners();
          }
        } else {
          final seeker = Seeker(
            userId: userId,
            email: email,
            password: 'secured_by_supabase', // Placeholder
            createdAt: createdAt,
            seekerId: userId, // Using same ID for simplicity
            fullName: name,
            education: education ?? EducationLevel.matric,
          );
          
          final box = Hive.box('seekersBox');
          await box.put(userId, seeker.toMap());

          // Note: Supabase insertion is now handled by a Database Trigger on auth.users
          
          // Only set current user if session is active (no email verification required)
          if (response.session != null) {
            _currentUser = seeker;
            notifyListeners();
          }
        }
        
        // Return true if signup was successful (even if email verification is pending)
        return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    _isSigningOut = true;
    try {
      // Store user info before clearing for cache cleanup
      final userId = _supabase.auth.currentUser?.id;
      final userType = _currentUser?.userType;
      
      // Clear Hive cache for current user to prevent stale data
      if (userId != null) {
        try {
          if (userType == UserType.company) {
            final companiesBox = Hive.box('companiesBox');
            await companiesBox.delete(userId);
          } else if (userType == UserType.seeker) {
            final seekersBox = Hive.box('seekersBox');
            await seekersBox.delete(userId);
          }
        } catch (e) {
          debugPrint('Error clearing Hive cache on logout: $e');
        }
      }
      
      // Sign out from Supabase
      await _supabase.auth.signOut();
      
      // Clear local state
      _currentUser = null;
      _isProfileLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('signOut error: $e');
      rethrow;
    } finally {
      // Add a small delay to ensure any pending auth events are processed
      // while _isSigningOut is still true
      await Future.delayed(const Duration(milliseconds: 500));
      _isSigningOut = false;
    }
  }

  /// Delete the current user's account permanently
  /// This will delete all user data due to CASCADE in foreign keys
  Future<void> deleteAccount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('No user logged in');
    }
    
    // Set flag to prevent auth listener from interfering
    _isAccountDeleted = true;

    try {
      // Store user type before clearing
      final userType = _currentUser?.userType;
      
      // Call the Supabase RPC function to delete the user
      // This function uses SECURITY DEFINER to allow deleting from auth.users
      await _supabase.rpc('delete_user_account');
      
      // Clear local Hive cache
      if (userType == UserType.company) {
        final companiesBox = Hive.box('companiesBox');
        await companiesBox.delete(userId);
      } else if (userType == UserType.seeker) {
        final seekersBox = Hive.box('seekersBox');
        await seekersBox.delete(userId);
      }
      
      // Clear current user
      _currentUser = null;
      
      // Sign out locally only - don't try to communicate with server
      // since the user no longer exists on the server
      // Use SignOutScope.local to avoid network calls that would hang/fail
      try {
        await _supabase.auth.signOut(scope: supabase.SignOutScope.local);
      } catch (e) {
        debugPrint('Expected error signing out deleted user: $e');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting account: $e');
      _isAccountDeleted = false; // Reset flag on error
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  /// Resend verification email for unverified accounts
  /// Uses Supabase's resend method with 'signup' type to send a new verification link
  Future<void> resendVerificationEmail(String email) async {
    try {
      await _supabase.auth.resend(
        type: supabase.OtpType.signup,
        email: email,
        emailRedirectTo: 'https://jobbly-app.web.app/email_verified.html',
      );
    } catch (e) {
      debugPrint('Error resending verification email: $e');
      rethrow;
    }
  }

  Future<void> verifyRecoveryOtp(String email, String token) async {
    try {
      await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: supabase.OtpType.recovery,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update password after OTP verification (used by forgot password flow)
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        supabase.UserAttributes(password: newPassword),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _loadUserFromHive(String userId) async {
    // Try to find in companies box
    final companiesBox = Hive.box('companiesBox');
    final companyData = companiesBox.get(userId);
    
    if (companyData != null) {
      _currentUser = Company.fromMap(Map<String, dynamic>.from(companyData));
      notifyListeners();
      return;
    }

    // Try to find in seekers box
    final seekersBox = Hive.box('seekersBox');
    final seekerData = seekersBox.get(userId);
    
    if (seekerData != null) {
      _currentUser = Seeker.fromMap(Map<String, dynamic>.from(seekerData));
      notifyListeners();
      return;
    }

    // If not found in Hive, try to fetch from Supabase
    await _fetchUserFromSupabase(userId);
  }

  Future<void> _fetchUserFromSupabase(String userId) async {
    try {
      // We don't know the user type, so we check metadata or try both tables
      // Checking metadata is safer if available
      final user = _supabase.auth.currentUser;
      String? userTypeStr = user?.userMetadata?['user_type'];

      // If metadata is missing, try to infer or check both (fallback)
      if (userTypeStr == null) {
        // Try company first
        final companyCheck = await _supabase
            .from('companies')
            .select('companyId')
            .eq('companyId', userId)
            .maybeSingle();
        if (companyCheck != null) {
          userTypeStr = UserType.company.name;
        } else {
          userTypeStr = UserType.seeker.name;
        }
      }

      if (userTypeStr == UserType.company.name) {
        final data = await _supabase
            .from('companies')
            .select()
            .eq('companyId', userId)
            .maybeSingle();
        
        if (data != null) {
          // Add missing fields for local model
          final Map<String, dynamic> map = Map<String, dynamic>.from(data);
          map['userId'] = userId;
          map['password'] = 'secured_by_supabase';
          map['userType'] = UserType.company.name;
          
          final company = Company.fromMap(map);
          
          // Save to Hive
          await Hive.box('companiesBox').put(userId, company.toMap());
          
          _currentUser = company;
          notifyListeners();
        }
      } else if (userTypeStr == UserType.seeker.name) {
        final data = await _supabase
            .from('seekers')
            .select()
            .eq('seekerId', userId)
            .maybeSingle();
            
        if (data != null) {
          // Add missing fields for local model
          final Map<String, dynamic> map = Map<String, dynamic>.from(data);
          map['userId'] = userId;
          map['password'] = 'secured_by_supabase';
          map['userType'] = UserType.seeker.name;
          
          final seeker = Seeker.fromMap(map);
          
          // Save to Hive
          await Hive.box('seekersBox').put(userId, seeker.toMap());
          
          _currentUser = seeker;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching user from Supabase: $e');
      // If fetch fails (e.g. network error), we might want to show an error or retry
      // For now, _currentUser remains null, which will show loading or error state in UI
    }
  }

  /// Refresh current user with updated data (after onboarding/profile edit)
  void refreshCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Check if current user needs onboarding (profile incomplete)
  bool get needsOnboarding {
    if (_currentUser == null) return false;
    
    if (_currentUser is Company) {
      final company = _currentUser as Company;
      // Company needs onboarding if required fields are empty
      return company.companyName.isEmpty || 
             company.description.isEmpty || 
             company.contactNo.isEmpty;
    } else if (_currentUser is Seeker) {
      final seeker = _currentUser as Seeker;
      // Seeker needs onboarding if required fields are empty (phone is now required)
      return seeker.phone == null || seeker.phone!.isEmpty;
    }
    
    return false;
  }

  /// Get user type of current user
  UserType? get currentUserType {
    return _currentUser?.userType;
  }
}
