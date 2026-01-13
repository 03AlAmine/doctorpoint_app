import 'package:doctorpoint/services/auth_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Attendre un peu pour éviter les problèmes de timing
      await Future.delayed(const Duration(milliseconds: 800));

      // Vérifier l'état d'authentification
      final authManager = AuthManager();
      final isAuthenticated = await authManager.checkAuthState();

      if (isAuthenticated) {
        final user = FirebaseAuth.instance.currentUser;
        
        // Vérifier si l'email est vérifié
        if (user != null && !user.emailVerified) {
          await FirebaseAuth.instance.signOut();
          _redirectToLogin();
          return;
        }

        // Rafraîchir le token
        await authManager.refreshAuthToken();
        
        // Rediriger vers la page principale
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      } else {
        _redirectToLogin();
      }
    } catch (e) {
      print('❌ Erreur initialisation: $e');
      _redirectToLogin();
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() => _initialized = true);
    }
  }

  void _redirectToLogin() {
    if (!mounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            if (!_initialized)
              const Text(
                'Initialisation...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }
}