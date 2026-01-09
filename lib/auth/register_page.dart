// lib/presentation/pages/auth/register_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctorpoint/auth/complete_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';

enum RegistrationType { patient, doctor }

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specializationController = TextEditingController();
  final _licenseController = TextEditingController();

  RegistrationType _type = RegistrationType.patient;

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String _errorMessage = '';

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
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.medical_services,
                    size: 50,
                    color: AppTheme.primaryColor,
                  ),
                ),

                const SizedBox(height: 30),

                // Titre
                const Text(
                  'Créer un compte',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Rejoignez DoctorPoint',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
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
                                Icon(Icons.error,
                                    color: Colors.red.shade700, size: 20),
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

                        // Sélecteur de type
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SegmentedButton<RegistrationType>(
                              segments: const [
                                ButtonSegment<RegistrationType>(
                                  value: RegistrationType.patient,
                                  label: Text('Patient'),
                                  icon: Icon(Icons.person),
                                ),
                                ButtonSegment<RegistrationType>(
                                  value: RegistrationType.doctor,
                                  label: Text('Médecin'),
                                  icon: Icon(Icons.medical_services),
                                ),
                              ],
                              selected: {_type},
                              onSelectionChanged:
                                  (Set<RegistrationType> newSelection) {
                                setState(() => _type = newSelection.first);
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Nom
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: _type == RegistrationType.patient
                                ? 'Nom complet *'
                                : 'Dr. Nom Prénom *',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ce champ est requis';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email *',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'L\'email est requis';
                            }
                            if (!value.contains('@')) {
                              return 'Email invalide';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Téléphone
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Téléphone *',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Le téléphone est requis';
                            }
                            return null;
                          },
                        ),

                        // Champs spécifiques médecin
                        if (_type == RegistrationType.doctor) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _specializationController,
                            decoration: InputDecoration(
                              labelText: 'Spécialisation *',
                              prefixIcon: const Icon(Icons.medical_services),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'La spécialisation est requise';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _licenseController,
                            decoration: InputDecoration(
                              labelText: 'Numéro de licence *',
                              prefixIcon: const Icon(Icons.badge),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Le numéro de licence est requis';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Mot de passe
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe *',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Le mot de passe est requis';
                            }
                            if (value.length < 6) {
                              return 'Minimum 6 caractères';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Confirmation mot de passe
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_showConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirmer le mot de passe *',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showConfirmPassword = !_showConfirmPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez confirmer le mot de passe';
                            }
                            if (value != _passwordController.text) {
                              return 'Les mots de passe ne correspondent pas';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Information pour les médecins
                        if (_type == RegistrationType.doctor)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  '⚠️ Information importante',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Les inscriptions médecins nécessitent une validation manuelle par l\'administration. Vous recevrez un email une fois votre compte activé.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber[800],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                        // Bouton d'inscription
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
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
                                : Text(
                                    _type == RegistrationType.patient
                                        ? 'Créer mon compte patient'
                                        : 'Demander l\'inscription médecin',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Lien vers la connexion
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Déjà un compte ? ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
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
                              child: const Text(
                                'Se connecter',
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

// Dans votre méthode _register() pour les patients
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_type == RegistrationType.patient) {
        // Créer l'utilisateur Firebase Auth pour patient
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        final userId = userCredential.user!.uid;
        final email = _emailController.text.trim();
        final fullName = _nameController.text.trim();
        final phone = _phoneController.text.trim();

        // Créer le document utilisateur dans Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'uid': userId,
          'email': email,
          'fullName': fullName,
          'phone': phone,
          'role': 'patient',
          'profileCompleted': false,
          'emailVerified': false,
          'hasSkippedProfile': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Créer aussi dans la collection patients
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(userId)
            .set({
          'uid': userId,
          'email': email,
          'fullName': fullName,
          'phone': phone,
          'role': 'patient',
          'profileCompleted': false,
          'emailVerified': false,
          'hasSkippedProfile': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Envoyer l'email de vérification
        await userCredential.user!.sendEmailVerification();

        // Rediriger vers la page de complétion du profil
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CompleteProfilePage(
                userId: userId,
                email: email,
              ),
            ),
          );
        }
      } else if (_type == RegistrationType.doctor) {
        // Pour les médecins, créer une demande d'inscription
        await _registerDoctorRequest();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _handleAuthError(e));
    } catch (e) {
      setState(() => _errorMessage = 'Erreur: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _registerDoctorRequest() async {
    // NE PAS créer l'utilisateur Firebase Auth immédiatement
    // Juste enregistrer la demande dans doctor_requests
    final requestData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'specialization': _specializationController.text.trim(),
      'licenseNumber': _licenseController.text.trim(),
      'status': 'pending', // pending, approved, rejected
      'requestDate': FieldValue.serverTimestamp(),
      'password':
          _passwordController.text, // À garder pour créer le compte plus tard
      'additionalInfo': {
        'requestType': 'doctor_registration',
        'source': 'app_registration',
      },
    };

    try {
      // Enregistrer la demande dans doctor_requests
      await FirebaseFirestore.instance
          .collection('doctor_requests')
          .add(requestData);

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Demande d\'inscription envoyée ! L\'administration vous contactera pour finaliser votre inscription.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );

        // Revenir à la page de connexion
        await Future.delayed(const Duration(milliseconds: 1500));
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      setState(
          () => _errorMessage = 'Erreur lors de l\'envoi de la demande: $e');
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
        return 'L\'inscription par email est désactivée';
      default:
        return 'Erreur d\'inscription: ${e.message}';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _licenseController.dispose();
    super.dispose();
  }
}
