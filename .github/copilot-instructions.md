# Employee Hiring Platform - AI Coding Instructions

## Project Overview
Flutter-based employee hiring platform connecting companies with job seekers. Uses a dual-user system (Companies post jobs/quizzes, Seekers apply/take assessments) with skill matching and quiz-based screening.

**Tech Stack**: Flutter + Supabase (backend/auth) + Hive (local cache) + Provider (state management)

## Architecture & Data Model

### Model-First Design Pattern
All data models live in `lib/models/` with a unified export via `lib/models/models.dart`. Import everything with:
```dart
import 'package:project/models/models.dart';
```

**Critical: Models are MUTABLE by design** - no `final` keywords, no `copyWith()` methods. Update fields directly:
```dart
job.status = JobStatus.closed;
company.companyName = 'New Name';
```

### Model Structure & Relationships
- **Inheritance**: `User` is the base class; `Company` and `Seeker` extend it
  - Both force `userType` in their constructors (company/seeker)
  - Override `toMap()` by calling `super.toMap()` then adding subclass fields
- **Many-to-Many**: Junction models `SeekerSkill` and `JobSkill` link entities
- **Nested Data**: `Quiz` embeds `List<Question>` - serialize with `.map((q) => q.toMap()).toList()`
- **Optional Relations**: `Application.quizAttemptId` is nullable (quiz may be skipped)

### Serialization Pattern (toMap/fromMap)
All models use `toMap()`/`fromMap()` for both Supabase and Hive compatibility:

```dart
// TO database (toMap)
Map<String, dynamic> toMap() {
  return {
    'enumField': enumValue.name,           // Enums: use .name
    'dateField': dateValue.toIso8601String(),  // Dates: ISO string
    'listField': listValue.map((item) => item.toMap()).toList(),  // Nested models
  };
}

// FROM database (fromMap)
factory Model.fromMap(Map<String, dynamic> map) {
  return Model(
    enumField: EnumType.values.firstWhere(
      (e) => e.name == map['enumField'],
      orElse: () => EnumType.defaultValue,  // Always provide fallback
    ),
    dateField: DateTime.parse(map['dateField'] as String),
    listField: (map['listField'] as List<dynamic>?)
        ?.map((item) => NestedModel.fromMap(
          Map<String, dynamic>.from(item as Map<dynamic, dynamic>)
        ))
        .toList() ?? [],  // Handle null lists with type casting
  );
}
```

### Type-Safe Enums (lib/models/enums/)
All categorical fields use enums for type safety:
- `UserType`: company, seeker
- `EducationLevel`: matric, inter, bs, ms, phd
- `JobType`: fullTime, partTime, internship, contract
- `JobStatus`: active, closed
- `SkillCategory`: technical, soft, other
- `ApplicationStatus`: pending, reviewed, shortlisted, rejected

**Always use `.name` for serialization**, not `.toString()` or index values.

## Provider State Management Pattern

### Standard Provider Structure
All providers use **nullable Box + null-check pattern** with Supabase as primary data source:

```dart
class JobProvider with ChangeNotifier {
  Box? _jobBox;
  List<Job> _jobs = [];
  
  // Initialize Hive box
  Future<void> _ensureInitialized() async {
    _jobBox ??= await Hive.openBox('jobsBox');
  }
  
  // Fetch from Supabase and cache to Hive
  Future<void> fetchAllJobsFromSupabase() async {
    try {
      await _ensureInitialized();
      final response = await Supabase.instance.client
          .from('jobs')
          .select();
      _jobs = (response as List)
          .map((e) => Job.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      // Cache to Hive
      for (final job in _jobs) {
        _jobBox!.put(job.jobId, job.toMap());
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching jobs: $e');
      rethrow;
    }
  }
  
  // CRUD operations update both Supabase and local cache
  Future<void> addJob(Job job) async {
    await _ensureInitialized();
    await Supabase.instance.client.from('jobs').insert(job.toMap());
    _jobBox!.put(job.jobId, job.toMap());
    _jobs.add(job);
    notifyListeners();
  }
  
  List<Job> get jobs => _jobs;
}
```

