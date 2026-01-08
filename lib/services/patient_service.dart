import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctorpoint/data/models/patient_model.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PatientService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Récupérer le profil patient
  Future<Patient?> getPatientProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _db.collection('patients').doc(user.uid).get();
      if (doc.exists) {
        return Patient.fromFirestore(doc);
      }
      // Si le document n'existe pas, créer un patient vide
      return Patient(
        id: user.uid,
        uid: user.uid,
        email: user.email ?? '',
        fullName: user.displayName ?? 'Utilisateur',
        phone: user.phoneNumber ?? '',
        profileCompleted: false,
        emailVerified: user.emailVerified,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('Erreur récupération profil: $e');
      // Retourner un patient vide en cas d'erreur
      return Patient(
        id: user.uid,
        uid: user.uid,
        email: user.email ?? '',
        fullName: user.displayName ?? 'Utilisateur',
        phone: user.phoneNumber ?? '',
        profileCompleted: false,
        emailVerified: user.emailVerified,
        createdAt: DateTime.now(),
      );
    }
  }

  // Sauvegarder le profil patient (crée ou met à jour)
  Future<void> savePatientProfile(Patient patient) async {
    try {
      // Vérifier que l'ID n'est pas vide
      if (patient.id.isEmpty) {
        throw Exception('ID patient vide');
      }

      await _db.collection('patients').doc(patient.id).set(
            patient.toMap(),
            SetOptions(merge: true),
          );
      print('Profil sauvegardé avec succès pour: ${patient.email}');
    } catch (e) {
      print('Erreur sauvegarde profil: $e');
      rethrow;
    }
  }

  // Mettre à jour le profil patient (pour les mises à jour partielles)
  Future<void> updatePatientProfile(Patient patient) async {
    try {
      if (patient.id.isEmpty) {
        throw Exception('ID patient vide');
      }

      await _db.collection('patients').doc(patient.id).update(patient.toMap());
    } catch (e) {
      print('Erreur mise à jour profil: $e');
      rethrow;
    }
  }



  // Uploader une photo de profil
  Future<String?> uploadProfilePhoto(String filePath) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final ref = _storage.ref().child('patients/${user.uid}/profile.jpg');
      await ref.putFile(File(filePath));
      return await ref.getDownloadURL();
    } catch (e) {
      print('Erreur upload photo: $e');
      return null;
    }
  }

  // Vérifier si le profil est complet
  Future<bool> isProfileComplete() async {
    final patient = await getPatientProfile();
    if (patient == null) return false;

    return patient.profileCompleted &&
        patient.gender != null &&
        patient.birthDate != null &&
        patient.address != null &&
        patient.city != null;
  }

  // Récupérer l'historique médical
  Stream<List<Map<String, dynamic>>> getMedicalHistory() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('patients')
        .doc(user.uid)
        .collection('medical_history')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                  'date': (doc.data()['date'] as Timestamp).toDate(),
                })
            .toList());
  }

  // Récupérer les rendez-vous
  Stream<List<Map<String, dynamic>>> getAppointments() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('patients')
        .doc(user.uid)
        .collection('appointments')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                  'date': (doc.data()['date'] as Timestamp).toDate(),
                })
            .toList());
  }

  // Ajouter une allergie
  Future<void> addAllergy(String allergy) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db.collection('patients').doc(user.uid).update({
        'allergies': FieldValue.arrayUnion([allergy]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur ajout allergie: $e');
      rethrow;
    }
  }

  // Supprimer une allergie
  Future<void> removeAllergy(String allergy) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db.collection('patients').doc(user.uid).update({
        'allergies': FieldValue.arrayRemove([allergy]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur suppression allergie: $e');
      rethrow;
    }
  }

  // Changer le mot de passe
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> deleteAccount() async {}
}
