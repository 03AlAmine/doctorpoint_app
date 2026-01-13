// lib/core/providers/auth_provider.dart - MODIFIÉ
import 'package:doctorpoint/data/models/patient_model.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctorpoint/services/auth_service.dart';
import 'package:doctorpoint/services/patient_service.dart'; // AJOUTEZ CET IMPORT
import 'package:doctorpoint/data/models/app_user.dart';
import 'package:doctorpoint/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final PatientService _patientService = PatientService(); // AJOUTEZ CE SERVICE

  AppUser? _currentUser;
  UserModel? _userProfile;
  bool _isLoading = true;
  bool _isFirstLaunch = true;

  AppUser? get currentUser => _currentUser;
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isLoggedIn => _currentUser != null;
  bool get isPatient => _currentUser?.isPatient ?? false;
  bool get isDoctor => _currentUser?.isDoctor ?? false;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  // Initialiser l'authentification - MODIFIÉ
  Future<void> initialize() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        _currentUser = await _authService.getCurrentUser();

        // Charger le profil utilisateur - AJOUTEZ CE CODE
        if (_currentUser?.isPatient ?? false) {
          await _loadPatientProfile();
        }
      }

      // Vérifier si premier lancement
      final prefs = await SharedPreferences.getInstance();
      _isFirstLaunch = prefs.getBool('first_launch') ?? true;
    } catch (e) {
      print('Erreur initialisation auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // NOUVELLE MÉTHODE : Charger le profil patient
  Future<void> _loadPatientProfile() async {
    try {
      final patient = await _patientService.getPatientProfile();
      if (patient != null) {
        _userProfile = UserModel(
          uid: patient.uid,
          email: patient.email,
          fullName: patient.fullName,
          phone: patient.phone,
          gender: patient.gender,
          birthDate: patient.birthDate,
          address: patient.address,
          photoUrl: patient.photoUrl,
          profileCompleted: patient.profileCompleted,
          createdAt: patient.createdAt,
        );
      }
    } catch (e) {
      print('Erreur chargement profil patient: $e');
    }
  }

  // MODIFIEZ la méthode registerPatient
  Future<AppUser?> registerPatient({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.registerPatient(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );

      _currentUser = user;
      
      // Créer le profil patient dans Firestore
      await _patientService.savePatientProfile(
        Patient(
          id: user.id,
          uid: user.id,
          email: user.email,
          fullName: fullName,
          phone: phone,
          profileCompleted: false,
          emailVerified: false,
          createdAt: DateTime.now(),
        ),
      );

      // Charger le profil après création
      await _loadPatientProfile();

      // Marquer comme pas premier lancement
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('first_launch', false);
      _isFirstLaunch = false;

      return user;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // MODIFIEZ la méthode signOut
  Future<void> signOut() async {
    try {
      print('🔄 AuthProvider signOut() appelé');

      await _authService.signOut();

      // Réinitialiser l'état local
      _currentUser = null;
      _userProfile = null;

      await Future.delayed(const Duration(milliseconds: 300));

      print('✅ AuthProvider signOut() terminé avec succès');
    } catch (e) {
      print('❌ Erreur AuthProvider signOut(): $e');
      
      try {
        await FirebaseAuth.instance.signOut();
        _currentUser = null;
        _userProfile = null;
      } catch (e2) {
        print('❌ Erreur déconnexion forcée: $e2');
      }
      
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  // NOUVELLE MÉTHODE : Rafraîchir le profil
  Future<void> refreshProfile() async {
    if (_currentUser?.isPatient ?? false) {
      await _loadPatientProfile();
      notifyListeners();
    }
  }

  // Autres méthodes restent inchangées...
  Future<AppUser?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.signIn(email, password);
      _currentUser = user;

      // Charger le profil patient si c'est un patient
      if (user.isPatient) {
        await _loadPatientProfile();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('first_launch', false);
      _isFirstLaunch = false;

      return user;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  Future<bool> checkEmailVerification() async {
    return await _authService.checkEmailVerification();
  }

  Future<void> sendVerificationEmail() async {
    await _authService.sendVerificationEmail();
  }

  Future<void> refreshUser() async {
    if (FirebaseAuth.instance.currentUser != null) {
      _currentUser = await _authService.getCurrentUser();
      
      // Recharger le profil si patient
      if (_currentUser?.isPatient ?? false) {
        await _loadPatientProfile();
      }
      
      notifyListeners();
    }
  }
}