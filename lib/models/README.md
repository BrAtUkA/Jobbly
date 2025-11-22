# Models Documentation

This directory contains all the data model classes for the Employee Hiring application.

## Structure Overview

### Core Models
- **User** - Base user model with authentication fields
- **Company** - Company profile (extends User)
- **Seeker** - Job seeker profile (extends User)
- **Job** - Job posting details
- **Skill** - Skill definitions
- **Question** - Quiz question details
- **Quiz** - Quiz configuration with questions
- **QuizAttempt** - Record of seeker's quiz attempt
- **Application** - Job application tracking

### Junction Tables (Many-to-Many Relationships)
- **SeekerSkill** - Links seekers to their skills with proficiency levels
- **JobSkill** - Links jobs to required skills

### Enums
- **UserType** - company, seeker
- **EducationLevel** - matric, inter, bs, ms, phd
- **JobType** - fullTime, partTime, internship, contract
- **JobStatus** - active, closed
- **SkillCategory** - technical, soft, other
- **ApplicationStatus** - pending, reviewed, shortlisted, rejected

## Usage

Import all models at once:
```dart
import 'package:project/models/models.dart';
```

Or import individual models:
```dart
import 'package:project/models/company.dart';
import 'package:project/models/seeker.dart';
```

## Features

Each model includes:
- ✅ **toJson()** - Convert to JSON Map for database storage
- ✅ **fromJson()** - Create instance from JSON Map
- ✅ **toString()** - Human-readable string representation for debugging
- ✅ **Mutable fields** - Direct updates without copyWith()
- ✅ Type-safe enums for all categorical fields
- ✅ Nullable fields where appropriate
