// lib/services/auth_service.dart (version complète)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctorpoint/data/models/app_user.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /* ============================================================
   * 🔐 SIGN IN (Connexion unique)
   * ============================================================ */
  Future<AppUser> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final firebaseUser = userCredential.user!;
      final appUser = await _detectUserRole(firebaseUser);
      
      if (appUser == null) {
        await _auth.signOut();
        throw Exception('Aucun compte trouvé avec cet email');
      }

      // Mettre à jour la dernière connexion
      await _updateLastLogin(appUser);

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /* ============================================================
   * 👤 CREATE USER (Générique - tous rôles)
   * ============================================================ */
  Future<AppUser> createUser({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
    Map<String, dynamic>? profileData,
    Map<String, dynamic>? roleSpecificData,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final firebaseUser = userCredential.user!;
      
      final userData = {
        'email': email.trim(),
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'role': role.name,
        'profileCompleted': false,
        'emailVerified': false,
        'profile': profileData ?? {},
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _db.collection('users').doc(firebaseUser.uid).set(userData);
      
      await _createRoleSpecificData(firebaseUser.uid, role, roleSpecificData);
      
      await firebaseUser.sendEmailVerification();

      return AppUser(
        id: firebaseUser.uid,
        email: email.trim(),
        fullName: fullName.trim(),
        phone: phone.trim(),
        role: role,
        profileCompleted: false,
        emailVerified: false,
        createdAt: DateTime.now(),
        profile: profileData,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /* ============================================================
   * 👨‍⚕️ REGISTER PATIENT (Pour interface patient)
   * ============================================================ */
  Future<AppUser> registerPatient({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    return await createUser(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      role: UserRole.patient,
    );
  }

  /* ============================================================
   * 🏥 CREATE DOCTOR (Pour admin)
   * ============================================================ */
  Future<AppUser> createDoctor({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String specialization,
    required String hospital,
    required int experience,
    required String licenseNumber,
    double consultationFee = 80.0,
    Map<String, dynamic>? additionalData,
  }) async {
    final roleSpecificData = {
      'specialization': specialization,
      'hospital': hospital,
      'experience': experience,
      'licenseNumber': licenseNumber,
      'consultationFee': consultationFee,
      'rating': 0.0,
      'reviews': 0,
      'hasAccount': true,
      'accountStatus': 'pending',
      'languages': ['Français'],
      ...?additionalData,
    };

    return await createUser(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      role: UserRole.doctor,
      roleSpecificData: roleSpecificData,
    );
  }

  /* ============================================================
   * 👑 CREATE ADMIN (Pour super admin)
   * ============================================================ */
  Future<AppUser> createAdmin({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    List<String> permissions = const ['all'],
    Map<String, dynamic>? additionalData,
  }) async {
    final roleSpecificData = {
      'permissions': permissions,
      ...?additionalData,
    };

    return await createUser(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      role: UserRole.admin,
      roleSpecificData: roleSpecificData,
    );
  }

  /* ============================================================
   * 🔍 DETECT USER ROLE
   * ============================================================ */
  Future<AppUser?> _detectUserRole(User firebaseUser) async {
    try {
      // Chercher dans users par UID
      final userDoc = await _db.collection('users').doc(firebaseUser.uid).get();
      
      if (!userDoc.exists) {
        // Fallback: chercher par email
        final emailQuery = await _db.collection('users')
          .where('email', isEqualTo: firebaseUser.email)
          .limit(1)
          .get();
        
        if (emailQuery.docs.isNotEmpty) {
          return AppUser.fromFirestore(emailQuery.docs.first);
        }
        
        return null;
      }
      
      final appUser = AppUser.fromFirestore(userDoc);
      
      // Vérification supplémentaire pour les médecins
      if (appUser.isDoctor) {
        final doctorDoc = await _db.collection('doctors').doc(appUser.id).get();
        if (!doctorDoc.exists || !(doctorDoc.data()?['hasAccount'] ?? false)) {
          throw Exception('Compte médecin non activé');
        }
      }
      
      return appUser;
      
    } catch (e) {
      print('Erreur détection rôle: $e');
      return null;
    }
  }

  /* ============================================================
   * 🏗️ CREATE ROLE SPECIFIC DATA (privée)
   * ============================================================ */
  Future<void> _createRoleSpecificData(
    String userId,
    UserRole role,
    Map<String, dynamic>? roleSpecificData,
  ) async {
    if (roleSpecificData == null) return;

    switch (role) {
      case UserRole.doctor:
        await _db.collection('doctors').doc(userId).set({
          ...roleSpecificData,
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        break;
        
      case UserRole.admin:
        await _db.collection('admins').doc(userId).set({
          ...roleSpecificData,
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        break;
        
      case UserRole.patient:
        // Pas de collection séparée pour les patients
        break;
    }
  }

  /* ============================================================
   * 📝 UPDATE LAST LOGIN
   * ============================================================ */
  Future<void> _updateLastLogin(AppUser user) async {
    final now = FieldValue.serverTimestamp();
    
    await _db.collection('users').doc(user.id).update({
      'lastLogin': now,
    });
    
    // Mettre à jour aussi dans les collections spécifiques
    if (user.isDoctor) {
      await _db.collection('doctors').doc(user.id).update({
        'lastLogin': now,
        'accountStatus': 'active',
      });
    } else if (user.isAdmin) {
      await _db.collection('admins').doc(user.id).update({
        'lastLogin': now,
      });
    }
  }

  /* ============================================================
   * 🚪 SIGN OUT
   * ============================================================ */
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /* ============================================================
   * 🔄 GET CURRENT USER
   * ============================================================ */
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return await _detectUserRole(firebaseUser);
  }

  /* ============================================================
   * 📧 RESET PASSWORD
   * ============================================================ */
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /* ============================================================
   * ✅ CHECK EMAIL VERIFICATION
   * ============================================================ */
  Future<bool> checkEmailVerification() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  /* ============================================================
   * 📨 SEND VERIFICATION EMAIL
   * ============================================================ */
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /* ============================================================
   * 🚨 HANDLE AUTH ERRORS
   * ============================================================ */
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'invalid-email':
        return 'Adresse email invalide';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email';
      case 'weak-password':
        return 'Le mot de passe est trop faible (min. 6 caractères)';
      case 'operation-not-allowed':
        return 'La connexion par email/mot de passe n\'est pas activée';
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }

  Future<dynamic> handleStart() async {}
  
}