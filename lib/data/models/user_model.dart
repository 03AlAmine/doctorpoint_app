import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String phone;

  final String? gender;
  final DateTime? birthDate;
  final String? address;
  final String? photoUrl;

  final bool profileCompleted;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phone,
    this.gender,
    this.birthDate,
    this.address,
    this.photoUrl,
    required this.profileCompleted,
    required this.createdAt,
  });

  /// =========================
  /// 🔄 FROM FIRESTORE
  /// =========================
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phone: data['phone'] ?? '',

      gender: data['gender'],
      birthDate: data['birthDate'] != null
          ? (data['birthDate'] as Timestamp).toDate()
          : null,
      address: data['address'],
      photoUrl: data['photoUrl'],

      profileCompleted: data['profileCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// =========================
  /// ⬆️ TO FIRESTORE
  /// =========================
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'gender': gender,
      'birthDate': birthDate,
      'address': address,
      'photoUrl': photoUrl,
      'profileCompleted': profileCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