### Import Style
**Always use package imports** (not relative imports):
```dart
// ✅ Correct
import 'package:project/models/models.dart';
import 'package:project/providers/providers.dart';

// ❌ Avoid
import '../../models/models.dart';
```

## File Structure Reference
```
lib/
  main.dart              # App entry point with Supabase/Hive init
  notes.yaml             # Development notes and TODOs
  structure.yaml         # Database schema documentation
  models/
    models.dart          # Barrel export - import this
    user.dart            # Base User class
    company.dart         # Company extends User
    seeker.dart          # Seeker extends User
    job.dart, skill.dart, quiz.dart, application.dart
    seeker_skill.dart, job_skill.dart  # Junction tables
    quiz_attempt.dart, question.dart   # Quiz system
    example_usage.dart   # Complete usage examples
    enums/               # All type-safe enums
  providers/
    providers.dart       # Barrel export
    auth_provider.dart   # Authentication with Supabase Auth
    company_provider.dart, seeker_provider.dart
    job_provider.dart, application_provider.dart
    skill_provider.dart, seeker_skill_provider.dart, job_skill_provider.dart
    quiz_provider.dart, quiz_attempt_provider.dart
  screens/
    auth/                # Login, signup, forgot password, welcome
    onboarding/          # Company and seeker onboarding
    company/             # Company dashboard, jobs, applications, profile
    seeker/              # Seeker dashboard, job listings, applications, profile
    shared/              # Settings
    home/                # Home screen
  widgets/               # Reusable UI components
    primary_button.dart, bouncing_button.dart
    app_modal.dart, question_editor_card.dart, user_type_toggle.dart
  theme/
    app_theme.dart       # Material 3 theme configuration
  utils/
    constants.dart       # App constants
    validators.dart      # Form validators
    dialogs.dart         # Dialog utilities
```

## Project-Specific Conventions

### No Immutability Pattern
This project uses **mutable models** for simplicity. Do NOT add:
- `final` keywords on model fields
- `copyWith()` methods
- Immutable pattern enforcement

### UI/UX Guidelines
- Use **Material 3** design system
- Use `AppTheme` constants for colors (`AppTheme.primaryColor`, `AppTheme.backgroundColor`, etc.)
- Keep UI simple and functional - semester project scope

### DateTime Handling
All timestamps stored as ISO 8601 strings:
```dart
createdAt: DateTime.now()                      // Create
'createdAt': createdAt.toIso8601String()       // Serialize
createdAt: DateTime.parse(map['createdAt'])    // Deserialize
```

### Error Handling
Use simple try-catch with `debugPrint()` and `rethrow`:
```dart
try {
  // operation
} catch (e) {
  debugPrint('Error description: $e');
  rethrow;
}
```

### Navigation
Use direct `Navigator.push()` with `MaterialPageRoute` for simplicity:
```dart
Navigator.push(context, MaterialPageRoute(builder: (_) => TargetScreen()));
Navigator.pushNamed(context, '/route');  // For named routes defined in main.dart
```

## Common Pitfalls
- ❌ Don't use `copyWith()` - fields are mutable, update directly
- ❌ Don't serialize enums with `.toString()` - use `.name`
- ❌ Don't forget `orElse` fallback in enum `fromMap()` parsing
- ❌ Don't omit null checks for lists in `fromMap()` - always use `?? []`
- ❌ Don't forget type casting: `Map<String, dynamic>.from(e as Map<dynamic, dynamic>)`
- ❌ Don't use relative imports - use package imports everywhere
- ✅ DO reference `example_usage.dart` for correct model usage patterns
- ✅ DO call `super.toMap()` in subclass serialization methods
- ✅ DO force `userType` in Company/Seeker constructors via `super(userType: ...)`
- ✅ DO use nullable Box pattern (`Box?`) in providers
