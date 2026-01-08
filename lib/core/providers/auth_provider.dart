import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String uid;
  final String fullName;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final bool isProfileComplete;

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.isProfileComplete = false,
  });

  bool get isProfileIncomplete => !isProfileComplete;

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      gender: data['gender'],
      isProfileComplete: data['isProfileComplete'] ?? false,
    );
  }
}

class AuthProvider with ChangeNotifier {
  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isFirstLaunch = true;

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isFirstLaunch => _isFirstLaunch;

  AuthProvider() {
    // Vérifier le premier lancement
    _checkFirstLaunch();
  }

  void _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstLaunch = prefs.getBool('first_launch') ?? true;
    if (_isFirstLaunch) {
      await prefs.setBool('first_launch', false);
    }
    notifyListeners();
  }

  void initialize() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserProfile(user.uid);
      } else {
        _userProfile = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists) {
        _userProfile =
            UserProfile.fromFirestore(doc.data() as Map<String, dynamic>, uid);
      } else {
        _userProfile = UserProfile(
          uid: uid,
          fullName: '',
          email: _user?.email ?? '',
          isProfileComplete: false,
        );
      }
    } catch (e) {
      print('Erreur lors du chargement du profil: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _user = null;
    _userProfile = null;
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        ...data,
        'isProfileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _loadUserProfile(_user!.uid);
    } catch (e) {
      print('Erreur lors de la mise à jour du profil: $e');
      rethrow;
    }
  }
}
