import 'package:doctorpoint/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:doctorpoint/presentation/pages/onboarding_page.dart';
import 'package:doctorpoint/presentation/pages/setup_profile_page.dart';
import 'package:doctorpoint/presentation/pages/home_page.dart';
import 'package:doctorpoint/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    final user = FirebaseAuth.instance.currentUser;

    switch (result) {
      case 'onboarding':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
        break;

      case 'setup':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SetupProfileScreen(uid: user!.uid),
          ),
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
          MaterialPageRoute(builder: (_) => const LoginScreen()),
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
