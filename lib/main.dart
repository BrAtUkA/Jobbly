import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';

import 'providers/providers.dart';
import 'theme/app_theme.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/company_onboarding_screen.dart';
import 'screens/onboarding/seeker_onboarding_screen.dart';
import 'screens/company/create_job_screen.dart';
import 'screens/company/create_quiz_screen.dart';
import 'screens/company/company_main_screen.dart';
import 'screens/company/job_applications_screen.dart';
import 'screens/seeker/seeker_main_screen.dart';
import 'screens/seeker/job_detail_screen.dart';
import 'screens/seeker/quiz_taking_screen.dart';
import 'screens/seeker/edit_seeker_profile_screen.dart';
import 'screens/shared/settings_screen.dart';
import 'models/models.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Hive
  await Hive.initFlutter();
  // Open boxes
  await Hive.openBox('companiesBox');
  await Hive.openBox('seekersBox');
  await Hive.openBox('jobsBox');
  await Hive.openBox('applicationsBox');
  await Hive.openBox('skillsBox');
  await Hive.openBox('quizzesBox');
  await Hive.openBox('seekerSkillsBox');
  await Hive.openBox('jobSkillsBox');
  await Hive.openBox('quizAttemptsBox');
  // Add other boxes as needed by your providers

  // Initialize Supabase with error handling for stale sessions
  try {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        // Auto refresh session but handle failures gracefully
        autoRefreshToken: true,
      ),
    );
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
    // Continue anyway - the auth provider will handle session issues
  }

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  DateTime? _lastDeepLinkTime;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Listen for incoming links
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // Handle initial link
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _handleDeepLink(uri);
      }
    } catch (e) {
      debugPrint('Deep link error: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    // Debounce to prevent double handling (initial link + stream)
    if (_lastDeepLinkTime != null && 
        DateTime.now().difference(_lastDeepLinkTime!) < const Duration(milliseconds: 1000)) {
      return;
    }

    if (uri.scheme == 'jobbly' && uri.host == 'login') {
      _lastDeepLinkTime = DateTime.now();
      debugPrint('Handling deep link: $uri');

      // Use a small delay to ensure Navigator is ready and widget tree is stable
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()..init()),
        ChangeNotifierProvider(create: (_) => SeekerProvider()..init()),
        ChangeNotifierProvider(create: (_) => JobProvider()..init()),
        ChangeNotifierProvider(create: (_) => SkillProvider()..init()),
        ChangeNotifierProvider(create: (_) => QuizProvider()..init()),
        ChangeNotifierProvider(create: (_) => ApplicationProvider()..init()),
        ChangeNotifierProvider(create: (_) => SeekerSkillProvider()..init()),
        ChangeNotifierProvider(create: (_) => JobSkillProvider()..init()),
        ChangeNotifierProvider(create: (_) => QuizAttemptProvider()..init()),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Jobbly',
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/onboarding/company': (context) => const CompanyOnboardingScreen(),
          '/onboarding/seeker': (context) => const SeekerOnboardingScreen(),
          '/company/create-job': (context) => const CreateJobScreen(),
          '/company/create-quiz': (context) => const CreateQuizScreen(),
          '/company/dashboard': (context) => const CompanyMainScreen(),
          '/seeker/dashboard': (context) => const SeekerMainScreen(),
          '/seeker/edit-profile': (context) => const EditSeekerProfileScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
        onGenerateRoute: (settings) {
          // Handle routes with arguments
          if (settings.name == '/company/job-applications') {
            final job = settings.arguments as Job;
            return MaterialPageRoute(
              builder: (_) => JobApplicationsScreen(job: job),
            );
          }
          // Handle quiz creation with job argument
          if (settings.name == '/company/create-quiz') {
            return MaterialPageRoute(
              builder: (_) => const CreateQuizScreen(),
              settings: settings,
            );
          }
          // Handle seeker job detail route
          if (settings.name == '/seeker/job-detail') {
            final job = settings.arguments as Job;
            return MaterialPageRoute(
              builder: (_) => JobDetailScreen(job: job),
            );
          }
          // Handle seeker quiz taking route
          if (settings.name == '/seeker/take-quiz') {
            final args = settings.arguments as Map<String, dynamic>;
            final quiz = args['quiz'] as Quiz;
            final job = args['job'] as Job;
            return MaterialPageRoute(
              builder: (_) => QuizTakingScreen(quiz: quiz, job: job),
            );
          }
          return null;
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Show loading while checking auth state
        if (auth.isProfileLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Not authenticated - show welcome/login
        if (!auth.isAuthenticated) {
          return const WelcomeScreen();
        }
        
        // Safety check: if authenticated but user type is null, show loading
        // This handles race conditions during auth state transitions
        if (auth.currentUserType == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Authenticated but needs onboarding
        if (auth.needsOnboarding) {
          // Route to appropriate onboarding based on user type
          if (auth.currentUserType == UserType.company) {
            return const CompanyOnboardingScreen();
          } else {
            return const SeekerOnboardingScreen();
          }
        }
        
        // Authenticated and onboarding complete - route to appropriate dashboard
        if (auth.currentUserType == UserType.company) {
          return const CompanyMainScreen();
        } else {
          return const SeekerMainScreen();
        }
      },
    );
  }
}
