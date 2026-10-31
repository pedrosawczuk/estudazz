import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String username;
  final String email;
  final String birthDate;
  final String institution;
  final String course;
  final String expectedGraduation;
  final bool profileCompleted;
  final String photoUrl;
  final DateTime? lastLogin;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.username,
    required this.email,
    required this.birthDate,
    required this.institution,
    required this.course,
    required this.expectedGraduation,
    required this.profileCompleted,
    required this.photoUrl,
    this.lastLogin,
  });

  factory UserModel.fromMap(
    Map<String, dynamic> map,
    String uid, {
    Map<String, dynamic>? privateMap,
  }) {
    return UserModel(
      uid: uid,
      displayName: map['display_name'] ?? '',
      username: map['username'] ?? '',
      email: privateMap?['email'] ?? map['email'] ?? '',
      birthDate: privateMap?['birth_date'] ?? map['birth_date'] ?? '',
      institution: privateMap?['institution'] ?? map['institution'] ?? '',
      course: privateMap?['course'] ?? map['course'] ?? '',
      expectedGraduation:
          privateMap?['expected_graduation'] ??
          map['expected_graduation'] ??
          '',
      profileCompleted: map['profile_completed'] ?? false,
      photoUrl: map['photoURL'] ?? '',
      lastLogin: (map['last_login'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toPublicMap() {
    return {
      'uid': uid,
      'display_name': displayName,
      'username': username,
      'profile_completed': profileCompleted,
      'photoURL': photoUrl,
      if (lastLogin != null) 'last_login': Timestamp.fromDate(lastLogin!),
    };
  }

  Map<String, dynamic> toPrivateMap() {
    return {
      'uid': uid,
      'email': email,
      'birth_date': birthDate,
      'institution': institution,
      'course': course,
      'expected_graduation': expectedGraduation,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      ...toPublicMap(),
      ...toPrivateMap(),
      'last_login': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }
}
