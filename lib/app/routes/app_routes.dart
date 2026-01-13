// lib/core/routes/routes.dart
import 'package:flutter/material.dart';

// Pages Auth
import 'package:doctorpoint/auth/login_page.dart';
import 'package:doctorpoint/auth/register_page.dart';
import 'package:doctorpoint/auth/complete_profile_page.dart';

// Pages Patient
import 'package:doctorpoint/presentation/pages/patient/home_page.dart';
import 'package:doctorpoint/presentation/pages/patient/doctor_detail_page.dart';
import 'package:doctorpoint/presentation/pages/patient/all_doctors_page.dart';
import 'package:doctorpoint/presentation/pages/patient/all_specialties_page.dart';
import 'package:doctorpoint/presentation/pages/patient/search_page.dart';
import 'package:doctorpoint/presentation/pages/patient/appointments_page.dart';
import 'package:doctorpoint/presentation/pages/onboarding_page.dart';
import 'package:doctorpoint/presentation/pages/splash_page.dart';
import 'package:doctorpoint/presentation/pages/profile/patient_profile_page.dart';

// Pages Doctor
import 'package:doctorpoint/presentation/pages/doctor/doctor_dashboard.dart';
import 'package:doctorpoint/presentation/pages/doctor/doctor_documents_page.dart';
import 'package:doctorpoint/presentation/pages/doctor/complete_doctor_profile.dart';

// Pages Admin
import 'package:doctorpoint/presentation/pages/admin/admin_dashboard.dart';
import 'package:doctorpoint/presentation/pages/admin/admin_doctors_page.dart';
import 'package:doctorpoint/presentation/pages/admin/admin_doctor_form.dart';
import 'package:doctorpoint/presentation/pages/admin/admin_doctor_requests.dart';
import 'package:doctorpoint/presentation/pages/admin/admin_patients_page.dart'; // NOUVEAU

// Models
import 'package:doctorpoint/data/models/doctor_model.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/': (context) => const LoginPage(),
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
        final doctor = ModalRoute.of(context)!.settings.arguments as Doctor?;
        return DoctorDetailPage(doctor: doctor!);
      },
      '/all-doctors': (context) => const AllDoctorsPage(),
      '/all-specialties': (context) => const AllSpecialtiesPage(),
      '/search': (context) => const SearchPage(),
      '/appointments': (context) => const AppointmentsPage(),
      '/onboarding': (context) => const OnboardingScreen(),
      
      // Routes Admin
      '/admin': (context) => const AdminDashboard(),
      '/admin/doctors': (context) => const AdminDoctorsPage(),
      '/admin/doctor-form': (context) => const AdminDoctorForm(),
      '/admin/doctor-requests': (context) => const AdminDoctorRequestsPage(),
      '/admin/patients': (context) => const AdminPatientsPage(), // NOUVEAU
      
      // Routes Doctor
      '/doctor-dashboard': (context) {
        final doctor = ModalRoute.of(context)!.settings.arguments as Doctor?;
        return DoctorDashboard(doctor: doctor!);
      },
      
      // Routes Patient
      '/patient-profile': (context) => const PatientProfilePage(),
      
      '/doctor-documents': (context) {
        final doctorId = ModalRoute.of(context)!.settings.arguments as String;
        return DoctorDocumentsPage(doctorId: doctorId);
      },
      
      '/complete-doctor-profile': (context) {
        final doctorId = ModalRoute.of(context)!.settings.arguments as String;
        return CompleteDoctorProfilePage(doctorId: doctorId);
      },
      
      '/splash': (context) => const SplashScreen(),
    };
  }

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    final routes = getRoutes();
    
    if (routes.containsKey(settings.name)) {
      return MaterialPageRoute(
        builder: routes[settings.name]!,
        settings: settings,
      );
    }
    
    // Route par défaut
    return MaterialPageRoute(
      builder: (context) => const LoginPage(),
    );
  }
}