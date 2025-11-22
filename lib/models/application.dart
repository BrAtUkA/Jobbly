import 'enums/application_status.dart';

class Application {
  String applicationId;
  String jobId;
  String seekerId;
  String? quizAttemptId; // nullable - links quiz result
  DateTime appliedDate;
  ApplicationStatus status;

  Application({
    required this.applicationId,
    required this.jobId,
    required this.seekerId,
    this.quizAttemptId,
    required this.appliedDate,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'applicationId': applicationId,
      'jobId': jobId,
      'seekerId': seekerId,
      'quizAttemptId': quizAttemptId,
      'appliedDate': appliedDate.toIso8601String(),
      'status': status.name,
    };
  }

  factory Application.fromMap(Map<String, dynamic> map) {
    return Application(
      applicationId: map['applicationId'] ?? '',
      jobId: map['jobId'] ?? '',
      seekerId: map['seekerId'] ?? '',
      quizAttemptId: map['quizAttemptId'],
      appliedDate: DateTime.tryParse(map['appliedDate'] ?? '') ?? DateTime.now(),
      status: ApplicationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ApplicationStatus.pending,
      ),
    );
  }

  @override
  String toString() {
    return 'Application(applicationId: $applicationId, jobId: $jobId, seekerId: $seekerId, status: ${status.name})';
  }
}
