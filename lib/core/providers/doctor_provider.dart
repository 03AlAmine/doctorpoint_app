import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';

class DoctorProvider with ChangeNotifier {
  List<Doctor> _doctors = [];
  List<Doctor> _popularDoctors = [];
  final List<Doctor> _favoriteDoctors = [];
  bool _isLoading = false;
  String? _error;
  List<String> _availableSpecialties = [];

  List<Doctor> get doctors => _doctors;
  List<Doctor> get popularDoctors => _popularDoctors;
  List<Doctor> get favoriteDoctors => _favoriteDoctors;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get availableSpecialties => _availableSpecialties;

  DoctorProvider() {
    loadDoctors();
    loadPopularDoctors();
    _extractSpecialties();
  }

  Future<void> loadDoctors() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // ESSAYER FIREBASE D'ABORD
      try {
        await loadDoctorsFromFirebase();
      } catch (e) {
        print('Firebase non disponible, utilisation des données mockées: $e');
        // Fallback sur les données mockées
        _doctors = _getMockDoctors();
        _extractSpecialties();
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadPopularDoctors() async {
    try {
      // Pour les données mockées en attendant Firebase
      _popularDoctors = _getMockDoctors().take(4).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _extractSpecialties() {
    final specialties =
        _doctors.map((doctor) => doctor.specialization).toSet().toList();
    _availableSpecialties = ['All'] + specialties;
    notifyListeners();
  }

  List<Doctor> _getMockDoctors() {
    return [
      Doctor(
        id: '1',
        name: 'Dr. Sarah Johnson',
        specialization: 'Cardiologue',
        specialtyIcon: 'assets/icons/heart.svg',
        rating: 4.8,
        reviews: 120,
        experience: 10,
        hospital: 'Hôpital Saint-Louis',
        department: 'Cardiologie',
        imageUrl:
            'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d',
        isFavorite: true,
        consultationFee: 80.0,
        languages: ['Français', 'Anglais', 'Espagnol'],
        description:
            'Spécialiste en cardiologie avec plus de 10 ans d\'expérience dans le traitement des maladies cardiovasculaires.',
        availability: {
          'lundi': ['09:00', '14:00'],
          'mardi': ['10:00', '16:00'],
          'mercredi': ['08:00', '13:00'],
        },
        location: const GeoPoint(48.8566, 2.3522),
        phoneNumber: '+33123456789',
        email: 'sarah.johnson@hospital.com',
        education: ['MD, Université de Paris', 'Spécialisation en Cardiologie'],
        certifications: ['Certified Cardiologist', 'Board Certified'],
      ),
      Doctor(
        id: '2',
        name: 'Dr. Michael Chen',
        specialization: 'Dermatologue',
        specialtyIcon: 'assets/icons/skin.svg',
        rating: 4.9,
        reviews: 89,
        experience: 8,
        hospital: 'Clinique du Marais',
        department: 'Dermatologie',
        imageUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2',
        isFavorite: false,
        consultationFee: 70.0,
        languages: ['Français', 'Chinois'],
        description:
            'Expert en dermatologie esthétique et traitement des maladies de la peau.',
        availability: {
          'lundi': ['14:00', '18:00'],
          'mercredi': ['09:00', '13:00'],
          'vendredi': ['10:00', '16:00'],
        },
      ),
      Doctor(
        id: '3',
        name: 'Dr. Emma Wilson',
        specialization: 'Pédiatre',
        specialtyIcon: 'assets/icons/child.svg',
        rating: 4.7,
        reviews: 156,
        experience: 12,
        hospital: 'Hôpital Necker',
        department: 'Pédiatrie',
        imageUrl:
            'https://images.unsplash.com/photo-1594824434340-7e7dfc37cabb',
        isFavorite: true,
        consultationFee: 65.0,
        languages: ['Français', 'Anglais'],
        description:
            'Pédiatre expérimentée spécialisée dans la santé des enfants et adolescents.',
        availability: {
          'mardi': ['08:00', '12:00'],
          'jeudi': ['09:00', '17:00'],
          'samedi': ['09:00', '13:00'],
        },
      ),
      Doctor(
        id: '4',
        name: 'Dr. James Rodriguez',
        specialization: 'Neurologue',
        specialtyIcon: 'assets/icons/brain.svg',
        rating: 4.6,
        reviews: 95,
        experience: 15,
        hospital: 'Hôpital de la Pitié-Salpêtrière',
        department: 'Neurologie',
        imageUrl:
            'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d',
        isFavorite: false,
        consultationFee: 90.0,
        languages: ['Français', 'Espagnol'],
        description:
            'Neurologue spécialisé dans les troubles du système nerveux.',
        availability: {
          'lundi': ['10:00', '16:00'],
          'mercredi': ['08:00', '14:00'],
          'vendredi': ['09:00', '15:00'],
        },
      ),
      Doctor(
        id: '5',
        name: 'Dr. Sophie Martin',
        specialization: 'Dentiste',
        specialtyIcon: 'assets/icons/tooth.svg',
        rating: 4.8,
        reviews: 112,
        experience: 7,
        hospital: 'Centre Dentaire Paris',
        department: 'Dentisterie',
        imageUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2',
        isFavorite: true,
        consultationFee: 60.0,
        languages: ['Français', 'Anglais', 'Allemand'],
        description:
            'Dentiste générale spécialisée en orthodontie et implantologie.',
        availability: {
          'lundi': ['09:00', '18:00'],
          'mardi': ['08:00', '17:00'],
          'jeudi': ['10:00', '19:00'],
        },
      ),
      Doctor(
        id: '6',
        name: 'Dr. Thomas Bernard',
        specialization: 'Ophtalmologue',
        specialtyIcon: 'assets/icons/eye.svg',
        rating: 4.5,
        reviews: 78,
        experience: 9,
        hospital: 'Institut de la Vision',
        department: 'Ophtalmologie',
        imageUrl:
            'https://images.unsplash.com/photo-1537368910025-700350fe46c7',
        isFavorite: false,
        consultationFee: 75.0,
        languages: ['Français', 'Anglais'],
        description:
            'Spécialiste en chirurgie réfractive et traitement des maladies oculaires.',
      ),
      Doctor(
        id: '7',
        name: 'Dr. Marie Dubois',
        specialization: 'Gynécologue',
        specialtyIcon: 'assets/icons/female.svg',
        rating: 4.9,
        reviews: 134,
        experience: 11,
        hospital: 'Hôpital Saint-Vincent',
        department: 'Gynécologie',
        imageUrl:
            'https://images.unsplash.com/photo-1594824434340-7e7dfc37cabb',
        isFavorite: true,
        consultationFee: 85.0,
        languages: ['Français', 'Arabe'],
        description:
            'Gynécologue obstétricienne spécialisée en suivi de grossesse.',
      ),
      Doctor(
        id: '8',
        name: 'Dr. Ahmed Khan',
        specialization: 'Orthopédiste',
        specialtyIcon: 'assets/icons/bone.svg',
        rating: 4.7,
        reviews: 67,
        experience: 14,
        hospital: 'Clinique Orthopédique',
        department: 'Orthopédie',
        imageUrl:
            'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d',
        isFavorite: false,
        consultationFee: 95.0,
        languages: ['Français', 'Arabe', 'Anglais'],
        description:
            'Chirurgien orthopédique spécialiste en traumatologie sportive.',
      ),
    ];
  }

  Future<void> toggleFavorite(String doctorId) async {
    final doctorIndex = _doctors.indexWhere((doctor) => doctor.id == doctorId);
    final popularIndex =
        _popularDoctors.indexWhere((doctor) => doctor.id == doctorId);

    if (doctorIndex != -1) {
      _doctors[doctorIndex] = _doctors[doctorIndex].copyWith(
        isFavorite: !_doctors[doctorIndex].isFavorite,
      );

      // Mettre à jour aussi dans popularDoctors si présent
      if (popularIndex != -1) {
        _popularDoctors[popularIndex] = _popularDoctors[popularIndex].copyWith(
          isFavorite: !_popularDoctors[popularIndex].isFavorite,
        );
      }

      // Mettre à jour la liste des favoris
      _updateFavoriteDoctors();
      notifyListeners();
    }
  }

  void _updateFavoriteDoctors() {
    _favoriteDoctors.clear();
    _favoriteDoctors.addAll(_doctors.where((doctor) => doctor.isFavorite));
  }

  List<Doctor> getDoctorsBySpecialty(String specialty) {
    if (specialty.toLowerCase() == 'all') {
      return _doctors;
    }
    return _doctors.where((doctor) {
      return doctor.specialization
          .toLowerCase()
          .contains(specialty.toLowerCase());
    }).toList();
  }

  Doctor? getDoctorById(String doctorId) {
    try {
      return _doctors.firstWhere((doctor) => doctor.id == doctorId);
    } catch (e) {
      return null;
    }
  }

  List<Doctor> searchDoctors(String query) {
    if (query.isEmpty) return _doctors;

    return _doctors.where((doctor) {
      return doctor.name.toLowerCase().contains(query.toLowerCase()) ||
          doctor.specialization.toLowerCase().contains(query.toLowerCase()) ||
          doctor.hospital.toLowerCase().contains(query.toLowerCase()) ||
          doctor.department!.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<Doctor> filterDoctors({
    String? specialty,
    double? minRating,
    double? maxPrice,
    String? hospital,
  }) {
    List<Doctor> filtered = _doctors;

    if (specialty != null &&
        specialty.isNotEmpty &&
        specialty.toLowerCase() != 'all') {
      filtered = filtered.where((doctor) {
        return doctor.specialization
            .toLowerCase()
            .contains(specialty.toLowerCase());
      }).toList();
    }

    if (minRating != null) {
      filtered =
          filtered.where((doctor) => doctor.rating >= minRating).toList();
    }

    if (maxPrice != null) {
      filtered = filtered
          .where((doctor) => doctor.consultationFee <= maxPrice)
          .toList();
    }

    if (hospital != null && hospital.isNotEmpty) {
      filtered = filtered.where((doctor) {
        return doctor.hospital.toLowerCase().contains(hospital.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  void refreshData() {
    loadDoctors();
    loadPopularDoctors();
  }

  // ==================== MÉTHODES FIREBASE ====================

  Future<void> addDoctorToFirebase(Doctor doctor) async {
    try {
      print('Tentative d\'ajout du médecin à Firebase...');
      print('Doctor ID: ${doctor.id}');
      print('Doctor Name: ${doctor.name}');
      
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctor.id)
          .set(doctor.toMap());

      print('Médecin ajouté avec succès à Firebase!');
      
      // Ajouter aussi à la liste locale
      _doctors.add(doctor);
      _extractSpecialties();
      notifyListeners();
    } catch (e) {
      print('Erreur lors de l\'ajout du médecin: $e');
      rethrow;
    }
  }

  Future<void> updateDoctorInFirebase(Doctor doctor) async {
    try {
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctor.id)
          .update(doctor.toMap());

      // Mettre à jour la liste locale
      final index = _doctors.indexWhere((d) => d.id == doctor.id);
      if (index != -1) {
        _doctors[index] = doctor;
        _extractSpecialties();
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du médecin: $e');
      rethrow;
    }
  }

  Future<void> deleteDoctorFromFirebase(String doctorId) async {
    try {
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .delete();

      // Supprimer de la liste locale
      _doctors.removeWhere((doctor) => doctor.id == doctorId);
      _extractSpecialties();
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la suppression du médecin: $e');
      rethrow;
    }
  }

  Future<void> loadDoctorsFromFirebase() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('Chargement des médecins depuis Firebase...');
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .orderBy('name')
          .get();

      print('${querySnapshot.docs.length} médecins trouvés dans Firebase');
      
      _doctors = querySnapshot.docs.map((doc) {
        return Doctor.fromFirestore(doc);
      }).toList();

      _extractSpecialties();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement depuis Firebase: $e');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow; // Important: rethrow pour que l'erreur soit capturée
    }
  }
}

extension DoctorCopyWith on Doctor {
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
    List<String>? education,
    List<String>? certifications,
    DateTime? createdAt,
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
      education: education ?? this.education,
      certifications: certifications ?? this.certifications,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}