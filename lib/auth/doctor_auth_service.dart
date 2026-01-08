import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';

class DoctorAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Connexion du médecin
  Future<User?> signInDoctor(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Vérifier si l'utilisateur est bien un médecin
      final doctorDoc = await _db
          .collection('doctors')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (doctorDoc.docs.isEmpty) {
        await _auth.signOut();
        throw Exception('Aucun compte médecin trouvé avec cet email');
      }

      // Mettre à jour la dernière connexion
      final doctorId = doctorDoc.docs.first.id;
      await _db.collection('doctors').doc(doctorId).update({
        'lastLogin': FieldValue.serverTimestamp(),
        'accountStatus': 'active',
      });

      return userCredential.user;
    } catch (e) {
      print('Erreur connexion médecin: $e');
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Vérifier si l'utilisateur connecté est un médecin
  Future<Doctor?> getCurrentDoctor() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doctorDoc = await _db
          .collection('doctors')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (doctorDoc.docs.isNotEmpty) {
        return Doctor.fromFirestore(doctorDoc.docs.first);
      }
      return null;
    } catch (e) {
      print('Erreur récupération médecin: $e');
      return null;
    }
  }

  // Réinitialiser le mot de passe
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Vérifier l'accès médecin
  Future<bool> hasDoctorAccess() async {
    final doctor = await getCurrentDoctor();
    return doctor != null && (doctor.hasAccount ?? false);
  }

  // Mettre à jour le profil médecin
  Future<void> updateDoctorProfile(Doctor doctor) async {
    final currentDoctor = await getCurrentDoctor();
    if (currentDoctor == null || currentDoctor.id != doctor.id) {
      throw Exception('Non autorisé à modifier ce profil');
    }

    await _db.collection('doctors').doc(doctor.id).update(doctor.toMap());
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

    // Mettre à jour dans Firestore
    final doctorDoc = await _db
        .collection('doctors')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (doctorDoc.docs.isNotEmpty) {
      await _db.collection('doctors').doc(doctorDoc.docs.first.id).update({
        'password': newPassword,
      });
    }
  }
}