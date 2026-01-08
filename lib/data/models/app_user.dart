// lib/data/models/app_user.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { patient, doctor, admin }

class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final UserRole role;
  final bool profileCompleted;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? roleData; // Données spécifiques au rôle

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.profileCompleted,
    required this.emailVerified,
    required this.createdAt,
    this.lastLogin,
    this.profile,
    this.roleData,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phone: data['phone'] ?? '',
      role: _parseRole(data['role'] ?? 'patient'),
      profileCompleted: data['profileCompleted'] ?? false,
      emailVerified: data['emailVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      profile: data['profile'] != null
          ? Map<String, dynamic>.from(data['profile'])
          : null,
    );
  }

  static UserRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
        return UserRole.doctor;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.patient;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'role': role.name,
      'profileCompleted': profileCompleted,
      'emailVerified': emailVerified,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'profile': profile,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  bool get isDoctor => role == UserRole.doctor;
  bool get isAdmin => role == UserRole.admin;
  bool get isPatient => role == UserRole.patient;

  // Charger les données spécifiques au rôle
  Future<AppUser> loadRoleData() async {
    Map<String, dynamic>? data;

    if (isDoctor) {
      final doc =
          await FirebaseFirestore.instance.collection('doctors').doc(id).get();
      if (doc.exists) data = doc.data();
    } else if (isAdmin) {
      final doc =
          await FirebaseFirestore.instance.collection('admins').doc(id).get();
      if (doc.exists) data = doc.data();
    }

    return AppUser(
      id: id,
      email: email,
      fullName: fullName,
      phone: phone,
      role: role,
      profileCompleted: profileCompleted,
      emailVerified: emailVerified,
      createdAt: createdAt,
      lastLogin: lastLogin,
      profile: profile,
      roleData: data,
    );
  }
}
