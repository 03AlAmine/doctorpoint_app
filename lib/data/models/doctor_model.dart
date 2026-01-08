import 'package:cloud_firestore/cloud_firestore.dart';

class Doctor {
  final String id;
  final String name;
  final String specialization;
  final String? specialtyIcon;
  final double rating;
  final int reviews;
  final int experience;
  final String hospital;
  final String? department;
  final String imageUrl;
  final bool isFavorite;
  final double consultationFee;
  final List<String> languages;
  final String? description;
  final Map<String, dynamic>? availability;
  final GeoPoint? location;
  final String? phoneNumber;
  final String? email;
  final List<String>? education;
  final List<String>? certifications;
  final DateTime? createdAt;
  final String? password; // AJOUTEZ CE CHAMP
  final bool? hasAccount; // Pour savoir si le médecin a un compte
  final String? accountStatus; // pending, active, inactive
  final DateTime? lastLogin;
  final List<String>? roles; // ['doctor', 'admin'] etc.

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    this.specialtyIcon,
    required this.rating,
    required this.reviews,
    required this.experience,
    required this.hospital,
    this.department,
    required this.imageUrl,
    this.isFavorite = false,
    required this.consultationFee,
    required this.languages,
    this.description,
    this.availability,
    this.location,
    this.phoneNumber,
    this.email,
    this.password, // AJOUTEZ
    this.hasAccount = false, // AJOUTEZ
    this.accountStatus = 'pending', // AJOUTEZ
    this.lastLogin, // AJOUTEZ
    this.roles = const ['doctor'], // AJOUTEZ
    this.education,
    this.certifications,
    this.createdAt,
  });

  factory Doctor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Doctor(
      id: doc.id,
      name: data['name'] ?? '',
      specialization: data['specialization'] ?? '',
      specialtyIcon: data['specialtyIcon'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviews: data['reviews'] ?? 0,
      experience: data['experience'] ?? 0,
      hospital: data['hospital'] ?? '',
      department: data['department'],
      imageUrl: data['imageUrl'] ?? '',
      isFavorite: data['isFavorite'] ?? false,
      consultationFee: (data['consultationFee'] ?? 0.0).toDouble(),
      languages: List<String>.from(data['languages'] ?? []),
      description: data['description'],
      availability: data['availability'] != null
          ? Map<String, dynamic>.from(data['availability'])
          : null,
      location: data['location'],
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      password: data['password'], // AJOUTEZ
      hasAccount: data['hasAccount'] ?? false, // AJOUTEZ
      accountStatus: data['accountStatus'] ?? 'pending', // AJOUTEZ
      lastLogin: data['lastLogin']?.toDate(), // AJOUTEZ
      roles: List<String>.from(data['roles'] ?? ['doctor']), // AJOUTEZ
      education: data['education'] != null
          ? List<String>.from(data['education'])
          : null,
      certifications: data['certifications'] != null
          ? List<String>.from(data['certifications'])
          : null,
      createdAt: data['createdAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'specialization': specialization,
      'rating': rating,
      'reviews': reviews,
      'experience': experience,
      'hospital': hospital,
      'imageUrl': imageUrl,
      'isFavorite': isFavorite,
      'consultationFee': consultationFee,
      'languages': languages,
      'hasAccount': hasAccount ?? false, // AJOUTEZ
      'accountStatus': accountStatus ?? 'pending', // AJOUTEZ
      'roles': roles ?? ['doctor'], // AJOUTEZ
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Champs optionnels
    if (specialtyIcon != null) map['specialtyIcon'] = specialtyIcon;
    if (department != null) map['department'] = department;
    if (description != null) map['description'] = description;
    if (availability != null) map['availability'] = availability;
    if (location != null) map['location'] = location;
    if (phoneNumber != null) map['phoneNumber'] = phoneNumber;
    if (email != null) map['email'] = email;
    if (password != null) map['password'] = password; // AJOUTEZ
    if (hasAccount != null) map['hasAccount'] = hasAccount;
    if (lastLogin != null) map['lastLogin'] = Timestamp.fromDate(lastLogin!);
    if (education != null) map['education'] = education;
    if (certifications != null) map['certifications'] = certifications;
    
    return map;
  }
}