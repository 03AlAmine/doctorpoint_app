// lib/presentation/pages/auth/login_page.dart
import 'package:doctorpoint/presentation/pages/patient/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/services/auth_manager.dart';
import 'package:doctorpoint/services/auth_service.dart';
import 'package:doctorpoint/data/models/app_user.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:doctorpoint/presentation/pages/doctor/doctor_dashboard.dart';
import 'package:doctorpoint/presentation/pages/admin/admin_dashboard.dart';

class LoginPage extends StatefulWidget {
  final bool showRegisterLink;

  const LoginPage({super.key, this.showRegisterLink = true});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _showPassword = false;
  String _errorMessage = '';
  bool _isResetMode = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      body: Container(
        height: screenHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.backgroundColor,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - MediaQuery.of(context).padding.vertical,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 20 : 40,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      // Header avec logo animé
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.medical_services_rounded,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                _isResetMode ? 'Réinitialisation' : 'Bienvenue',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 36 : 42,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textColor,
                                  letterSpacing: -1.5,
                                  height: 1.1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isResetMode
                                    ? 'Nous allons vous aider à récupérer votre accès'
                                    : 'Connectez-vous pour accéder à votre espace',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Carte de formulaire
                      Expanded(
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.shadowColor.withOpacity(0.1),
                                    blurRadius: 40,
                                    spreadRadius: -10,
                                    offset: const Offset(0, 20),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _isResetMode ? _buildResetForm() : _buildLoginForm(),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Séparateur ou actions
                                  if (!_isResetMode && widget.showRegisterLink)
                                    _buildAuthActions(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Footer
                      if (!_isLoading)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _isResetMode = !_isResetMode;
                                _errorMessage = '';
                              });
                            },
                            child: Text(
                              _isResetMode
                                  ? '← Retour à la connexion'
                                  : 'Mot de passe oublié ?',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
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
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppTheme.dangerColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dangerColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.dangerColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage,
                    style: TextStyle(
                      color: AppTheme.dangerColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Champ email
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Adresse email',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textColor,
              ),
              decoration: InputDecoration(
                hintText: 'exemple@email.com',
                prefixIcon: Container(
                  width: 56,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.email_outlined,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Champ mot de passe
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Mot de passe',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textColor,
              ),
              decoration: InputDecoration(
                hintText: 'Votre mot de passe',
                prefixIcon: Container(
                  width: 56,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: AppTheme.primaryColor,
                  ),
                ),
                suffixIcon: Container(
                  width: 56,
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: AppTheme.greyColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Lien "Se souvenir de moi"
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() => _isResetMode = true);
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
              ),
              child: Text(
                'Se souvenir de moi',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Bouton de connexion
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Se connecter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetForm() {
    return Column(
      children: [
        // Instructions
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: AppTheme.infoColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.infoColor.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.email_rounded,
                  color: AppTheme.infoColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nous vous enverrons un lien de réinitialisation par email',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Champ email pour réinitialisation
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Votre adresse email',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textColor,
              ),
              decoration: InputDecoration(
                hintText: 'exemple@email.com',
                prefixIcon: Container(
                  width: 56,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.email_outlined,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Boutons d'action
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isResetMode = false;
                      _errorMessage = '';
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                  child: Text(
                    'Annuler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Envoyer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.send_rounded, size: 20),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAuthActions() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        // Séparateur
        Row(
          children: [
            Expanded(
              child: Divider(color: AppTheme.borderColor),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ou',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: AppTheme.borderColor),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Lien d'inscription
        if (widget.showRegisterLink)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add_alt_1_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Créer un compte',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Information médecins
        if (!_isResetMode)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.warningColor.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.medical_services_rounded,
                      color: AppTheme.warningColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Médecins',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.warningColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSmallScreen
                              ? 'Utilisez vos identifiants fournis'
                              : 'Utilisez l\'email et le mot de passe fournis par l\'administration',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
      final authManager = AuthManager();
      final user = await authManager.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (user == null) {
        setState(() => _errorMessage = 'Identifiants incorrects');
        return;
      }

      if (!user.emailVerified) {
        final userDoc = await _db.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final role = userDoc.data()?['role'] as String?;

          if (role != 'admin') {
            setState(() => _errorMessage =
                'Veuillez vérifier votre email avant de vous connecter');
            await FirebaseAuth.instance.signOut();
            return;
          }
        } else {
          setState(() => _errorMessage =
              'Profil utilisateur non trouvé. Contactez l\'administrateur.');
          await FirebaseAuth.instance.signOut();
          return;
        }
      }

      final appUser = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

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
          final doctorDoc =
              await _db.collection('doctors').doc(appUser.id).get();
          if (doctorDoc.exists) {
            final doctor = Doctor.fromFirestore(doctorDoc);
            final doctorData = doctorDoc.data()!;
            final accountStatus = doctorData['accountStatus'] ?? 'pending';

            if (accountStatus == 'pending') {
              Navigator.pushReplacementNamed(context, '/');
            } else if (accountStatus == 'active') {
              final roleData =
                  doctorData['roleData'] as Map<String, dynamic>?;
              final verification =
                  roleData?['verification'] as Map<String, dynamic>?;
              final verificationStatus =
                  verification?['status'] ?? 'pending_documents';

              if (!appUser.profileCompleted) {
                Navigator.pushReplacementNamed(
                  context,
                  '/complete-doctor-profile',
                  arguments: appUser.id,
                );
              } else if (verificationStatus == 'pending_documents') {
                Navigator.pushReplacementNamed(
                  context,
                  '/doctor-documents',
                  arguments: appUser.id,
                );
              } else if (verificationStatus == 'completed') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DoctorDashboard(doctor: doctor),
                  ),
                );
              } else {
                Navigator.pushReplacementNamed(context, '/');
              }
            } else {
              Navigator.pushReplacementNamed(context, '/');
            }
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
    } catch (e) {
      setState(() => _errorMessage = _getErrorMessage(e));
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
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Email envoyé à ${_emailController.text}. Vérifiez votre boîte de réception.',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

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

  String _getErrorMessage(Object e) {
    final error = e.toString().toLowerCase();
    
    if (error.contains('user-not-found') || error.contains('wrong-password')) {
      return 'Email ou mot de passe incorrect';
    } else if (error.contains('network-request-failed')) {
      return 'Erreur de connexion. Vérifiez votre internet';
    } else if (error.contains('too-many-requests')) {
      return 'Trop de tentatives. Réessayez plus tard';
    } else if (error.contains('email-not-verified')) {
      return 'Veuillez vérifier votre email avant de vous connecter';
    } else {
      return 'Une erreur est survenue. Veuillez réessayer';
    }
  }
}