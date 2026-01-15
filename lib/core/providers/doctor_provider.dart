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
  }

  Future<void> loadDoctors() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await loadDoctorsFromFirebase();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      print('Erreur lors du chargement des médecins: $e');
    }
  }

  Future<void> loadPopularDoctors() async {
    try {
      if (_doctors.isNotEmpty) {
        final sorted = List<Doctor>.from(_doctors);
        sorted.sort((a, b) => b.rating.compareTo(a.rating));

        _popularDoctors = sorted.take(4).toList();

        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors du chargement des médecins populaires: $e');
    }
  }

  void _extractSpecialties() {
    final specialties = _doctors
        .map((doctor) => doctor.specialization)
        .where((specialty) => specialty.isNotEmpty)
        .toSet()
        .toList();

    specialties.sort();
    _availableSpecialties = ['Tous'] + specialties;
    notifyListeners();
  }

  Future<void> toggleFavorite(String doctorId) async {
    try {
      final doctorIndex =
          _doctors.indexWhere((doctor) => doctor.id == doctorId);
      final popularIndex =
          _popularDoctors.indexWhere((doctor) => doctor.id == doctorId);

      if (doctorIndex != -1) {
        final newFavoriteStatus = !_doctors[doctorIndex].isFavorite;

        // Mettre à jour dans Firebase
        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorId)
            .update({
          'isFavorite': newFavoriteStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Mettre à jour localement
        _doctors[doctorIndex] = _doctors[doctorIndex].copyWith(
          isFavorite: newFavoriteStatus,
        );

        // Mettre à jour aussi dans popularDoctors si présent
        if (popularIndex != -1) {
          _popularDoctors[popularIndex] =
              _popularDoctors[popularIndex].copyWith(
            isFavorite: newFavoriteStatus,
          );
        }

        // Mettre à jour la liste des favoris
        _updateFavoriteDoctors();
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors de la modification du favori: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  void _updateFavoriteDoctors() {
    _favoriteDoctors.clear();
    _favoriteDoctors.addAll(_doctors.where((doctor) => doctor.isFavorite));
  }

  List<Doctor> getDoctorsBySpecialty(String specialty) {
    if (specialty == 'Tous' || specialty.isEmpty) {
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

    final lowerQuery = query.toLowerCase();
    return _doctors.where((doctor) {
      return doctor.name.toLowerCase().contains(lowerQuery) ||
          doctor.specialization.toLowerCase().contains(lowerQuery) ||
          doctor.hospital.toLowerCase().contains(lowerQuery) ||
          (doctor.department?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  List<Doctor> filterDoctors({
    String? specialty,
    double? minRating,
    double? maxPrice,
    String? hospital,
  }) {
    List<Doctor> filtered = _doctors;

    if (specialty != null && specialty.isNotEmpty && specialty != 'Tous') {
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
  }

  // ==================== MÉTHODES FIREBASE ====================

  Future<void> addDoctorToFirebase(Doctor doctor) async {
    try {
     /* print('Ajout du médecin à Firebase...');
      print('Doctor ID: ${doctor.id}');
      print('Doctor Name: ${doctor.name}');*/

      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctor.id)
          .set({
        ...doctor.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Médecin ajouté avec succès à Firebase!');

      // Ajouter aussi à la liste locale
      _doctors.add(doctor);
      _extractSpecialties();
      loadPopularDoctors(); // Recharger les médecins populaires
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
          .update({
        ...doctor.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour la liste locale
      final index = _doctors.indexWhere((d) => d.id == doctor.id);
      if (index != -1) {
        _doctors[index] = doctor;
        _extractSpecialties();
        loadPopularDoctors(); // Recharger les médecins populaires
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
      loadPopularDoctors(); // Recharger les médecins populaires
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

     /* print('Chargement des médecins depuis Firebase...');*/

      final querySnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .orderBy('name')
          .get();

      /*print('${querySnapshot.docs.length} médecins trouvés dans Firebase');*/

      _doctors = querySnapshot.docs.map((doc) {
        return Doctor.fromFirestore(doc);
      }).toList();

      _extractSpecialties();
      _updateFavoriteDoctors();
      loadPopularDoctors();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement depuis Firebase: $e');
      _isLoading = false;
      _error =
          'Impossible de charger les médecins. Vérifiez votre connexion internet.';
      notifyListeners();
      rethrow;
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
