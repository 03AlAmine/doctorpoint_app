// ignore_for_file: unused_element

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctorpoint/data/models/app_user.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /* ============================================================
   * 🔐 SIGN IN (Connexion unique) - LOGIQUE AMÉLIORÉE
   * ============================================================ */
  Future<AppUser> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final firebaseUser = userCredential.user!;

      // Vérifier si l'email est vérifié - SAUF POUR LES ADMINS
      if (!firebaseUser.emailVerified) {
        // Vérifier si c'est un administrateur
        final userDoc =
            await _db.collection('users').doc(firebaseUser.uid).get();

        if (userDoc.exists) {
          final role = userDoc.data()?['role'] as String?;

          if (role == 'admin') {
            // Si c'est un admin, passer outre la vérification d'email
            print('⚠️ Admin connecté sans email vérifié - Accès autorisé');
          } else {
            throw Exception(
                'Veuillez vérifier votre email avant de vous connecter');
          }
        } else {
          throw Exception(
              'Veuillez vérifier votre email avant de vous connecter');
        }
      }

      // Détecter le rôle de l'utilisateur
      final appUser = await _detectUserRole(firebaseUser);

      if (appUser == null) {
        await _auth.signOut();
        throw Exception('Aucun compte trouvé avec cet email');
      }

      // Vérifications spécifiques pour les médecins
      if (appUser.isDoctor) {
        final doctorDoc = await _db.collection('doctors').doc(appUser.id).get();

        if (!doctorDoc.exists) {
          throw Exception('Profil médecin introuvable');
        }

        final doctorData = doctorDoc.data()!;
        final accountStatus = doctorData['accountStatus'] ?? 'pending';

        // Si compte en attente d'approbation
        if (accountStatus == 'pending') {
          throw Exception(
              'Votre compte médecin est en attente d\'approbation par l\'administration');
        }

        // Si compte rejeté
        if (accountStatus == 'rejected') {
          final rejectReason = doctorData['rejectReason'] ?? '';
          throw Exception(
              'Votre compte a été rejeté${rejectReason.isNotEmpty ? ': $rejectReason' : ''}');
        }

        // Vérifier le statut de vérification
        final roleData = doctorData['roleData'] as Map<String, dynamic>?;
        final verification = roleData?['verification'] as Map<String, dynamic>?;
        final verificationStatus =
            verification?['status'] ?? 'pending_documents';

        // Si documents en attente ou en cours de vérification
        if (verificationStatus == 'pending_documents' ||
            verificationStatus == 'under_review') {
          // L'utilisateur sera redirigé vers la page des documents
          return appUser;
        }
      }

      // Mettre à jour la dernière connexion
      await _updateLastLogin(appUser);

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /* ============================================================
   * 👨‍⚕️ CREATE DOCTOR ACCOUNT (Pour admin) - CORRIGÉ
   * ============================================================ */
  Future<Doctor> createDoctorAccount({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String specialization,
    required String licenseNumber,
    required String hospital,
    required int experience,
    double consultationFee = 80.0,
    double rating = 4.5,
    int reviews = 0,
    List<String> languages = const ['Français'],
    String? description,
    Map<String, dynamic>? availability,
    String? imageUrl,
  }) async {
    try {
      // 1. Créer le compte Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final userId = userCredential.user!.uid;

      // 2. Créer l'utilisateur dans Firestore
      await _db.collection('users').doc(userId).set({
        'uid': userId,
        'email': email.trim(),
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'role': 'doctor',
        'profileCompleted': false,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'doctorId': userId,
      });

      // 3. Créer le médecin dans la collection doctors
      final doctor = Doctor(
        id: userId,
        name: fullName.trim(),
        specialization: specialization.trim(),
        rating: rating,
        reviews: reviews,
        experience: experience,
        hospital: hospital.trim(),
        imageUrl: imageUrl ??
            'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d',
        isFavorite: false,
        consultationFee: consultationFee,
        languages: languages,
        description: description,
        availability: availability ?? _defaultAvailability(),
        phoneNumber: phone.trim(),
        email: email.trim(),
        hasAccount: true,
        accountStatus: 'active',
        roles: const ['doctor'],
        roleData: {
          'licenseNumber': licenseNumber.trim(),
          'specialization': specialization.trim(),
          'documents': {
            'cni': {'uploaded': false, 'url': null, 'uploadedAt': null},
            'diploma': {'uploaded': false, 'url': null, 'uploadedAt': null},
            'certificate': {'uploaded': false, 'url': null, 'uploadedAt': null},
          },
          'verification': {
            'status': 'pending_documents',
            'verifiedBy': null,
            'verifiedAt': null,
            'notes': null,
          }
        },
        createdAt: DateTime.now(),
        location: const GeoPoint(48.8566, 2.3522),
      );

      await _db.collection('doctors').doc(userId).set({
        ...doctor.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Envoyer l'email de vérification
      await userCredential.user!.sendEmailVerification();

      return doctor;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Un compte existe déjà avec cet email');
      }
      rethrow;
    } catch (e) {
      print('Erreur création compte médecin: $e');
      rethrow;
    }
  }

/* ============================================================
 * 📝 REGISTER DOCTOR REQUEST (Inscription publique) - ENRICHIE
 * ============================================================ */
  Future<void> registerDoctorRequest({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String specialization,
    required String licenseNumber,
    String hospital = '',
    int experience = 0,
    String description = '',
  }) async {
    try {
      // Vérifier si l'email existe déjà dans doctor_requests
      final existingRequests = await _db
          .collection('doctor_requests')
          .where('email', isEqualTo: email.trim())
          .where('status', whereIn: ['pending', 'approved']).get();

      if (existingRequests.docs.isNotEmpty) {
        throw Exception('Une demande existe déjà avec cet email');
      }

      // Vérifier si l'email existe déjà dans users
      final existingUser = await _db
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception('Un utilisateur existe déjà avec cet email');
      }

      // Vérifier si l'email existe déjà dans doctors
      final existingDoctor = await _db
          .collection('doctors')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (existingDoctor.docs.isNotEmpty) {
        throw Exception('Un médecin existe déjà avec cet email');
      }

      // Générer un ID pour la demande
      final requestId = _db.collection('doctor_requests').doc().id;

      // Sauvegarder la demande avec toutes les informations
      await _db.collection('doctor_requests').doc(requestId).set({
        'requestId': requestId,
        'name': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'specialization': specialization.trim(),
        'licenseNumber': licenseNumber.trim(),
        'hospital': hospital.trim(),
        'experience': experience,
        'description': description.trim(),
        'password': password,
        'status': 'pending',
        'requestDate': FieldValue.serverTimestamp(),
        'source': 'public_registration',
        'documents': {
          'cni': {'uploaded': false, 'url': null, 'uploadedAt': null},
          'diploma': {'uploaded': false, 'url': null, 'uploadedAt': null},
          'certificate': {'uploaded': false, 'url': null, 'uploadedAt': null},
        },
      });

      print('✅ Demande médecin créée: $requestId');
    } catch (e) {
      print('❌ Erreur création demande médecin: $e');
      rethrow;
    }
  }

