// lib/main.dart - Code complet corrigé
import 'package:doctorpoint/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';

// Services
import 'package:doctorpoint/services/auth_service.dart';

// Models
import 'package:doctorpoint/data/models/app_user.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';

// Providers
import 'package:doctorpoint/core/providers/auth_provider.dart'
    as app_auth_provider;
import 'package:doctorpoint/core/providers/doctor_provider.dart';
import 'package:doctorpoint/core/providers/specialty_provider.dart';

// Pages Auth
import 'package:doctorpoint/auth/login_page.dart';
import 'package:doctorpoint/auth/complete_profile_page.dart';

// Pages Patient
import 'package:doctorpoint/presentation/pages/patient/home_page.dart';
import 'package:doctorpoint/presentation/pages/splash_page.dart';

// Pages Doctor
import 'package:doctorpoint/presentation/pages/doctor/doctor_dashboard.dart';
import 'package:doctorpoint/presentation/pages/doctor/doctor_documents_page.dart';
import 'package:doctorpoint/presentation/pages/doctor/complete_doctor_profile.dart';

// Pages Admin
import 'package:doctorpoint/presentation/pages/admin/admin_dashboard.dart';

// Theme
import 'package:doctorpoint/core/theme/app_theme.dart';

// Firebase
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialiser le formatage des dates
  await initializeDateFormatting('fr_FR');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth_provider.AuthProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => SpecialtyProvider()),
      ],
      child: MaterialApp(
        title: 'DoctorPoint',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        onGenerateRoute: AppRoutes.generateRoute,
        // Ou utilisez directement les routes :
        // routes: AppRoutes.getRoutes(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('fr', 'FR'),
        ],
        locale: const Locale('fr', 'FR'),
      ),
    );
  }
}

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  bool _isCheckingAuth = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<firebase_auth.User?>(
      stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // Pas d'utilisateur connecté → Page de connexion
        if (authSnapshot.data == null) {
          return const LoginPage();
        }

        final userId = authSnapshot.data!.uid;

        // Ajouter un délai pour éviter les conflits
        if (_isCheckingAuth) {
          return const SplashScreen();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: _getUserDataWithRetry(userId),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            if (userSnapshot.hasError) {
              // En cas d'erreur, déconnecter et rediriger
              _forceLogout();
              return const LoginPage();
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              _forceLogout();
              return const LoginPage();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final profileCompleted = userData['profileCompleted'] ?? false;
            final role = userData['role'] ?? 'patient';

            // Si patient et profil incomplet
            if (role == 'patient' && !profileCompleted) {
              final hasSkipped = userData['hasSkippedProfile'] ?? false;

              if (hasSkipped) {
                return FutureBuilder<AppUser?>(
                  future: _getCurrentUserWithRetry(),
                  builder: (context, appUserSnapshot) {
                    return _handleUserRole(appUserSnapshot);
                  },
                );
              }

              return CompleteProfilePage(
                userId: userId,
                email: userData['email'] ?? '',
              );
            }

            return FutureBuilder<AppUser?>(
              future: _getCurrentUserWithRetry(),
              builder: (context, appUserSnapshot) {
                return _handleUserRole(appUserSnapshot);
              },
            );
          },
        );
      },
    );
  }

  /* ============================================================
   * 🔄 MÉTHODES AVEC REPRISE SUR ERREUR
   * ============================================================ */
  Future<DocumentSnapshot> _getUserDataWithRetry(String userId,
      {int retryCount = 0}) async {
    try {
      setState(() => _isCheckingAuth = true);
      final snapshot = await _db.collection('users').doc(userId).get();
      setState(() => _isCheckingAuth = false);
      return snapshot;
    } catch (e) {
      if (retryCount < 2) {
        await Future.delayed(const Duration(milliseconds: 500));
        return _getUserDataWithRetry(userId, retryCount: retryCount + 1);
      }
      setState(() => _isCheckingAuth = false);
      rethrow;
    }
  }

  Future<AppUser?> _getCurrentUserWithRetry({int retryCount = 0}) async {
    try {
      setState(() => _isCheckingAuth = true);
      final user = await _authService.getCurrentUser();
      setState(() => _isCheckingAuth = false);
      return user;
    } catch (e) {
      if (retryCount < 2) {
        await Future.delayed(const Duration(milliseconds: 500));
        return _getCurrentUserWithRetry(retryCount: retryCount + 1);
      }
      setState(() => _isCheckingAuth = false);
      return null;
    }
  }

  /* ============================================================
   * 🚪 DÉCONNEXION FORCÉE
   * ============================================================ */
  Future<void> _forceLogout() async {
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
      // Nettoyer le cache
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      print('Erreur déconnexion forcée: $e');
    }
  }

  /* ============================================================
   * 👤 GESTION DES RÔLES (LOGIQUE CORRIGÉE)
   * ============================================================ */
  Widget _handleUserRole(AsyncSnapshot<AppUser?> appUserSnapshot) {
    if (appUserSnapshot.connectionState == ConnectionState.waiting) {
      return const SplashScreen();
    }

    final appUser = appUserSnapshot.data;

    if (appUser == null) {
      // Si pas d'utilisateur, déconnecter et retourner au login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _forceLogout();
      });
      return const SplashScreen();
    }

    print('✅ Utilisateur connecté: ${appUser.role.name} - ${appUser.email}');

    switch (appUser.role) {
      case UserRole.patient:
        if (!appUser.profileCompleted) {
          return CompleteProfilePage(
            userId: appUser.id,
            email: appUser.email,
          );
        }
        return HomePage(userName: appUser.fullName);

      case UserRole.doctor:
        return FutureBuilder<DocumentSnapshot>(
          future: _db.collection('doctors').doc(appUser.id).get(),
          builder: (context, doctorSnapshot) {
            if (doctorSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            if (!doctorSnapshot.hasData || !doctorSnapshot.data!.exists) {
              // Docteur non trouvé, déconnecter
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _forceLogout();
              });
              return const SplashScreen();
            }

            final doctorData =
                doctorSnapshot.data!.data() as Map<String, dynamic>;
            final doctor = Doctor.fromFirestore(doctorSnapshot.data!);
            final accountStatus = doctorData['accountStatus'] ?? 'pending';

            // LOGIQUE CORRIGÉE POUR LES MÉDECINS
            if (accountStatus == 'pending') {
              return _buildPendingApprovalScreen();
            } else if (accountStatus == 'active') {
              final roleData = doctorData['roleData'] as Map<String, dynamic>?;
              final verification =
                  roleData?['verification'] as Map<String, dynamic>?;
              final verificationStatus =
                  verification?['status'] ?? 'pending_documents';

              if (!appUser.profileCompleted) {
                // REDIRECTION VERS COMPLÉTION DU PROFIL
                return CompleteDoctorProfilePage(doctorId: appUser.id);
              } else if (verificationStatus == 'pending_documents') {
                // REDIRECTION VERS UPLOAD DES DOCUMENTS
                return DoctorDocumentsPage(doctorId: appUser.id);
              } else if (verificationStatus == 'under_review') {
                return _buildUnderReviewScreen();
              } else if (verificationStatus == 'completed') {
                return DoctorDashboard(doctor: doctor);
              }
            } else if (accountStatus == 'rejected') {
              return _buildRejectedScreen(doctorData);
            }

            return const LoginPage(showRegisterLink: true);
          },
        );

      case UserRole.admin:
        return const AdminDashboard();
    }
  }

  /* ============================================================
   * 🕐 ÉCRANS D'ATTENTE POUR MÉDECINS
   * ============================================================ */

  Widget _buildPendingApprovalScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pending_actions,
                size: 100,
                color: Colors.orange,
              ),
              const SizedBox(height: 30),
              const Text(
                'En attente d\'approbation',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Votre demande d\'inscription est en cours de traitement par notre équipe administrative.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Vous recevrez un email dès que votre compte sera activé.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  firebase_auth.FirebaseAuth.instance.signOut();
                },
                child: const Text('Déconnexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnderReviewScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_empty,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 30),
              const Text(
                'Documents en vérification',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Vos documents sont actuellement en cours de vérification par notre équipe.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Cette étape prend généralement 24 à 48 heures.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  firebase_auth.FirebaseAuth.instance.signOut();
                },
                child: const Text('Déconnexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRejectedScreen(Map<String, dynamic> doctorData) {
    final roleData = doctorData['roleData'] as Map<String, dynamic>?;
    final verification = roleData?['verification'] as Map<String, dynamic>?;
    final rejectReason = verification?['rejectReason'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cancel,
                size: 100,
                color: Colors.red,
              ),
              const SizedBox(height: 30),
              const Text(
                'Compte rejeté',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (rejectReason.isNotEmpty)
                Text(
                  'Raison: $rejectReason',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 8),
              const Text(
                'Votre demande d\'inscription a été rejetée.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  firebase_auth.FirebaseAuth.instance.signOut();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Retour à la connexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* ============================================================
   * 🔍 RÉCUPÉRATION DONNÉES MÉDECIN
   * ============================================================ 
  Future<Doctor?> _getDoctorData(String doctorId) async {
    try {
      final doc = await _db.collection('doctors').doc(doctorId).get();

      if (!doc.exists) {
        return null;
      }

      return Doctor.fromFirestore(doc);
    } catch (e) {
      print('❌ Erreur chargement docteur: $e');
      return null;
    }
  }*/
}
