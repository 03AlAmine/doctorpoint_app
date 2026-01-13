import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/services/auth_service.dart';
import 'package:doctorpoint/data/models/app_user.dart';

enum RegistrationType { patient, doctor }

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specializationController = TextEditingController();
  final _licenseController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _experienceController = TextEditingController();
  final _descriptionController = TextEditingController();

  RegistrationType _type = RegistrationType.patient;

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String _errorMessage = '';

  List<String> _availableSpecialties = [];
  String? _selectedSpecialty;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _loadSpecialties();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _licenseController.dispose();
    _hospitalController.dispose();
    _experienceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialties() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('specialties')
          .orderBy('name')
          .get();
      
      setState(() {
        _availableSpecialties = snapshot.docs
            .map((doc) => doc['name'] as String)
            .toList();
      });
    } catch (e) {
      setState(() {
        _availableSpecialties = [
          'Cardiologie',
          'Dermatologie',
          'Neurologie',
          'Pédiatrie',
          'Dentisterie',
          'Gynécologie',
          'Ophtalmologie',
          'Orthopédie',
          'Psychiatrie',
          'Gastro-entérologie',
          'Endocrinologie',
          'Urologie',
          'ORL',
          'Radiologie',
          'Anesthésiologie'
        ];
      });
    }
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
                      // Header avec logo
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.2),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.medical_services_rounded,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Rejoignez DoctorPoint',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 32 : 36,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textColor,
                                  letterSpacing: -1.0,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Créez votre compte en quelques étapes',
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
                                children: [
                                  // Sélecteur de type
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.lightGrey,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildTypeButton(
                                            type: RegistrationType.patient,
                                            label: 'Patient',
                                            icon: Icons.person_outline_rounded,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildTypeButton(
                                            type: RegistrationType.doctor,
                                            label: 'Médecin',
                                            icon: Icons.medical_services_outlined,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  // Formulaire
                                  Expanded(
                                    child: Form(
                                      key: _formKey,
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            // Message d'erreur
                                            if (_errorMessage.isNotEmpty)
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(16),
                                                margin: const EdgeInsets.only(bottom: 20),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.dangerColor.withOpacity(0.05),
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: AppTheme.dangerColor.withOpacity(0.2),
                                                  ),
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

                                            // Champs communs
                                            _buildTextField(
                                              controller: _nameController,
                                              label: _type == RegistrationType.patient
                                                  ? 'Nom complet *'
                                                  : 'Dr. Nom Prénom *',
                                              icon: Icons.person_outline_rounded,
                                            ),
                                            const SizedBox(height: 20),

                                            _buildTextField(
                                              controller: _emailController,
                                              label: 'Email *',
                                              icon: Icons.email_outlined,
                                              keyboardType: TextInputType.emailAddress,
                                            ),
                                            const SizedBox(height: 20),

                                            _buildTextField(
                                              controller: _phoneController,
                                              label: 'Téléphone *',
                                              icon: Icons.phone_outlined,
                                              keyboardType: TextInputType.phone,
                                            ),

                                            // Champs spécifiques médecin
                                            if (_type == RegistrationType.doctor) ...[
                                              const SizedBox(height: 20),
                                              _buildSpecialtyField(),
                                              const SizedBox(height: 20),
                                              _buildTextField(
                                                controller: _licenseController,
                                                label: 'Numéro de licence/Ordre *',
                                                icon: Icons.badge_outlined,
                                              ),
                                              const SizedBox(height: 20),
                                              _buildTextField(
                                                controller: _hospitalController,
                                                label: 'Hôpital/Clinique',
                                                icon: Icons.local_hospital_outlined,
                                              ),
                                              const SizedBox(height: 20),
                                              _buildTextField(
                                                controller: _experienceController,
                                                label: 'Années d\'expérience',
                                                icon: Icons.work_outline,
                                                keyboardType: TextInputType.number,
                                              ),
                                              const SizedBox(height: 20),
                                              _buildDescriptionField(),
                                            ],

                                            const SizedBox(height: 20),

                                            // Mot de passe
                                            _buildPasswordField(
                                              controller: _passwordController,
                                              label: 'Mot de passe *',
                                              obscureText: !_showPassword,
                                              onToggleVisibility: () {
                                                setState(() {
                                                  _showPassword = !_showPassword;
                                                });
                                              },
                                            ),
                                            const SizedBox(height: 20),

                                            // Confirmation mot de passe
                                            _buildPasswordField(
                                              controller: _confirmPasswordController,
                                              label: 'Confirmer le mot de passe *',
                                              obscureText: !_showConfirmPassword,
                                              onToggleVisibility: () {
                                                setState(() {
                                                  _showConfirmPassword = !_showConfirmPassword;
                                                });
                                              },
                                            ),

                                            // Information importante pour médecins
                                            if (_type == RegistrationType.doctor)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 24, bottom: 20),
                                                child: Container(
                                                  padding: const EdgeInsets.all(20),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.warningColor.withOpacity(0.05),
                                                    borderRadius: BorderRadius.circular(16),
                                                    border: Border.all(
                                                      color: AppTheme.warningColor.withOpacity(0.1),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        width: 32,
                                                        height: 32,
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.warningColor.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Icon(
                                                          Icons.info_outline_rounded,
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
                                                              'Validation requise',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w600,
                                                                color: AppTheme.warningColor,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 8),
                                                            Text(
                                                              'Votre inscription médecin nécessite une validation manuelle. Vous recevrez un email de confirmation une fois votre compte approuvé.',
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                                color: AppTheme.textSecondary,
                                                                height: 1.5,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                            const SizedBox(height: 32),

                                            // Bouton d'inscription
                                            SizedBox(
                                              width: double.infinity,
                                              height: 56,
                                              child: ElevatedButton(
                                                onPressed: _isLoading ? null : _register,
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
                                                          Icon(
                                                            _type == RegistrationType.patient
                                                                ? Icons.person_add_alt_1_rounded
                                                                : Icons.medical_services_rounded,
                                                            size: 20,
                                                            color: Colors.white,
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Text(
                                                            _type == RegistrationType.patient
                                                                ? 'Créer mon compte'
                                                                : 'Demander l\'inscription',
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ),

                                            const SizedBox(height: 24),

                                            // Lien vers la connexion
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Déjà un compte ? ',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pushReplacementNamed(
                                                        context, '/login');
                                                  },
                                                  style: TextButton.styleFrom(
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: Size.zero,
                                                  ),
                                                  child: Text(
                                                    'Se connecter',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppTheme.primaryColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
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

  Widget _buildTypeButton({
    required RegistrationType type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _type == type;
    
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: AnimatedContainer(
        duration: AppTheme.fastAnimationDuration,
        curve: AppTheme.fastOutSlowInCurve,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.shadowColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppTheme.primaryColor : AppTheme.greyColor,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.textColor : AppTheme.greyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textColor,
          ),
          validator: (value) {
            if (label.contains('*') && (value == null || value.isEmpty)) {
              return 'Ce champ est requis';
            }
            if (label.contains('Email') && value != null && value.isNotEmpty) {
              if (!value.contains('@')) {
                return 'Email invalide';
              }
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: label.replaceAll(' *', ''),
            prefixIcon: Container(
              width: 56,
              alignment: Alignment.center,
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialtyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Spécialité *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: _selectedSpecialty,
          decoration: InputDecoration(
            hintText: 'Sélectionner une spécialité',
            prefixIcon: Container(
              width: 56,
              alignment: Alignment.center,
              child: Icon(
                Icons.medical_services_outlined,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          items: _availableSpecialties.map((specialty) {
            return DropdownMenuItem(
              value: specialty,
              child: Text(
                specialty,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textColor,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSpecialty = value;
              if (value != null) {
                _specializationController.text = value;
              }
            });
          },
          validator: (value) {
            if (_type == RegistrationType.doctor && (value == null || value.isEmpty)) {
              return 'Veuillez sélectionner une spécialité';
            }
            return null;
          },
          dropdownColor: Colors.white,
          icon: Icon(Icons.expand_more_rounded, color: AppTheme.greyColor),
          borderRadius: BorderRadius.circular(12),
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Présentation professionnelle',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textColor,
          ),
          decoration: InputDecoration(
            hintText: 'Décrivez votre expérience et spécialités',
            alignLabelWithHint: true,
            prefixIcon: Container(
              width: 56,
              alignment: Alignment.center,
              child: Icon(
                Icons.description_outlined,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textColor,
          ),
          validator: (value) {
            if (label.contains('*') && (value == null || value.isEmpty)) {
              return 'Ce champ est requis';
            }
            if (label.contains('Mot de passe') && value != null && value.isNotEmpty) {
              if (value.length < 6) {
                return 'Minimum 6 caractères';
              }
            }
            if (label.contains('Confirmer') && value != _passwordController.text) {
              return 'Les mots de passe ne correspondent pas';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: label.replaceAll(' *', ''),
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
                  obscureText ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: AppTheme.greyColor,
                ),
                onPressed: onToggleVisibility,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_type == RegistrationType.doctor && 
        (_selectedSpecialty == null || _selectedSpecialty!.isEmpty)) {
      setState(() => _errorMessage = 'Veuillez sélectionner une spécialité');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authService = AuthService();

      if (_type == RegistrationType.patient) {
        final appUser = await authService.createUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          role: UserRole.patient,
        );

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/complete-profile',
            arguments: {
              'userId': appUser.id,
              'email': appUser.email,
            },
          );
        }
      } else if (_type == RegistrationType.doctor) {
        await authService.registerDoctorRequest(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          specialization: _selectedSpecialty!,
          licenseNumber: _licenseController.text.trim(),
          hospital: _hospitalController.text.trim(),
          experience: _experienceController.text.isNotEmpty 
            ? int.parse(_experienceController.text) 
            : 0,
          description: _descriptionController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Demande d\'inscription envoyée avec succès !',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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

          await Future.delayed(const Duration(milliseconds: 1500));
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _handleAuthError(e));
    } catch (e) {
      setState(() => _errorMessage = 'Une erreur est survenue. Veuillez réessayer.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email';
      case 'invalid-email':
        return 'Adresse email invalide';
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      case 'operation-not-allowed':
        return 'L\'inscription par email est temporairement désactivée';
      case 'network-request-failed':
        return 'Erreur réseau. Vérifiez votre connexion internet';
      default:
        return 'Erreur d\'inscription';
    }
  }
}