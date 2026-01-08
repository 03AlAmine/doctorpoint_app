// lib/presentation/pages/auth/complete_profile_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';

class CompleteProfilePage extends StatefulWidget {
  final String userId;
  final String email;

  const CompleteProfilePage({
    super.key,
    required this.userId,
    required this.email,
  });

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Contrôleurs pour les champs obligatoires
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  
  // Valeurs par défaut
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  String? _selectedBloodGroup;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compléter votre profil'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            const Text(
              'Presque terminé !',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complétez votre profil pour profiter pleinement de DoctorPoint',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            // Indicateur de progression
            _buildProgressIndicator(),
            const SizedBox(height: 32),
            
            // Formulaire
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: Text(_errorMessage),
                    ),
                  
                  // Date de naissance
                  TextFormField(
                    controller: _birthDateController,
                    decoration: const InputDecoration(
                      labelText: 'Date de naissance *',
                      prefixIcon: Icon(Icons.cake),
                      hintText: 'JJ/MM/AAAA',
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedBirthDate = date;
                          _birthDateController.text = DateFormat('dd/MM/yyyy').format(date);
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La date de naissance est requise';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Genre
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Genre *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: ['Homme', 'Femme', 'Autre']
                        .map((gender) => DropdownMenuItem(
                              value: gender,
                              child: Text(gender),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedGender = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner votre genre';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Adresse
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Adresse *',
                      prefixIcon: Icon(Icons.home),
                      hintText: 'Votre adresse complète',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'L\'adresse est requise';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Ville
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Ville *',
                      prefixIcon: Icon(Icons.location_city),
                      hintText: 'Votre ville',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La ville est requise';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Groupe sanguin (optionnel)
                  DropdownButtonFormField<String>(
                    value: _selectedBloodGroup,
                    decoration: const InputDecoration(
                      labelText: 'Groupe sanguin',
                      prefixIcon: Icon(Icons.bloodtype),
                    ),
                    items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Non connu']
                        .map((group) => DropdownMenuItem(
                              value: group,
                              child: Text(group),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedBloodGroup = value);
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Information
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ces informations sont essentielles pour vos rendez-vous médicaux. Vous pourrez les modifier plus tard.',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Passer pour plus tard
                            _skipForNow();
                          },
                          child: const Text('Compléter plus tard'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _completeProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Terminer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: 0.5,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
        const SizedBox(height: 8),
        const Text(
          'Étape 2 sur 2',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Mettre à jour les deux collections
      final updates = {
        'gender': _selectedGender,
        'birthDate': _selectedBirthDate != null
            ? Timestamp.fromDate(_selectedBirthDate!)
            : null,
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'bloodGroup': _selectedBloodGroup,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Mettre à jour dans users
      await _db.collection('users').doc(widget.userId).update(updates);
      
      // Mettre à jour dans patients
      await _db.collection('patients').doc(widget.userId).update(updates);

      // Rediriger vers l'accueil
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }

    } catch (e) {
      setState(() => _errorMessage = 'Erreur: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _skipForNow() async {
    // Marquer que l'utilisateur a sauté l'étape
    await _db.collection('users').doc(widget.userId).update({
      'profileCompleted': false,
      'hasSkippedProfile': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Rediriger vers l'accueil
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }
}