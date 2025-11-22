// Example usage of the model classes
// This file demonstrates how to create and use the models

// ignore_for_file: avoid_print

import 'package:project/models/models.dart';

void main() {
  // Example 1: Creating a Company
  final company = Company(
    userId: 'user_1',
    email: 'company@example.com',
    password: 'hashedPassword123',
    createdAt: DateTime.now(),
    companyId: 'comp_1',
    companyName: 'Tech Solutions Inc',
    description: 'Leading software development company',
    logoUrl: 'https://example.com/logo.png',
    website: 'https://techsolutions.com',
    contactNo: '+1234567890',
  );

  print('Company: ${company.companyName}');

  // Example 2: Creating a Seeker
  final seeker = Seeker(
    userId: 'user_2',
    email: 'seeker@example.com',
    password: 'hashedPassword456',
    createdAt: DateTime.now(),
    seekerId: 'seek_1',
    fullName: 'Ali Ahmad',
    education: EducationLevel.bs,
    phone: '+9876543210',
    location: 'Karachi, Pakistan',
    experience: '2 years in Flutter development',
  );

  print('Seeker: ${seeker.fullName}');

  // Example 3: Creating a Job
  final job = Job(
    jobId: 'job_1',
    companyId: company.companyId,
    title: 'Flutter Developer',
    description: 'We are looking for a skilled Flutter developer...',
    location: 'Remote',
    minSalary: 50000,
    maxSalary: 80000,
    jobType: JobType.fullTime,
    requiredEducation: EducationLevel.bs,
    postedDate: DateTime.now(),
    status: JobStatus.active,
  );

  print('Job: ${job.title}');

  // Example 4: Creating Skills
  final skill1 = Skill(
    skillId: 'skill_1',
    skillName: 'Flutter',
    category: SkillCategory.technical,
  );

  final skill2 = Skill(
    skillId: 'skill_2',
    skillName: 'Communication',
    category: SkillCategory.soft,
  );

  print('Skills created: ${skill1.skillName}, ${skill2.skillName}');

  // Example 5: Linking Seeker to Skills
  final seekerSkill = SeekerSkill(
    seekerId: seeker.seekerId,
    skillId: skill1.skillId,
  );

  print('Seeker skill added: ${seekerSkill.seekerId} -> ${seekerSkill.skillId}');

  // Example 6: Linking Job to Required Skills
  final jobSkill = JobSkill(jobId: job.jobId, skillId: skill1.skillId);

  print('Job skill requirement added for job: ${jobSkill.jobId}');

  // Example 7: Creating Questions
  final question1 = Question(
    questionId: 'q1',
    questionText: 'What is Flutter?',
    optionA: 'A programming language',
    optionB: 'A UI framework',
    optionC: 'A database',
    optionD: 'An operating system',
    correctAnswer: 'B',
  );

  final question2 = Question(
    questionId: 'q2',
    questionText: 'Which language does Flutter use?',
    optionA: 'Java',
    optionB: 'Kotlin',
    optionC: 'Dart',
    optionD: 'Swift',
    correctAnswer: 'C',
  );

  // Example 8: Creating a Quiz
  final quiz = Quiz(
    quizId: 'quiz_1',
    jobId: job.jobId,
    companyId: company.companyId,
    title: 'Flutter Developer Assessment',
    duration: 30,
    passingScore: 70,
    createdDate: DateTime.now(),
    questions: [question1, question2],
  );

  print('Quiz: ${quiz.title} - ${quiz.questions.length} questions');

  // Example 9: Creating a Quiz Attempt
  final quizAttempt = QuizAttempt(
    attemptId: 'attempt_1',
    quizId: quiz.quizId,
    seekerId: seeker.seekerId,
    score: 85,
    attemptDate: DateTime.now(),
    isPassed: true,
    timeTaken: 25,
  );

  print(
    'Quiz Attempt: Score ${quizAttempt.score} - Passed: ${quizAttempt.isPassed}',
  );

  // Example 10: Creating an Application
  final application = Application(
    applicationId: 'app_1',
    jobId: job.jobId,
    seekerId: seeker.seekerId,
    quizAttemptId: quizAttempt.attemptId,
    appliedDate: DateTime.now(),
    status: ApplicationStatus.pending,
  );

  print('Application: ${application.status.name}');

  // Example 11: Converting to JSON (for database storage)
  final companyJson = company.toMap();
  print('Company JSON: $companyJson');

  // Example 12: Creating from JSON (from database)
  final companyFromJson = Company.fromMap(companyJson);
  print('Company from JSON: ${companyFromJson.companyName}');

  // Example 13: Direct update (mutable fields)
  job.status = JobStatus.closed;
  job.maxSalary = 90000;
  print(
    'Updated Job Status: ${job.status.name}, New Max Salary: ${job.maxSalary}',
  );

  // Example 14: Using toString for debugging
  print('\n--- Using toString() ---');
  print(company);
  print(seeker);
  print(job);
  print(quiz);
  print(application);
}
