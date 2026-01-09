// lib/core/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctorpoint/services/auth_service.dart';
import 'package:doctorpoint/data/models/app_user.dart';
import 'package:doctorpoint/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

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

  // Initialiser l'authentification
  Future<void> initialize() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        _currentUser = await _authService.getCurrentUser();

        // Charger le profil si patient
        if (_currentUser?.isPatient ?? false) {
          // Charger le profil utilisateur
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

  // Connexion
  Future<AppUser?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.signIn(email, password);
      _currentUser = user;

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

  // Inscription patient
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

  // Déconnexion
  Future<void> signOut() async {
    try {
      print('🔄 AuthProvider signOut() appelé');

      // Appeler AuthService pour la déconnexion Firebase
      await _authService.signOut();

      // Réinitialiser l'état local
      _currentUser = null;
      _userProfile = null;

      print('✅ AuthProvider signOut() terminé avec succès');
    } catch (e) {
      print('❌ Erreur AuthProvider signOut(): $e');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  // Réinitialiser le mot de passe
  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  // Vérifier l'email
  Future<bool> checkEmailVerification() async {
    return await _authService.checkEmailVerification();
  }

  // Renvoyer l'email de vérification
  Future<void> sendVerificationEmail() async {
    await _authService.sendVerificationEmail();
  }

  // Rafraîchir l'utilisateur courant
  Future<void> refreshUser() async {
    if (FirebaseAuth.instance.currentUser != null) {
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
    }
  }
}
