import 'package:doctorpoint/auth/admin_login.dart';
import 'package:doctorpoint/auth/doctor_login_page.dart';
import 'package:doctorpoint/presentation/pages/admin/admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctorpoint/services/auth_service.dart';
import 'package:doctorpoint/presentation/pages/home_page.dart';
import 'package:doctorpoint/core/constants/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final AuthService auth = AuthService();

  bool loading = false;
  bool hidePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            /// LOGO
            Image.asset('assets/images/logo.png', height: 90),

            const SizedBox(height: 24),

            const Text(
              'Connexion',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 32),

            /// EMAIL
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Adresse email',
                prefixIcon: Icon(Icons.email),
              ),
            ),

            const SizedBox(height: 16),

            /// PASSWORD
            TextField(
              controller: passCtrl,
              obscureText: hidePassword,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    hidePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => hidePassword = !hidePassword);
                  },
                ),
              ),
            ),

            const SizedBox(height: 32),

            /// BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: loading ? null : _login,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Se connecter'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminLoginScreen(),
                  ),
                );
              },
              child: const Text('Accéder à l\'interface admin'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorLoginPage(),
                  ),
                );
              },
              child: const Text('Accéder à l\'espace médecin'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    setState(() => loading = true);
    try {
      final user = await auth.login(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      final profile = await auth.getUserProfile(user.uid);
      final fullName = profile['fullName'] ?? 'Utilisateur';

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(userName: fullName),
        ),
      );
    } on FirebaseAuthException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identifiants incorrects')),
      );
    }
    setState(() => loading = false);
  }
}
