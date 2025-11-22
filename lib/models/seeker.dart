import 'user.dart';
import 'enums/user_type.dart';
import 'enums/education_level.dart';

class Seeker extends User {
  String seekerId;
  String fullName;
  String? pfp;
  String? resumeUrl;
  String? experience;
  EducationLevel education;
  String? phone;
  String? location;

  Seeker({
    required super.userId,
    required super.email,
    required super.password,
    required super.createdAt,
    required this.seekerId,
    required this.fullName,
    this.pfp,
    this.resumeUrl,
    this.experience,
    required this.education,
    this.phone,
    this.location,
  }) : super(userType: UserType.seeker);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'seekerId': seekerId,
      'fullName': fullName,
      'pfp': pfp,
      'resumeUrl': resumeUrl,
      'experience': experience,
      'education': education.name,
      'phone': phone,
      'location': location,
    });
    return map;
  }

  factory Seeker.fromMap(Map<String, dynamic> map) {
    return Seeker(
      userId: map['userId'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      seekerId: map['seekerId'] ?? '',
      fullName: map['fullName'] ?? '',
      pfp: map['pfp'],
      resumeUrl: map['resumeUrl'],
      experience: map['experience'],
      education: EducationLevel.values.firstWhere(
        (e) => e.name == map['education'],
        orElse: () => EducationLevel.matric,
      ),
      phone: map['phone'],
      location: map['location'],
    );
  }

  @override
  String toString() {
    return 'Seeker(seekerId: $seekerId, fullName: $fullName, email: $email, education: ${education.name}, location: $location)';
  }
}
