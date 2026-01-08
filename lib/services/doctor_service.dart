import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';

class DoctorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Récupérer tous les médecins
  Stream<List<Doctor>> streamAllDoctors() {
    return _db
        .collection('doctors')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Doctor.fromFirestore(doc))
            .toList());
  }

  // Récupérer un médecin par ID
  Future<Doctor?> getDoctorById(String id) async {
    final doc = await _db.collection('doctors').doc(id).get();
    return doc.exists ? Doctor.fromFirestore(doc) : null;
  }

  // Ajouter un médecin
  Future<void> addDoctor(Doctor doctor) async {
    await _db.collection('doctors').doc(doctor.id).set(doctor.toMap());
  }

  // Mettre à jour un médecin
  Future<void> updateDoctor(Doctor doctor) async {
    await _db.collection('doctors').doc(doctor.id).update(doctor.toMap());
  }

  // Supprimer un médecin
  Future<void> deleteDoctor(String id) async {
    await _db.collection('doctors').doc(id).delete();
  }

  // Rechercher des médecins
  Future<List<Doctor>> searchDoctors(String query) async {
    if (query.isEmpty) return [];
    
    final snapshot = await _db
        .collection('doctors')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snapshot.docs.map((doc) => Doctor.fromFirestore(doc)).toList();
  }

  // Filtrer par spécialité
  Future<List<Doctor>> filterBySpecialty(String specialty) async {
    final snapshot = await _db
        .collection('doctors')
        .where('specialization', isEqualTo: specialty)
        .get();

    return snapshot.docs.map((doc) => Doctor.fromFirestore(doc)).toList();
  }

  // Récupérer les médecins populaires (note > 4.5)
  Future<List<Doctor>> getPopularDoctors() async {
    final snapshot = await _db
        .collection('doctors')
        .where('rating', isGreaterThan: 4.5)
        .limit(4)
        .get();

    return snapshot.docs.map((doc) => Doctor.fromFirestore(doc)).toList();
  }
}