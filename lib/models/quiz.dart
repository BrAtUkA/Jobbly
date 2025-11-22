import 'question.dart';

class Quiz {
  String quizId;
  String jobId;
  String companyId;
  String title;
  int duration; // in minutes
  int passingScore;
  DateTime createdDate;
  List<Question> questions;

  Quiz({
    required this.quizId,
    required this.jobId,
    required this.companyId,
    required this.title,
    required this.duration,
    required this.passingScore,
    required this.createdDate,
    required this.questions,
  });

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'jobId': jobId,
      'companyId': companyId,
      'title': title,
      'duration': duration,
      'passingScore': passingScore,
      'createdDate': createdDate.toIso8601String(),
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      quizId: map['quizId'] ?? '',
      jobId: map['jobId'] ?? '',
      companyId: map['companyId'] ?? '',
      title: map['title'] ?? '',
      duration: map['duration'] ?? 0,
      passingScore: map['passingScore'] ?? 0,
      createdDate: DateTime.parse(map['createdDate']),
      questions: (map['questions'] as List<dynamic>?)
              ?.map((q) => Question.fromMap(
                    Map<String, dynamic>.from(q as Map<dynamic, dynamic>),
                  ))
              .toList() ??
          [],
    );
  }

  @override
  String toString() {
    return 'Quiz(quizId: $quizId, title: $title, duration: $duration min, questions: ${questions.length})';
  }
}
