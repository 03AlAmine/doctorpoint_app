import 'package:flutter/material.dart';
import 'package:doctorpoint/presentation/pages/home_page.dart';
import 'package:doctorpoint/presentation/pages/appointments_page.dart';
import 'package:doctorpoint/presentation/pages/doctor_detail_page.dart';
import 'package:doctorpoint/presentation/pages/all_doctors_page.dart';
import 'package:doctorpoint/presentation/pages/all_specialties_page.dart';
import 'package:doctorpoint/presentation/pages/search_page.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
class AppRoutes {
  // Routes names
  static const String home = '/';
  static const String appointments = '/appointments';
  static const String doctorDetail = '/doctor-detail';
  static const String allDoctors = '/all-doctors';
  static const String allSpecialties = '/all-specialties';
  static const String search = '/search';
  static const String booking = '/booking';
  static const String profile = '/profile';
  static const String messages = '/messages';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String login = '/login';
  static const String register = '/register';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage(userName: '',));
      
      case appointments:
        return MaterialPageRoute(builder: (_) => const AppointmentsPage());
      
      case doctorDetail:
        final Doctor doctor = settings.arguments as Doctor;
        return MaterialPageRoute(
          builder: (_) => DoctorDetailPage(doctor: doctor),
        );
      
      case allDoctors:
        return MaterialPageRoute(builder: (_) => const AllDoctorsPage());
      
      case allSpecialties:
        return MaterialPageRoute(builder: (_) => const AllSpecialtiesPage());
      
      case search:
        return MaterialPageRoute(builder: (_) => const SearchPage());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
