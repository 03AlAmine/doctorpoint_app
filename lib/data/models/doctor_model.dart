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
    return {
      'name': name,
      'specialization': specialization,
      'specialtyIcon': specialtyIcon,
      'rating': rating,
      'reviews': reviews,
      'experience': experience,
      'hospital': hospital,
      'department': department,
      'imageUrl': imageUrl,
      'isFavorite': isFavorite,
      'consultationFee': consultationFee,
      'languages': languages,
      'description': description,
      'availability': availability,
      'location': location,
      'phoneNumber': phoneNumber,
      'email': email,
      'education': education,
      'certifications': certifications,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}