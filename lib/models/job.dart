import 'enums/job_type.dart';
import 'enums/job_status.dart';
import 'enums/education_level.dart';

class Job {
  String jobId;
  String companyId;
  String title;
  String description;
  String location;
  double? minSalary;
  double? maxSalary;
  JobType jobType;
  EducationLevel requiredEducation;
  DateTime postedDate;
  JobStatus status;

  Job({
    required this.jobId,
    required this.companyId,
    required this.title,
    required this.description,
    required this.location,
    this.minSalary,
    this.maxSalary,
    required this.jobType,
    required this.requiredEducation,
    required this.postedDate,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'companyId': companyId,
      'title': title,
      'description': description,
      'location': location,
      'minSalary': minSalary,
      'maxSalary': maxSalary,
      'jobType': jobType.name,
      'requiredEducation': requiredEducation.name,
      'postedDate': postedDate.toIso8601String(),
      'status': status.name,
    };
  }

  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      jobId: map['jobId'] ?? '',
      companyId: map['companyId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      minSalary: map['minSalary']?.toDouble(),
      maxSalary: map['maxSalary']?.toDouble(),
      jobType: JobType.values.firstWhere(
        (e) => e.name == map['jobType'],
        orElse: () => JobType.fullTime,
      ),
      requiredEducation: EducationLevel.values.firstWhere(
        (e) => e.name == map['requiredEducation'],
        orElse: () => EducationLevel.matric,
      ),
      postedDate: DateTime.tryParse(map['postedDate'] ?? '') ?? DateTime.now(),
      status: JobStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => JobStatus.active,
      ),
    );
  }

  @override
  String toString() {
    return 'Job(jobId: $jobId, title: $title, company: $companyId, location: $location, type: ${jobType.name}, status: ${status.name})';
  }
}