/* ============================================================
 * ✅ APPROVE DOCTOR REQUEST (Admin approuve la demande) - ENRICHIE
 * ============================================================ */
  Future<void> approveDoctorRequest({
    required String requestId,
    required Map<String, dynamic> requestData,
    required String approvedBy,
  }) async {
    try {
      final email = requestData['email'];
      final password = requestData['password'];
      final fullName = requestData['name'];
      final phone = requestData['phone'];
      final specialization = requestData['specialization'];
      final licenseNumber = requestData['licenseNumber'];
      final hospital = requestData['hospital'] ?? 'À définir';
      final experience = requestData['experience'] ?? 0;
      final description = requestData['description'] ?? '';

      // 1. Créer le compte Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final userId = userCredential.user!.uid;

      // 2. Créer l'utilisateur dans Firestore
      await _db.collection('users').doc(userId).set({
        'uid': userId,
        'email': email.trim(),
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'role': 'doctor',
        'profileCompleted': false,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'doctorId': userId,
      });

      // 3. Créer le médecin dans doctors avec toutes les informations
      final doctor = Doctor(
        id: userId,
        name: fullName.trim(),
        specialization: specialization.trim(),
        rating: 0.0,
        reviews: 0,
        experience: experience,
        hospital: hospital,
        imageUrl:
            'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d',
        isFavorite: false,
        consultationFee: 0.0,
        languages: ['Français'],
        description: description.isNotEmpty ? description : null,
        availability: _defaultAvailability(),
        phoneNumber: phone.trim(),
        email: email.trim(),
        hasAccount: true,
        accountStatus: 'active',
        roles: const ['doctor'],
        roleData: {
          'licenseNumber': licenseNumber.trim(),
          'specialization': specialization.trim(),
          'documents': {
            'cni': {'uploaded': false, 'url': null, 'uploadedAt': null},
            'diploma': {'uploaded': false, 'url': null, 'uploadedAt': null},
            'certificate': {'uploaded': false, 'url': null, 'uploadedAt': null},
          },
          'verification': {
            'status': 'pending_documents',
            'verifiedBy': approvedBy,
            'verifiedAt': FieldValue.serverTimestamp(),
            'notes': null,
          }
        },
        createdAt: DateTime.now(),
      );

      await _db.collection('doctors').doc(userId).set({
        ...doctor.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Mettre à jour la demande
      await _db.collection('doctor_requests').doc(requestId).update({
        'status': 'approved',
        'approvedBy': approvedBy,
        'approvedAt': FieldValue.serverTimestamp(),
        'doctorId': userId,
        'password': FieldValue.delete(),
      });

      // 5. Envoyer l'email de vérification
      await userCredential.user!.sendEmailVerification();

      print('✅ Compte médecin créé pour: $email');
      print('📧 Email de vérification envoyé');
    } catch (e) {
      print('❌ Erreur approbation demande: $e');
      rethrow;
    }
  }

/* ============================================================
 * 📧 ENVOYER NOTIFICATION D'APPROBATION
 * ============================================================ */
  Future<void> _sendApprovalNotification(String email, String password) async {
    // Implémenter l'envoi d'email (Firebase Functions ou service email)
    print('✅ Compte approuvé pour $email');
    print('📧 Email de notification à envoyer');

    // En attendant, on peut utiliser Firebase Cloud Messaging
    try {
      // Logique pour notifier l'utilisateur
      print('📲 Notification envoyée pour $email');
    } catch (e) {
      print('Erreur notification: $e');
    }
  }

  /* ============================================================
   * ❌ REJECT DOCTOR REQUEST (Admin rejette la demande)
   * ============================================================ */
  Future<void> rejectDoctorRequest({
    required String requestId,
    required Map<String, dynamic> requestData,
    required String rejectedBy,
    String? reason,
  }) async {
    try {
      // Mettre à jour la demande
      await _db.collection('doctor_requests').doc(requestId).update({
        'status': 'rejected',
        'rejectedBy': rejectedBy,
        'rejectReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'password': FieldValue.delete(),
      });
    } catch (e) {
      print('Erreur rejet demande: $e');
      rethrow;
    }
  }

  /* ============================================================
   * 📄 UPLOAD DOCTOR DOCUMENT (Docteur upload ses documents)
   * ============================================================ */
  Future<void> uploadDoctorDocument({
    required String doctorId,
    required String documentType,
    required String fileUrl,
  }) async {
    try {
      await _db.collection('doctors').doc(doctorId).update({
        'roleData.documents.$documentType.uploaded': true,
        'roleData.documents.$documentType.url': fileUrl,
        'roleData.documents.$documentType.uploadedAt':
            FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Vérifier si tous les documents sont uploadés
      final doc = await _db.collection('doctors').doc(doctorId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final roleData = data['roleData'] as Map<String, dynamic>;
        final documents = roleData['documents'] as Map<String, dynamic>;

        final allUploaded =
            documents.values.every((doc) => doc['uploaded'] == true);

        if (allUploaded) {
          await _db.collection('doctors').doc(doctorId).update({
            'roleData.verification.status': 'under_review',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Erreur upload document: $e');
      rethrow;
    }
  }

  /* ============================================================
   * 🎯 COMPLETE DOCTOR PROFILE (Docteur complète son profil)
   * ============================================================ */
  Future<void> completeDoctorProfile({
    required String doctorId,
    required String hospital,
    required int experience,
    required double consultationFee,
    required List<String> languages,
    String? description,
    Map<String, dynamic>? availability,
    String? imageUrl,
  }) async {
    try {
      // Mettre à jour le médecin
      await _db.collection('doctors').doc(doctorId).update({
        'hospital': hospital,
        'experience': experience,
        'consultationFee': consultationFee,
        'languages': languages,
        if (description != null) 'description': description,
        if (availability != null) 'availability': availability,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour l'utilisateur
      await _db.collection('users').doc(doctorId).update({
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Si tous les documents sont vérifiés, marquer comme complet
      final doc = await _db.collection('doctors').doc(doctorId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final roleData = data['roleData'] as Map<String, dynamic>;
        final verification = roleData['verification'] as Map<String, dynamic>;

        if (verification['status'] == 'under_review') {
          await _db.collection('doctors').doc(doctorId).update({
            'roleData.verification.status': 'completed',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Erreur complétion profil médecin: $e');
      rethrow;
    }
  }

  /* ============================================================
   * 🔍 DETECT USER ROLE - LOGIQUE AMÉLIORÉE
   * ============================================================ */
  Future<AppUser?> _detectUserRole(User firebaseUser) async {
    try {
      // 1. Chercher dans users par UID
      final userDoc = await _db.collection('users').doc(firebaseUser.uid).get();

      if (userDoc.exists) {
        final appUser = AppUser.fromFirestore(userDoc);

        // Pour les médecins, vérifier le statut
        if (appUser.isDoctor) {
          final doctorDoc =
              await _db.collection('doctors').doc(appUser.id).get();
          if (doctorDoc.exists) {
            final doctorData = doctorDoc.data()!;
            final accountStatus = doctorData['accountStatus'] ?? 'pending';

            // Si compte rejeté, empêcher la connexion
            if (accountStatus == 'rejected') {
              return null;
            }
          }
        }

        return appUser;
      }

      // 2. Si pas dans users, chercher dans doctors par UID
      final doctorDoc =
          await _db.collection('doctors').doc(firebaseUser.uid).get();

      if (doctorDoc.exists) {
        final doctorData = doctorDoc.data()!;
        final accountStatus = doctorData['accountStatus'] ?? 'pending';

        // Vérifier le statut du compte
        if (accountStatus == 'rejected') {
          return null;
        }

        // Créer l'utilisateur dans users s'il n'existe pas
        final appUser = AppUser(
          id: firebaseUser.uid,
          email: doctorData['email']?.toString() ?? '',
          fullName: doctorData['name']?.toString() ?? '',
          phone: doctorData['phoneNumber']?.toString() ?? '',
          role: UserRole.doctor,
          profileCompleted: false,
          emailVerified: firebaseUser.emailVerified,
          createdAt: DateTime.now(),
          profile: {
            'doctorId': firebaseUser.uid,
            'specialization': doctorData['specialization']?.toString() ?? '',
            'hospital': doctorData['hospital']?.toString() ?? '',
            'accountStatus': accountStatus,
          },
        );

        await _db.collection('users').doc(firebaseUser.uid).set({
          'uid': firebaseUser.uid,
          'email': appUser.email,
          'fullName': appUser.fullName,
          'phone': appUser.phone,
          'role': 'doctor',
          'profileCompleted': appUser.profileCompleted,
          'emailVerified': firebaseUser.emailVerified,
          'profile': appUser.profile,
          'doctorId': firebaseUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });

        return appUser;
      }

      // 3. Si pas trouvé par UID, chercher par email dans users
      if (firebaseUser.email != null) {
        final emailQuery = await _db
            .collection('users')
            .where('email', isEqualTo: firebaseUser.email!.toLowerCase())
            .limit(1)
            .get();

        if (emailQuery.docs.isNotEmpty) {
          return AppUser.fromFirestore(emailQuery.docs.first);
        }
      }

      // 4. Si pas trouvé par email dans users, chercher dans doctors
      if (firebaseUser.email != null) {
        final doctorEmailQuery = await _db
            .collection('doctors')
            .where('email', isEqualTo: firebaseUser.email!.toLowerCase())
            .limit(1)
            .get();

        if (doctorEmailQuery.docs.isNotEmpty) {
          final doctorData = doctorEmailQuery.docs.first.data();
          final doctorId = doctorEmailQuery.docs.first.id;
          final accountStatus = doctorData['accountStatus'] ?? 'pending';

          if (accountStatus == 'rejected') {
            return null;
          }

          // Créer l'utilisateur
          final appUser = AppUser(
            id: doctorId,
            email: doctorData['email']?.toString() ?? '',
            fullName: doctorData['name']?.toString() ?? '',
            phone: doctorData['phoneNumber']?.toString() ?? '',
            role: UserRole.doctor,
            profileCompleted: false,
            emailVerified: firebaseUser.emailVerified,
            createdAt: DateTime.now(),
            profile: {
              'doctorId': doctorId,
              'specialization': doctorData['specialization']?.toString() ?? '',
              'hospital': doctorData['hospital']?.toString() ?? '',
              'accountStatus': accountStatus,
            },
          );

          await _db.collection('users').doc(doctorId).set({
            'uid': doctorId,
            'email': appUser.email,
            'fullName': appUser.fullName,
            'phone': appUser.phone,
            'role': 'doctor',
            'profileCompleted': appUser.profileCompleted,
            'emailVerified': firebaseUser.emailVerified,
            'profile': appUser.profile,
            'doctorId': doctorId,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          });

          return appUser;
        }
      }

      return null;
    } catch (e) {
      print('❌ Erreur détection rôle: $e');
      return null;
    }
  }

  /* ============================================================
   * 🛠️ MÉTHODES UTILITAIRES
   * ============================================================ */
  Map<String, dynamic> _defaultAvailability() {
    return {
      'Lundi': ['09:00', '17:00'],
      'Mardi': ['09:00', '17:00'],
      'Mercredi': ['09:00', '17:00'],
      'Jeudi': ['09:00', '17:00'],
      'Vendredi': ['09:00', '17:00'],
      'Samedi': ['Fermé'],
      'Dimanche': ['Fermé'],
    };
  }

  Future<void> _updateLastLogin(AppUser user) async {
    final now = FieldValue.serverTimestamp();

    await _db.collection('users').doc(user.id).update({
      'lastLogin': now,
    });

    if (user.isDoctor) {
      await _db.collection('doctors').doc(user.id).update({
        'lastLogin': now,
      });
    }
  }

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
      case 'network-request-failed':
        return 'Erreur réseau. Vérifiez votre connexion internet';
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }

/* ============================================================
 * 🚪 SIGN OUT (Déconnexion complète)
 * ============================================================ */
  Future<void> signOut() async {
    try {
     // print('🔄 Démarrage de la déconnexion...');

      // 1. Sign out de Firebase Auth
      await _auth.signOut();

      // 2. Attendre que le sign out soit effectif
      await Future.delayed(const Duration(milliseconds: 500));

      // 3. Vérifier que l'utilisateur est bien déconnecté
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('⚠️ L\'utilisateur est toujours connecté, nouvelle tentative...');
        await _auth.signOut();
        await Future.delayed(const Duration(milliseconds: 300));
      }

     // print('✅ Déconnexion réussie');
    } catch (e) {
      print('❌ Erreur lors de la déconnexion: $e');
      rethrow;
    }
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
   * 👨‍⚕️ REGISTER PATIENT
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
   * 👤 CREATE USER (Générique)
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
        'uid': firebaseUser.uid,
        'email': email.trim(),
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'role': role.name,
        'profileCompleted': role == UserRole.patient ? false : true,
        'emailVerified': false,
        'profile': profileData ?? {},
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Créer dans users
      await _db.collection('users').doc(firebaseUser.uid).set(userData);

      // Créer dans la collection spécifique
      await _createRoleSpecificData(firebaseUser.uid, role, roleSpecificData);

      // Envoyer l'email de vérification
      await firebaseUser.sendEmailVerification();

      return AppUser(
        id: firebaseUser.uid,
        email: email.trim(),
        fullName: fullName.trim(),
        phone: phone.trim(),
        role: role,
        profileCompleted: role == UserRole.patient ? false : true,
        emailVerified: false,
        createdAt: DateTime.now(),
        profile: profileData,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /* ============================================================
   * 🏗️ CREATE ROLE SPECIFIC DATA
   * ============================================================ */
  Future<void> _createRoleSpecificData(
    String userId,
    UserRole role,
    Map<String, dynamic>? roleSpecificData,
  ) async {
    switch (role) {
      case UserRole.doctor:
        await _db.collection('doctors').doc(userId).set({
          'userId': userId,
          'hasAccount': true,
          'accountStatus': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          ...?roleSpecificData,
        });
        break;

      case UserRole.admin:
        await _db.collection('admins').doc(userId).set({
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          ...?roleSpecificData,
        });
        break;

      case UserRole.patient:
        await _db.collection('patients').doc(userId).set({
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          ...?roleSpecificData,
        });
        break;
    }
  }
}
