class QuizAttempt {
  String attemptId;
  String quizId;
  String seekerId;
  int score;
  DateTime attemptDate;
  bool isPassed;
  int timeTaken; // in minutes

  QuizAttempt({
    required this.attemptId,
    required this.quizId,
    required this.seekerId,
    required this.score,
    required this.attemptDate,
    required this.isPassed,
    required this.timeTaken,
  });

  Map<String, dynamic> toMap() {
    return {
      'attemptId': attemptId,
      'quizId': quizId,
      'seekerId': seekerId,
      'score': score,
      'attemptDate': attemptDate.toIso8601String(),
      'isPassed': isPassed,
      'timeTaken': timeTaken,
    };
  }

  factory QuizAttempt.fromMap(Map<String, dynamic> map) {
    return QuizAttempt(
      attemptId: map['attemptId'] ?? '',
      quizId: map['quizId'] ?? '',
      seekerId: map['seekerId'] ?? '',
      score: map['score'] ?? 0,
      attemptDate: DateTime.parse(map['attemptDate']),
      isPassed: map['isPassed'] ?? false,
      timeTaken: map['timeTaken'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'QuizAttempt(attemptId: $attemptId, quizId: $quizId, score: $score, isPassed: $isPassed, timeTaken: $timeTaken min)';
  }
}
