import 'package:doctorpoint/auth/login_page.dart';
import 'package:doctorpoint/core/providers/auth_provider.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:doctorpoint/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:doctorpoint/core/providers/doctor_provider.dart';
import 'package:doctorpoint/core/providers/specialty_provider.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/presentation/pages/home_page.dart';
import 'package:doctorpoint/presentation/pages/doctor_detail_page.dart';
import 'package:doctorpoint/presentation/pages/all_doctors_page.dart';
import 'package:doctorpoint/presentation/pages/all_specialties_page.dart';
import 'package:doctorpoint/presentation/pages/search_page.dart';
import 'package:doctorpoint/presentation/pages/appointments_page.dart';
import 'package:doctorpoint/presentation/pages/onboarding_page.dart';
import 'package:doctorpoint/presentation/pages/setup_profile_page.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialiser le formatage des dates en français
  await initializeDateFormatting('fr_FR');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()), // Ajouté
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => SpecialtyProvider()),
      ],
      child: MaterialApp(
        title: 'DoctorPoint',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const Root(), // Changé pour Root
        routes: {
          '/home': (context) => const HomePage(userName: '',),
          '/doctor-detail': (context) {
            final doctor =
                ModalRoute.of(context)!.settings.arguments as Doctor?;
            return DoctorDetailPage(doctor: doctor!);
          },
          '/all-doctors': (context) => const AllDoctorsPage(),
          '/all-specialties': (context) => const AllSpecialtiesPage(),
          '/search': (context) => const SearchPage(),
          '/appointments': (context) => const AppointmentsPage(),
          // Routes d'authentification
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/setup-profile': (context) {
            final uid = ModalRoute.of(context)!.settings.arguments as String?;
            return SetupProfileScreen(uid: uid ?? '');
          },
        },
        // Localizations config
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'), // English
          Locale('fr', 'FR'), // French
        ],
        locale: const Locale('fr', 'FR'), // Français par défaut
      ),
    );
  }
}

// Nouvelle classe Root pour gérer l'authentification
class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  @override
  void initState() {
    super.initState();
    // Initialiser l'authentification
    Future.microtask(() {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Afficher un écran de chargement pendant l'initialisation
        if (authProvider.isLoading) {
          return const SplashScreen();
        }

        // Rediriger vers l'écran approprié selon l'état d'authentification
        if (authProvider.user == null) {
          // Pas d'utilisateur connecté
          if (authProvider.isFirstLaunch) {
            return const OnboardingScreen();
          } else {
            return const LoginScreen();
          }
        } else {
          // Utilisateur connecté
          if (authProvider.userProfile == null ||
              authProvider.userProfile!.isProfileIncomplete) {
            // Profil incomplet, rediriger vers la configuration
            return SetupProfileScreen(uid: authProvider.user!.uid);
          } else {
            // Profil complet, aller à l'accueil
            return const HomePage(userName: '',);
          }
        }
      },
    );
  }

  
}
