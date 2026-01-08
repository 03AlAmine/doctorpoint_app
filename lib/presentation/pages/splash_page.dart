import 'package:doctorpoint/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:doctorpoint/presentation/pages/onboarding_page.dart';
import 'package:doctorpoint/presentation/pages/home_page.dart';
import 'package:doctorpoint/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService auth = AuthService();

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(seconds: 2));

    final result = await auth.handleStart();

    if (!mounted) return;


    switch (result) {
      case 'onboarding':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
        break;

      case 'home':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const HomePage(
                    userName: '',
                  )),
        );
        break;

      default:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
