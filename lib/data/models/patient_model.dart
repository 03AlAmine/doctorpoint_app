// lib/data/models/patient_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Surgery {
  final String name;
  final DateTime date;
  final String? hospital;
  final String? notes;

  Surgery({
    required this.name,
    required this.date,
    this.hospital,
    this.notes,
  });

  factory Surgery.fromMap(Map<String, dynamic> map) {
    return Surgery(
      name: map['name'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      hospital: map['hospital'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': Timestamp.fromDate(date),
      'hospital': hospital,
      'notes': notes,
    };
  }
}

class Vaccine {
  final String name;
  final DateTime date;
  final DateTime? nextDoseDate;
  final String? notes;

  Vaccine({
    required this.name,
    required this.date,
    this.nextDoseDate,
    this.notes,
  });

  factory Vaccine.fromMap(Map<String, dynamic> map) {
    return Vaccine(
      name: map['name'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      nextDoseDate: map['nextDoseDate'] != null
          ? (map['nextDoseDate'] as Timestamp).toDate()
          : null,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': Timestamp.fromDate(date),
      'nextDoseDate':
          nextDoseDate != null ? Timestamp.fromDate(nextDoseDate!) : null,
      'notes': notes,
    };
  }
}

class Patient {
  final String id;
  final String uid;
  final String email;
  final String fullName;
  final String phone;
  final String? gender;
  final DateTime? birthDate;
  final String? address;
  final String? city;
  final String? postalCode;
  final String? country;
  final String? bloodGroup;
  final List<String>? allergies;
  final List<String>? chronicDiseases;
  final List<String>? currentMedications;
  final List<Surgery>? surgeries;
  final List<Vaccine>? vaccines;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final String? photoUrl;
  final double? height; // en cm
  final double? weight; // en kg
  final bool? smoker;
  final bool? alcoholConsumer;
  final String? occupation;
  final String? maritalStatus;
  final int? numberOfChildren;
  final String? familyMedicalHistory;
  final bool profileCompleted;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Patient({
    required this.id,
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phone,
    this.gender,
    this.birthDate,
    this.address,
    this.city,
    this.postalCode,
    this.country,
    this.bloodGroup,
    this.allergies,
    this.chronicDiseases,
    this.currentMedications,
    this.surgeries,
    this.vaccines,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.photoUrl,
    this.height,
    this.weight,
    this.smoker,
    this.alcoholConsumer,
    this.occupation,
    this.maritalStatus,
    this.numberOfChildren,
    this.familyMedicalHistory,
    required this.profileCompleted,
    required this.emailVerified,
    required this.createdAt,
    this.updatedAt,
  });

  factory Patient.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Gestion sécurisée de createdAt
    DateTime createdAt;
    if (data['createdAt'] != null) {
      try {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } catch (e) {
        print('Erreur parsing createdAt: $e');
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }

    return Patient(
      id: doc.id.isNotEmpty ? doc.id : '',
      uid: data['uid']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      fullName: data['fullName']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      gender: data['gender']?.toString(),
      birthDate: data['birthDate'] != null
          ? (data['birthDate'] as Timestamp).toDate()
          : null,
      address: data['address']?.toString(),
      city: data['city']?.toString(),
      postalCode: data['postalCode']?.toString(),
      country: data['country']?.toString() ?? 'Sénégal',
      bloodGroup: data['bloodGroup']?.toString(),
      allergies: data['allergies'] != null
          ? List<String>.from(data['allergies'])
          : null,
      chronicDiseases: data['chronicDiseases'] != null
          ? List<String>.from(data['chronicDiseases'])
          : null,
      currentMedications: data['currentMedications'] != null
          ? List<String>.from(data['currentMedications'])
          : null,
      surgeries: data['surgeries'] != null
          ? (data['surgeries'] as List).map((s) => Surgery.fromMap(s)).toList()
          : null,
      vaccines: data['vaccines'] != null
          ? (data['vaccines'] as List).map((v) => Vaccine.fromMap(v)).toList()
          : null,
      emergencyContactName: data['emergencyContactName']?.toString(),
      emergencyContactPhone: data['emergencyContactPhone']?.toString(),
      emergencyContactRelation: data['emergencyContactRelation']?.toString(),
      photoUrl: data['photoUrl']?.toString(),
      height:
          data['height'] != null ? (data['height'] as num).toDouble() : null,
      weight:
          data['weight'] != null ? (data['weight'] as num).toDouble() : null,
      smoker: data['smoker'] as bool?,
      alcoholConsumer: data['alcoholConsumer'] as bool?,
      occupation: data['occupation']?.toString(),
      maritalStatus: data['maritalStatus']?.toString(),
      numberOfChildren: data['numberOfChildren'] as int?,
      familyMedicalHistory: data['familyMedicalHistory']?.toString(),
      profileCompleted: data['profileCompleted'] as bool? ?? false,
      emailVerified: data['emailVerified'] as bool? ?? false,
      createdAt: createdAt,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'gender': gender,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'chronicDiseases': chronicDiseases,
      'currentMedications': currentMedications,
      'surgeries': surgeries?.map((s) => s.toMap()).toList(),
      'vaccines': vaccines?.map((v) => v.toMap()).toList(),
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'emergencyContactRelation': emergencyContactRelation,
      'photoUrl': photoUrl,
      'height': height,
      'weight': weight,
      'smoker': smoker,
      'alcoholConsumer': alcoholConsumer,
      'occupation': occupation,
      'maritalStatus': maritalStatus,
      'numberOfChildren': numberOfChildren,
      'familyMedicalHistory': familyMedicalHistory,
      'profileCompleted': profileCompleted,
      'emailVerified': emailVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }


  Patient copyWith({
    String? id,
    String? uid,
    String? email,
    String? fullName,
    String? phone,
    String? gender,
    DateTime? birthDate,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    String? bloodGroup,
    List<String>? allergies,
    List<String>? chronicDiseases,
    List<String>? currentMedications,
    List<Surgery>? surgeries,
    List<Vaccine>? vaccines,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    String? photoUrl,
    double? height,
    double? weight,
    bool? smoker,
    bool? alcoholConsumer,
    String? occupation,
    String? maritalStatus,
    int? numberOfChildren,
    String? familyMedicalHistory,
    bool? profileCompleted,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Patient(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      currentMedications: currentMedications ?? this.currentMedications,
      surgeries: surgeries ?? this.surgeries,
      vaccines: vaccines ?? this.vaccines,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelation:
          emergencyContactRelation ?? this.emergencyContactRelation,
      photoUrl: photoUrl ?? this.photoUrl,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      smoker: smoker ?? this.smoker,
      alcoholConsumer: alcoholConsumer ?? this.alcoholConsumer,
      occupation: occupation ?? this.occupation,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      numberOfChildren: numberOfChildren ?? this.numberOfChildren,
      familyMedicalHistory: familyMedicalHistory ?? this.familyMedicalHistory,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get age {
    if (birthDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  double? get bmi {
    if (height == null || weight == null || height! <= 0 || weight! <= 0) {
      return null;
    }
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'Non disponible';

    if (bmiValue < 18.5) return 'Insuffisance pondérale';
    if (bmiValue < 25) return 'Poids normal';
    if (bmiValue < 30) return 'Surpoids';
    return 'Obésité';
  }

  String get location {
    if (city != null && country != null) {
      return '$city, $country';
    } else if (city != null) {
      return city!;
    } else if (country != null) {
      return country!;
    }
    return 'Localisation non spécifiée';
  }
}
