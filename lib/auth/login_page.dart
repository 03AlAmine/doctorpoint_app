// lib/presentation/pages/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:doctorpoint/services/auth_service.dart';
import 'package:doctorpoint/data/models/app_user.dart';
import 'package:doctorpoint/presentation/pages/home_page.dart';
import 'package:doctorpoint/presentation/pages/doctor/doctor_dashboard.dart';
import 'package:doctorpoint/presentation/pages/admin/admin_dashboard.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  final bool showRegisterLink;
  
  const LoginPage({super.key, this.showRegisterLink = true});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  bool _showPassword = false;
  String _errorMessage = '';
  bool _isResetMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.medical_services,
                    size: 60,
                    color: AppTheme.primaryColor,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Titre
                Text(
                  _isResetMode ? 'Réinitialisation' : 'DoctorPoint',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  _isResetMode 
                    ? 'Entrez votre email pour réinitialiser votre mot de passe'
                    : 'Connectez-vous à votre compte',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Formulaire
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _isResetMode 
                    ? _buildResetForm()
                    : _buildLoginForm(),
                ),
                
                const SizedBox(height: 20),
                
                // Lien pour changer de mode
                if (!_isLoading)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isResetMode = !_isResetMode;
                        _errorMessage = '';
                      });
                    },
                    child: Text(
                      _isResetMode 
                        ? 'Retour à la connexion'
                        : 'Mot de passe oublié ?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // Message d'erreur
        if (_errorMessage.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Email
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Mot de passe
        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Bouton de connexion
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : const Text(
                    'Se connecter',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        
        if (widget.showRegisterLink) ...[
          const SizedBox(height: 20),
          
          // Lien vers l'inscription
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Pas encore de compte ? ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'Créer un compte',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
        
        const SizedBox(height: 20),
        
        // Information pour les médecins
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black),
          ),
          child: Column(
            children: [
              const Text(
                'Médecins',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Utilisez l\'email et le mot de passe fournis par l\'administration',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResetForm() {
    return Column(
      children: [
        const SizedBox(height: 10),
        
        // Instructions
        Text(
          'Nous vous enverrons un email avec un lien pour réinitialiser votre mot de passe.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 24),
        
        // Email pour réinitialisation
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Votre email',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Boutons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isResetMode = false;
                    _errorMessage = '';
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Annuler'),
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : const Text('Envoyer'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final appUser = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Redirection basée sur le rôle
      if (mounted) {
        switch (appUser.role) {
          case UserRole.patient:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(userName: appUser.fullName),
              ),
            );
            break;
            
          case UserRole.doctor:
            // Charger les données complètes du médecin
            final doctorDoc = await _db.collection('doctors').doc(appUser.id).get();
            if (doctorDoc.exists) {
              final doctor = Doctor.fromFirestore(doctorDoc);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DoctorDashboard(doctor: doctor),
                ),
              );
            } else {
              setState(() => _errorMessage = 'Profil médecin introuvable');
            }
            break;
            
          case UserRole.admin:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminDashboard(),
              ),
            );
            break;
        }
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer votre email');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _authService.resetPassword(_emailController.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email envoyé à ${_emailController.text}. Vérifiez votre boîte de réception.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
        
        // Revenir au formulaire de connexion
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          _isResetMode = false;
          _emailController.clear();
        });
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}