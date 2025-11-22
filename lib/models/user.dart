import 'enums/user_type.dart';

abstract class User {
  String userId;
  String email;
  String password;
  UserType userType;
  DateTime createdAt;

  User({
    required this.userId,
    required this.email,
    required this.password,
    required this.userType,
    required this.createdAt,
  });

  // Convert to Map for Hive database storage
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'password': password,
      'userType': userType.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
