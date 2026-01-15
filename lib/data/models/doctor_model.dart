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
  final String? password;
  final bool? hasAccount;
  final String? accountStatus;
  final DateTime? lastLogin;
  final List<String>? roles;
  final Map<String, dynamic>? roleData;
  final String? licenseNumber;
  final Map<String, dynamic>? verification;
  final Map<String, dynamic>? documents;

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
    this.password,
    this.hasAccount = false,
    this.accountStatus = 'pending',
    this.lastLogin,
    this.roles = const ['doctor'],
    this.roleData,
    this.licenseNumber,
    this.education,
    this.certifications,
    this.createdAt,
    this.verification,
    this.documents,
  });

  factory Doctor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Extraire licenseNumber de roleData
    String? licenseNumber;
    if (data['roleData'] != null && data['roleData'] is Map) {
      final roleData = data['roleData'] as Map<String, dynamic>;
      licenseNumber = roleData['licenseNumber']?.toString();
    }

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
      password: data['password'],
      hasAccount: data['hasAccount'] ?? false,
      accountStatus: data['accountStatus'] ?? 'pending',
      lastLogin: data['lastLogin']?.toDate(),
      roles: List<String>.from(data['roles'] ?? ['doctor']),
      roleData: data['roleData'] != null
          ? Map<String, dynamic>.from(data['roleData'])
          : null,
      licenseNumber: licenseNumber ?? data['licenseNumber'],
      education: data['education'] != null
          ? List<String>.from(data['education'])
          : null,
      certifications: data['certifications'] != null
          ? List<String>.from(data['certifications'])
          : null,
      createdAt: data['createdAt']?.toDate(),
      verification: data['verification'] != null
          ? Map<String, dynamic>.from(data['verification'])
          : null,
      documents: data['documents'] != null
          ? Map<String, dynamic>.from(data['documents'])
          : null,
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
      'hasAccount': hasAccount ?? false,
      'accountStatus': accountStatus ?? 'pending',
      'roles': roles ?? ['doctor'],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (verification != null) map['verification'] = verification;
    if (documents != null) map['documents'] = documents;

    // Champs optionnels
    if (specialtyIcon != null) map['specialtyIcon'] = specialtyIcon;
    if (department != null) map['department'] = department;
    if (description != null) map['description'] = description;
    if (availability != null) map['availability'] = availability;
    if (location != null) map['location'] = location;
    if (phoneNumber != null) map['phoneNumber'] = phoneNumber;
    if (email != null) map['email'] = email;
    if (password != null) map['password'] = password;
    if (lastLogin != null) map['lastLogin'] = Timestamp.fromDate(lastLogin!);
    if (education != null) map['education'] = education;
    if (certifications != null) map['certifications'] = certifications;
    if (licenseNumber != null) map['licenseNumber'] = licenseNumber;
    if (roleData != null) map['roleData'] = roleData;

    return map;
  }

  Doctor copyWith({
    String? id,
    String? name,
    String? specialization,
    String? specialtyIcon,
    double? rating,
    int? reviews,
    int? experience,
    String? hospital,
    String? department,
    String? imageUrl,
    bool? isFavorite,
    double? consultationFee,
    List<String>? languages,
    String? description,
    Map<String, dynamic>? availability,
    GeoPoint? location,
    String? phoneNumber,
    String? email,
    String? password,
    bool? hasAccount,
    String? accountStatus,
    DateTime? lastLogin,
    List<String>? roles,
    Map<String, dynamic>? roleData,
    String? licenseNumber,
    List<String>? education,
    List<String>? certifications,
    DateTime? createdAt,
    Map<String, dynamic>? verification,
    Map<String, dynamic>? documents,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      specialization: specialization ?? this.specialization,
      specialtyIcon: specialtyIcon ?? this.specialtyIcon,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      experience: experience ?? this.experience,
      hospital: hospital ?? this.hospital,
      department: department ?? this.department,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      consultationFee: consultationFee ?? this.consultationFee,
      languages: languages ?? this.languages,
      description: description ?? this.description,
      availability: availability ?? this.availability,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      password: password ?? this.password,
      hasAccount: hasAccount ?? this.hasAccount,
      accountStatus: accountStatus ?? this.accountStatus,
      lastLogin: lastLogin ?? this.lastLogin,
      roles: roles ?? this.roles,
      roleData: roleData ?? this.roleData,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      education: education ?? this.education,
      certifications: certifications ?? this.certifications,
      createdAt: createdAt ?? this.createdAt,
      verification: verification ?? this.verification,
      documents: documents ?? this.documents,
    );
  }

  // Ajouter cette méthode dans la classe Doctor (doctor_model.dart)
  factory Doctor.fromMap(Map<String, dynamic> map) {
    // Extraire licenseNumber de roleData
    String? licenseNumber;
    if (map['roleData'] != null && map['roleData'] is Map) {
      final roleData = map['roleData'] as Map<String, dynamic>;
      licenseNumber = roleData['licenseNumber']?.toString();
    }

    return Doctor(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      specialization: map['specialization'] ?? '',
      specialtyIcon: map['specialtyIcon'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviews: map['reviews'] ?? 0,
      experience: map['experience'] ?? 0,
      hospital: map['hospital'] ?? '',
      department: map['department'],
      imageUrl: map['imageUrl'] ?? '',
      isFavorite: map['isFavorite'] ?? false,
      consultationFee: (map['consultationFee'] ?? 0.0).toDouble(),
      languages: List<String>.from(map['languages'] ?? []),
      description: map['description'],
      availability: map['availability'] != null
          ? Map<String, dynamic>.from(map['availability'])
          : null,
      location: map['location'] as GeoPoint?,
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      password: map['password'],
      hasAccount: map['hasAccount'] ?? false,
      accountStatus: map['accountStatus'] ?? 'pending',
      lastLogin: map['lastLogin'] != null
          ? (map['lastLogin'] as Timestamp).toDate()
          : null,
      roles: List<String>.from(map['roles'] ?? ['doctor']),
      roleData: map['roleData'] != null
          ? Map<String, dynamic>.from(map['roleData'])
          : null,
      licenseNumber: licenseNumber ?? map['licenseNumber'],
      education:
          map['education'] != null ? List<String>.from(map['education']) : null,
      certifications: map['certifications'] != null
          ? List<String>.from(map['certifications'])
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      verification: map['verification'] != null
          ? Map<String, dynamic>.from(map['verification'])
          : null,
      documents: map['documents'] != null
          ? Map<String, dynamic>.from(map['documents'])
          : null,
    );
  }
}
