import 'package:doctorpoint/data/models/doctor_model.dart';
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
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => SpecialtyProvider()),
      ],
      child: MaterialApp(
        title: 'DoctorPoint',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/doctor-detail': (context) {
            final doctor = ModalRoute.of(context)!.settings.arguments as Doctor?;
            return DoctorDetailPage(doctor: doctor!);
          },
          '/all-doctors': (context) => const AllDoctorsPage(),
          '/all-specialties': (context) => const AllSpecialtiesPage(),
          '/search': (context) => const SearchPage(),
          '/appointments': (context) => const AppointmentsPage(),
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}




class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Liste des pages
  final List<Widget> _pages = [
    const HomePage(),
    const AppointmentsPage(), // Ajouté
    Container(color: Colors.white, child: const Center(child: Text('Messages'))),
    Container(color: Colors.white, child: const Center(child: Text('Profil'))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.greyColor,
        selectedLabelStyle: TextStyle(
          fontSize: isSmallScreen ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: isSmallScreen ? 10 : 12,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 8,
        iconSize: isSmallScreen ? 20 : 24,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_outlined,
              size: isSmallScreen ? 20 : 24,
            ),
            activeIcon: Icon(
              Icons.home,
              size: isSmallScreen ? 20 : 24,
            ),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.calendar_today_outlined,
              size: isSmallScreen ? 20 : 24,
            ),
            activeIcon: Icon(
              Icons.calendar_today,
              size: isSmallScreen ? 20 : 24,
            ),
            label: 'Rendez-vous',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: const Text('3'),
              backgroundColor: Colors.red,
              child: Icon(
                Icons.chat_bubble_outline,
                size: isSmallScreen ? 20 : 24,
              ),
            ),
            activeIcon: Badge(
              label: const Text('3'),
              backgroundColor: Colors.red,
              child: Icon(
                Icons.chat_bubble,
                size: isSmallScreen ? 20 : 24,
              ),
            ),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_outline,
              size: isSmallScreen ? 20 : 24,
            ),
            activeIcon: Icon(
              Icons.person,
              size: isSmallScreen ? 20 : 24,
            ),
            label: 'Profil',
          ),
        ],
        onTap: _onItemTapped,
      ),
    );
  }
}
