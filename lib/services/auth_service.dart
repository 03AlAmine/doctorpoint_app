import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /* ============================================================
   * 🔐 REGISTER
   * ============================================================ */
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    await _db.collection('users').doc(uid).set({
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'profileCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return cred.user!;
  }

  /* ============================================================
   * 🔑 LOGIN
   * ============================================================ */
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user!;
  }

  /* ============================================================
   * 👤 COMPLETE PROFILE (SETUP)
   * ============================================================ */
  Future<void> completeProfile({
    required String uid,
    required String gender,
    required DateTime birthDate,
    required String address,
  }) async {
    await _db.collection('users').doc(uid).update({
      'gender': gender,
      'birthDate': birthDate,
      'address': address,
      'profileCompleted': true,
    });
  }

  /* ============================================================
   * 🚀 HANDLE START (Splash / Onboarding)
   * ============================================================ */
  Future<String> handleStart() async {
    final user = _auth.currentUser;

    if (user == null) {
      return 'onboarding'; // pas connecté
    }

    final doc = await _db.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      return 'onboarding';
    }

    final completed = doc.data()?['profileCompleted'] ?? false;

    return completed ? 'home' : 'setup';
  }

  /* ============================================================
   * 📄 GET USER PROFILE
   * ============================================================ */
  Future<Map<String, dynamic>> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }

  /* ============================================================
   * 🚪 LOGOUT
   * ============================================================ */
  Future<void> logout() async {
    await _auth.signOut();
  }
}
