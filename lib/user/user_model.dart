import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final bool isVerified;
  final String role;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.isVerified,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: data['uid'] ?? '',
      name: data['agentName'] ?? '',
      email: data['email'] ?? '',
      isVerified: data['isVerified'] ?? false,
      role: data['role'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
