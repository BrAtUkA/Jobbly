class JobSkill {
  String jobId;
  String skillId;

  JobSkill({required this.jobId, required this.skillId});

  Map<String, dynamic> toMap() {
    return {'jobId': jobId, 'skillId': skillId};
  }

  factory JobSkill.fromMap(Map<String, dynamic> map) {
    return JobSkill(jobId: map['jobId'] ?? '', skillId: map['skillId'] ?? '');
  }

  @override
  String toString() {
    return 'JobSkill(jobId: $jobId, skillId: $skillId)';
  }
}
