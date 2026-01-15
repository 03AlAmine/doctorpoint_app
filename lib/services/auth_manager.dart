// lib/core/services/auth_manager.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _lastUserEmailKey = 'last_user_email';

  /* ============================================================
   * 🔐 CONNEXION AVEC GESTION DE SESSION
   * ============================================================ */
// lib/services/auth_manager.dart

  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Nettoyer la session précédente
      await _clearPreviousSession();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Sauvegarder l'email de l'utilisateur courant
      await _saveCurrentUserEmail(email.trim());

      // Vérifier si c'est un admin et si l'email n'est pas vérifié
      final user = userCredential.user;
      if (user != null && !user.emailVerified) {
        final db = FirebaseFirestore.instance;
        final userDoc = await db.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final role = userDoc.data()?['role'] as String?;

          // Si c'est un admin, autoriser la connexion sans vérification
          if (role == 'admin') {
            print(
                '✅ Admin connecté sans email vérifié - Autorisation spéciale');
            return user;
          }
        }

        // Pour les non-admins, vérifier l'email
        if (!user.emailVerified) {
          throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Veuillez vérifier votre email avant de vous connecter',
          );
        }
      }

      return userCredential.user;
    } catch (e) {
      print('❌ Erreur connexion: $e');
      rethrow;
    }
  }

  /* ============================================================
   * 🚪 DÉCONNEXION COMPLÈTE
   * ============================================================ */
  Future<void> signOut() async {
    try {
      // Déconnexion Firebase
      await _auth.signOut();

      // Nettoyer le stockage local
      await _clearLocalData();

      // Attendre que Firebase mette à jour l'état
      await Future.delayed(const Duration(milliseconds: 500));

      // print('✅ Déconnexion réussie pour: $currentEmail');
    } catch (e) {
      print('❌ Erreur déconnexion: $e');

      // Tentative de récupération
      try {
        await _auth.signOut();
      } catch (e2) {
        print('❌ Échec déconnexion de secours: $e2');
      }

      rethrow;
    }
  }

  /* ============================================================
   * 🧹 NETTOYAGE SESSION PRÉCÉDENTE
   * ============================================================ */
  Future<void> _clearPreviousSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastEmail = prefs.getString(_lastUserEmailKey);
      final currentUser = _auth.currentUser;

      // Si un autre utilisateur était connecté précédemment
      if (currentUser != null &&
          lastEmail != null &&
          currentUser.email != lastEmail) {
        print('🔄 Changement d\'utilisateur détecté, nettoyage...');
        await _auth.signOut();
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } catch (e) {
      print('⚠️ Erreur nettoyage session: $e');
    }
  }

  /* ============================================================
   * 💾 SAUVEGARDER UTILISATEUR COURANT
   * ============================================================ */
  Future<void> _saveCurrentUserEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUserEmailKey, email);
    } catch (e) {
      print('⚠️ Erreur sauvegarde email: $e');
    }
  }

  /* ============================================================
   * 🗑️ NETTOYAGE DONNÉES LOCALES
   * ============================================================ */
  Future<void> _clearLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastUserEmailKey);
    } catch (e) {
      print('⚠️ Erreur nettoyage données locales: $e');
    }
  }

  /* ============================================================
   * 🔄 RAFRAÎCHIR LE TOKEN
   * ============================================================ */
  Future<void> refreshAuthToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.getIdToken(true);
        print('✅ Token rafraîchi pour: ${user.email}');
      }
    } catch (e) {
      print('⚠️ Erreur rafraîchissement token: $e');
    }
  }

  /* ============================================================
   * 🔍 VÉRIFIER ÉTAT AUTH
   * ============================================================ */
  Future<bool> checkAuthState() async {
    try {
      await _auth.currentUser?.reload();
      return _auth.currentUser != null;
    } catch (e) {
      print('⚠️ Erreur vérification état auth: $e');
      return false;
    }
  }
}
