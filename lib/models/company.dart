import 'user.dart';
import 'enums/user_type.dart';

class Company extends User {
  String companyId;
  String companyName;
  String description;
  String? logoUrl;
  String? website;
  String contactNo;

  Company({
    required super.userId,
    required super.email,
    required super.password,
    required super.createdAt,
    required this.companyId,
    required this.companyName,
    required this.description,
    this.logoUrl,
    this.website,
    required this.contactNo,
  }) : super(userType: UserType.company);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'companyId': companyId,
      'companyName': companyName,
      'description': description,
      'logoUrl': logoUrl,
      'website': website,
      'contactNo': contactNo,
    });
    return map;
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      userId: map['userId'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      companyId: map['companyId'] ?? '',
      companyName: map['companyName'] ?? '',
      description: map['description'] ?? '',
      logoUrl: map['logoUrl'],
      website: map['website'],
      contactNo: map['contactNo'] ?? '',
    );
  }

  @override
  String toString() {
    return 'Company(companyId: $companyId, companyName: $companyName, email: $email, contactNo: $contactNo)';
  }
}
