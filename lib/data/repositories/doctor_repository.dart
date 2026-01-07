import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';

class DoctorRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Doctor>> getDoctors() {
    return _firestore
        .collection('doctors')
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Doctor.fromFirestore(doc))
            .toList());
  }

  Stream<List<Doctor>> getPopularDoctors() {
    return _firestore
        .collection('doctors')
        .where('rating', isGreaterThanOrEqualTo: 4.5)
        .orderBy('rating', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Doctor.fromFirestore(doc))
            .toList());
  }

  Stream<List<Doctor>> getDoctorsBySpecialty(String specialty) {
    return _firestore
        .collection('doctors')
        .where('specialization', isEqualTo: specialty)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Doctor.fromFirestore(doc))
            .toList());
  }

  Stream<Doctor> getDoctorById(String doctorId) {
    return _firestore
        .collection('doctors')
        .doc(doctorId)
        .snapshots()
        .map((snapshot) => Doctor.fromFirestore(snapshot));
  }

  Future<void> toggleFavorite(String doctorId, bool isFavorite) async {
    await _firestore
        .collection('doctors')
        .doc(doctorId)
        .update({'isFavorite': isFavorite});
  }

  Future<List<Doctor>> searchDoctors(String query) async {
    final snapshot = await _firestore
        .collection('doctors')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();
    
    return snapshot.docs
        .map((doc) => Doctor.fromFirestore(doc))
        .toList();
  }
}