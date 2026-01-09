// lib/main.dart
import 'package:doctorpoint/presentation/pages/admin/admin_doctor_requests.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';

//seed
//import 'package:doctorpoint/utils/seed.dart';

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
import 'package:doctorpoint/auth/register_page.dart';
import 'package:doctorpoint/auth/complete_profile_page.dart';

// Pages Patient
import 'package:doctorpoint/presentation/pages/home_page.dart';
import 'package:doctorpoint/presentation/pages/doctor_detail_page.dart';
import 'package:doctorpoint/presentation/pages/all_doctors_page.dart';
import 'package:doctorpoint/presentation/pages/all_specialties_page.dart';
import 'package:doctorpoint/presentation/pages/search_page.dart';
import 'package:doctorpoint/presentation/pages/appointments_page.dart';
import 'package:doctorpoint/presentation/pages/onboarding_page.dart';
import 'package:doctorpoint/presentation/pages/splash_page.dart';
import 'package:doctorpoint/presentation/pages/profile/patient_profile_page.dart';

// Pages Doctor
import 'package:doctorpoint/presentation/pages/doctor/doctor_dashboard.dart';

// Pages Admin
import 'package:doctorpoint/presentation/pages/admin/admin_dashboard.dart';
import 'package:doctorpoint/presentation/pages/admin/admin_doctors_page.dart';
import 'package:doctorpoint/presentation/pages/admin/admin_doctor_form.dart';

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
  // await runSeed();

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
        routes: {
          '/': (context) => const Root(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/complete-profile': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>?;
            return CompleteProfilePage(
              userId: args?['userId'] ?? '',
              email: args?['email'] ?? '',
            );
          },
          '/home': (context) => const HomePage(userName: ''),
          '/doctor-detail': (context) {
            final doctor =
                ModalRoute.of(context)!.settings.arguments as Doctor?;
            return DoctorDetailPage(doctor: doctor!);
          },
          '/all-doctors': (context) => const AllDoctorsPage(),
          '/all-specialties': (context) => const AllSpecialtiesPage(),
          '/search': (context) => const SearchPage(),
          '/appointments': (context) => const AppointmentsPage(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/admin': (context) => const AdminDashboard(),
          '/admin/doctors': (context) => const AdminDoctorsPage(),
          '/admin/doctor-form': (context) => const AdminDoctorForm(),
          '/admin/doctor-requests': (context) =>
              const AdminDoctorRequestsPage(), // AJOUTEZ CETTE LIGNE
          '/doctor-dashboard': (context) {
            final doctor =
                ModalRoute.of(context)!.settings.arguments as Doctor?;
            return DoctorDashboard(doctor: doctor!);
          },
          '/patient-profile': (context) => const PatientProfilePage(),
        },
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

        // Vérifier si le profil est complet
        return FutureBuilder<DocumentSnapshot>(
          future: _db.collection('users').doc(userId).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              firebase_auth.FirebaseAuth.instance.signOut();
              return const LoginPage();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final profileCompleted = userData['profileCompleted'] ?? false;
            final role = userData['role'] ?? 'patient';

            // Si patient et profil incomplet, rediriger vers complétion
            if (role == 'patient' && !profileCompleted) {
              final hasSkipped = userData['hasSkippedProfile'] ?? false;

              // Si l'utilisateur a déjà sauté, on le laisse passer
              if (hasSkipped) {
                return FutureBuilder<AppUser?>(
                  future: _authService.getCurrentUser(),
                  builder: (context, appUserSnapshot) {
                    return _handleUserRole(appUserSnapshot);
                  },
                );
              }

              // Sinon, rediriger vers complétion du profil
              return CompleteProfilePage(
                userId: userId,
                email: userData['email'] ?? '',
              );
            }

            // Profil complet ou non-patient → continuer normalement
            return FutureBuilder<AppUser?>(
              future: _authService.getCurrentUser(),
              builder: (context, appUserSnapshot) {
                return _handleUserRole(appUserSnapshot);
              },
            );
          },
        );
      },
    );
  }

// Dans _RootState de main.dart, modifiez cette partie :
  Widget _handleUserRole(AsyncSnapshot<AppUser?> appUserSnapshot) {
    if (appUserSnapshot.connectionState == ConnectionState.waiting) {
      return const SplashScreen();
    }

    final appUser = appUserSnapshot.data;

    if (appUser == null) {
      firebase_auth.FirebaseAuth.instance.signOut();
      return const LoginPage();
    }

    // VÉRIFICATION SPÉCIALE POUR PATIENT AVEC PROFIL INCOMPLET
    if (appUser.isPatient && !appUser.profileCompleted) {
      // Aller directement à la page de complétion
      return CompleteProfilePage(
        userId: appUser.id,
        email: appUser.email,
      );
    }

    switch (appUser.role) {
      case UserRole.patient:
        return HomePage(userName: appUser.fullName);

      case UserRole.doctor:
        return FutureBuilder<Doctor?>(
          future: _getDoctorData(appUser.id),
          builder: (context, doctorSnapshot) {
            if (doctorSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            final doctor = doctorSnapshot.data;
            return doctor != null
                ? DoctorDashboard(doctor: doctor)
                : const LoginPage();
          },
        );

      case UserRole.admin:
        return const AdminDashboard();
    }
  }

  Future<Doctor?> _getDoctorData(String doctorId) async {
    try {
      final doc = await _db.collection('doctors').doc(doctorId).get();
      return doc.exists ? Doctor.fromFirestore(doc) : null;
    } catch (e) {
      print('Erreur chargement docteur: $e');
      return null;
    }
  }
}
