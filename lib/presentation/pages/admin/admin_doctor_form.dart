import 'dart:io';
import 'package:doctorpoint/core/providers/doctor_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class AdminDoctorForm extends StatefulWidget {
  final Doctor? doctor;
  final Map<String, dynamic>? requestData; // Données de la demande d'inscription

  const AdminDoctorForm({
    super.key, 
    this.doctor,
    this.requestData,
  });

  @override
  State<AdminDoctorForm> createState() => _AdminDoctorFormState();
}

class _AdminDoctorFormState extends State<AdminDoctorForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController(text: '4.5');
  final TextEditingController _reviewsController = TextEditingController(text: '0');
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _consultationFeeController = TextEditingController(text: '80.00');
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();

  String _selectedImage = '';
  XFile? _pickedImage;
  bool _isLoading = false;
  bool _createAccount = false;
  bool _showPassword = false;

  List<String> _selectedLanguages = ['Français'];
  final List<String> _availableLanguages = [
    'Français',
    'Anglais',
    'Espagnol',
    'Chinois',
    'Arabe',
    'Allemand',
    'Italien',
    'Portugais'
  ];

  Map<String, List<String>> _availability = {
    'Lundi': ['09:00', '17:00'],
    'Mardi': ['09:00', '17:00'],
    'Mercredi': ['09:00', '17:00'],
    'Jeudi': ['09:00', '17:00'],
    'Vendredi': ['09:00', '17:00'],
    'Samedi': ['Fermé'],
    'Dimanche': ['Fermé'],
  };

  List<String> _availableSpecialties = [];
  String? _selectedSpecialty;

  @override
  void initState() {
    super.initState();
    _loadSpecialties();
    
    // Si on modifie un médecin existant, pré-remplir les champs
    if (widget.doctor != null) {
      _nameController.text = widget.doctor!.name;
      _specializationController.text = widget.doctor!.specialization;
      _selectedSpecialty = widget.doctor!.specialization;
      _hospitalController.text = widget.doctor!.hospital;
      _departmentController.text = widget.doctor!.department ?? '';
      _ratingController.text = widget.doctor!.rating.toString();
      _reviewsController.text = widget.doctor!.reviews.toString();
      _experienceController.text = widget.doctor!.experience.toString();
      _consultationFeeController.text = widget.doctor!.consultationFee.toString();
      _descriptionController.text = widget.doctor!.description ?? '';
      _phoneController.text = widget.doctor!.phoneNumber ?? '';
      _emailController.text = widget.doctor!.email ?? '';
      _licenseController.text = widget.doctor!.roleData?['licenseNumber'] ?? '';
      _selectedImage = widget.doctor!.imageUrl;
      _selectedLanguages = widget.doctor!.languages;
      _createAccount = widget.doctor!.hasAccount ?? false;

      if (widget.doctor!.availability != null) {
        _availability = Map<String, List<String>>.from(widget.doctor!.availability!);
      }
    }
    // Si on vient d'une demande d'inscription, pré-remplir avec ces données
    else if (widget.requestData != null) {
      final requestData = widget.requestData!;
      _nameController.text = requestData['name'] ?? '';
      _emailController.text = requestData['email'] ?? '';
      _phoneController.text = requestData['phone'] ?? '';
      _specializationController.text = requestData['specialization'] ?? '';
      _selectedSpecialty = requestData['specialization'] ?? '';
      _licenseController.text = requestData['licenseNumber'] ?? '';
      _experienceController.text = '0'; // Par défaut pour les nouveaux
      _createAccount = true; // Auto-cocher la création de compte pour les demandes
      if (requestData['password'] != null) {
        _passwordController.text = requestData['password']!;
        _confirmPasswordController.text = requestData['password']!;
      }
    }
  }

  Future<void> _loadSpecialties() async {
    try {
      // Charger les spécialités depuis Firebase
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
      print('Erreur chargement spécialités: $e');
      // Fallback avec des spécialités par défaut
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
  void dispose() {
    _nameController.dispose();
    _specializationController.dispose();
    _hospitalController.dispose();
    _departmentController.dispose();
    _ratingController.dispose();
    _reviewsController.dispose();
    _experienceController.dispose();
    _consultationFeeController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = pickedFile;
        _selectedImage = '';
      });
    }
  }

  void _showAvailabilityDialog(String day) {
    final currentTimes = _availability[day] ?? ['09:00', '17:00'];
    bool isClosed = currentTimes[0] == 'Fermé';

    TimeOfDay? startTime;
    TimeOfDay? endTime;

    if (!isClosed) {
      final startParts = currentTimes[0].split(':');
      final endParts = currentTimes[1].split(':');
      startTime = TimeOfDay(
          hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
      endTime = TimeOfDay(
          hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Horaires du $day'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Fermé'),
                    value: isClosed,
                    onChanged: (value) {
                      setState(() {
                        isClosed = value;
                      });
                    },
                  ),
                  if (!isClosed) ...[
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Heure d\'ouverture'),
                      subtitle: Text(startTime != null
                          ? startTime!.format(context)
                          : 'Sélectionner'),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime:
                              startTime ?? const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (time != null) {
                          setState(() {
                            startTime = time;
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('Heure de fermeture'),
                      subtitle: Text(endTime != null
                          ? endTime!.format(context)
                          : 'Sélectionner'),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime:
                              endTime ?? const TimeOfDay(hour: 17, minute: 0),
                        );
                        if (time != null) {
                          setState(() {
                            endTime = time;
                          });
                        }
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (isClosed) {
                      _availability[day] = ['Fermé'];
                    } else if (startTime != null && endTime != null) {
                      _availability[day] = [
                        '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}',
                        '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}',
                      ];
                    }
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Vérifier la spécialité sélectionnée
    if (_selectedSpecialty == null || _selectedSpecialty!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une spécialité'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Utiliser la spécialité sélectionnée
    _specializationController.text = _selectedSpecialty!;

    // Vérifier la cohérence des mots de passe
    if (_createAccount) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les mots de passe ne correspondent pas'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_emailController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('L\'email est requis pour créer un compte'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = _selectedImage;

      // Si une nouvelle image a été sélectionnée, l'uploader
      if (_pickedImage != null) {
        imageUrl = await _uploadImageToFirebase(_pickedImage!);
      } else if (imageUrl.isEmpty) {
        // Image par défaut pour médecin
        imageUrl = 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d';
      }

      // Créer l'objet Doctor avec toutes les données harmonisées
      final doctor = Doctor(
        id: widget.doctor?.id ?? FirebaseFirestore.instance.collection('doctors').doc().id,
        name: _nameController.text.trim(),
        specialization: _specializationController.text.trim(),
        rating: double.parse(_ratingController.text),
        reviews: int.parse(_reviewsController.text),
        experience: int.parse(_experienceController.text),
        hospital: _hospitalController.text.trim(),
        department: _departmentController.text.trim().isNotEmpty
            ? _departmentController.text.trim()
            : null,
        imageUrl: imageUrl,
        isFavorite: widget.doctor?.isFavorite ?? false,
        consultationFee: double.parse(_consultationFeeController.text),
        languages: _selectedLanguages,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        availability: _availability,
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        password: _createAccount ? _passwordController.text : null,
        hasAccount: _createAccount,
        accountStatus: _createAccount ? 'active' : 'none',
        roles: const ['doctor'],
        roleData: {
          'licenseNumber': _licenseController.text.trim(),
          'specialization': _specializationController.text.trim(),
        },
        createdAt: widget.doctor?.createdAt ?? DateTime.now(),
        location: widget.doctor?.location ?? const GeoPoint(48.8566, 2.3522),
      );

      // Sauvegarder dans Firebase via le Provider
      final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);

      if (widget.doctor == null) {
        // Nouveau médecin
        await doctorProvider.addDoctorToFirebase(doctor);

        // Créer le compte Firebase Authentication si demandé
        if (_createAccount) {
          await _createFirebaseAuthAccount(doctor);
          
          // Si c'est une demande d'inscription, mettre à jour son statut
          if (widget.requestData != null && widget.requestData!['requestId'] != null) {
            await FirebaseFirestore.instance
                .collection('doctor_requests')
                .doc(widget.requestData!['requestId'])
                .update({
              'status': 'approved',
              'approvedBy': FirebaseAuth.instance.currentUser?.email,
              'approvedAt': FieldValue.serverTimestamp(),
              'doctorId': doctor.id,
            });
          }
        }
      } else {
        // Modification d'un médecin existant
        await doctorProvider.updateDoctorInFirebase(doctor);

        // Mettre à jour le compte Firebase Authentication si nécessaire
        if (_createAccount && (widget.doctor?.hasAccount == false)) {
          await _createFirebaseAuthAccount(doctor);
        }
      }

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.doctor == null
                ? 'Médecin ajouté avec succès!'
                : 'Médecin modifié avec succès!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Retourner à la page précédente
      if (mounted) {
        Navigator.pop(context, doctor); // Retourner le docteur créé/modifié
      }
    } catch (e) {
      // Afficher une erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _uploadImageToFirebase(XFile imageFile) async {
    try {
      // : Implémenter Firebase Storage
      return 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d';
    } catch (e) {
      print('Erreur upload image: $e');
      return 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d';
    }
  }

  Future<void> _createFirebaseAuthAccount(Doctor doctor) async {
    try {
      final auth = FirebaseAuth.instance;

      // Créer l'utilisateur dans Firebase Authentication
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: doctor.email!,
        password: doctor.password!,
      );

      // Mettre à jour le profil de l'utilisateur
      await userCredential.user!.updateDisplayName(doctor.name);
      await userCredential.user!.updatePhotoURL(doctor.imageUrl);

      // Ajouter le rôle dans Firestore users
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': doctor.email,
        'fullName': doctor.name,
        'phone': doctor.phoneNumber ?? '',
        'role': 'doctor',
        'profileCompleted': true,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'doctorId': doctor.id, // Lien vers la collection doctors
      });

      print('Compte Firebase Authentication créé pour ${doctor.name}');
    } catch (e) {
      print('Erreur lors de la création du compte auth: $e');
      rethrow;
    }
  }

  void _showDeleteConfirmation(Doctor doctor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${doctor.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
                await doctorProvider.deleteDoctorFromFirebase(doctor.id);
                
                // Si le médecin a un compte auth, le supprimer aussi
                if (doctor.hasAccount == true && doctor.email != null) {
                  try {
                    final user = await FirebaseAuth.instance.fetchSignInMethodsForEmail(doctor.email!);
                    if (user.isNotEmpty) {
                      // Note: Firebase Admin SDK serait nécessaire pour supprimer un utilisateur
                      // Pour l'instant, on se contente de désactiver
                      print('Compte auth trouvé pour ${doctor.email}, à désactiver via Admin SDK');
                    }
                  } catch (e) {
                    print('Erreur vérification compte auth: $e');
                  }
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${doctor.name} supprimé avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        // Section compte docteur
        Row(
          children: [
            Checkbox(
              value: _createAccount,
              onChanged: (value) {
                setState(() {
                  _createAccount = value ?? false;
                });
              },
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Créer un compte d\'accès pour ce médecin',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        if (_createAccount) ...[
          const SizedBox(height: 16),
          const Text(
            'Identifiants de connexion',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Le médecin pourra se connecter avec son email et ce mot de passe',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 16),

          // Email (déjà dans contact, mais on le rappelle ici)
          if (_emailController.text.isEmpty)
            _buildTextFormField(
              controller: _emailController,
              label: 'Email de connexion *',
              hintText: 'docteur@exemple.com',
              keyboardType: TextInputType.emailAddress,
              validator: _createAccount
                  ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'L\'email est requis pour créer un compte';
                      }
                      if (!value.contains('@')) {
                        return 'Email invalide';
                      }
                      return null;
                    }
                  : null,
            ),

          const SizedBox(height: 12),

          // Mot de passe
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mot de passe *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  hintText: 'Mot de passe sécurisé (min. 6 caractères)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                ),
                validator: _createAccount
                    ? (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le mot de passe est requis';
                        }
                        if (value.length < 6) {
                          return 'Minimum 6 caractères';
                        }
                        return null;
                      }
                  : null,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Confirmation mot de passe
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirmer le mot de passe *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  hintText: 'Répétez le mot de passe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: _createAccount
                    ? (value) {
                        if (value != _passwordController.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      }
                  : null,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Information de sécurité
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Un email sera envoyé au médecin avec ses identifiants de connexion',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSpecialtyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spécialité *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _selectedSpecialty,
          decoration: InputDecoration(
            hintText: 'Sélectionner une spécialité',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          items: _availableSpecialties.map((specialty) {
            return DropdownMenuItem(
              value: specialty,
              child: Text(specialty),
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
            if (value == null || value.isEmpty) {
              return 'Veuillez sélectionner une spécialité';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doctor == null
            ? (widget.requestData != null ? 'Approuver la demande' : 'Ajouter un médecin')
            : 'Modifier le médecin'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          if (widget.doctor != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(widget.doctor!),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo de profil
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(60),
                                color: AppTheme.lightGrey,
                                border: Border.all(color: AppTheme.primaryColor),
                              ),
                              child: _pickedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: Image.file(
                                        File(_pickedImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : _selectedImage.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(60),
                                          child: Image.network(
                                            _selectedImage,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Center(
                                                child: Icon(
                                                  Icons.person,
                                                  size: 50,
                                                  color: AppTheme.primaryColor,
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.add_a_photo,
                                            size: 40,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _pickImage,
                            child: const Text('Changer la photo'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Informations de base
                    const Text(
                      'Informations de base',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTextFormField(
                      controller: _nameController,
                      label: 'Nom complet *',
                      hintText: 'Dr. Jean Dupont',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le nom';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Spécialité avec dropdown
                    _buildSpecialtyDropdown(),

                    const SizedBox(height: 12),

                    _buildTextFormField(
                      controller: _hospitalController,
                      label: 'Hôpital/Clinique *',
                      hintText: 'Hôpital Saint-Louis',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le nom de l\'hôpital';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildTextFormField(
                      controller: _departmentController,
                      label: 'Département (optionnel)',
                      hintText: 'Cardiologie',
                    ),

                    const SizedBox(height: 12),

                    _buildTextFormField(
                      controller: _licenseController,
                      label: 'Numéro de licence *',
                      hintText: 'MED123456',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le numéro de licence est requis';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Statistiques
                    const Text(
                      'Statistiques',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            controller: _ratingController,
                            label: 'Note (1-5) *',
                            hintText: '4.5',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer la note';
                              }
                              final rating = double.tryParse(value);
                              if (rating == null || rating < 1 || rating > 5) {
                                return 'Note entre 1 et 5';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextFormField(
                            controller: _reviewsController,
                            label: 'Nombre d\'avis *',
                            hintText: '120',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer le nombre d\'avis';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Nombre valide requis';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            controller: _experienceController,
                            label: 'Expérience (années) *',
                            hintText: '10',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer l\'expérience';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Nombre valide requis';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextFormField(
                            controller: _consultationFeeController,
                            label: 'Tarif (€) *',
                            hintText: '80.00',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer le tarif';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Tarif valide requis';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Langues parlées
                    const Text(
                      'Langues parlées',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableLanguages.map((language) {
                        final isSelected = _selectedLanguages.contains(language);
                        return FilterChip(
                          label: Text(language),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedLanguages.add(language);
                              } else {
                                _selectedLanguages.remove(language);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Horaires de travail
                    const Text(
                      'Horaires de travail',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: _availability.entries.map((entry) {
                        final day = entry.key;
                        final times = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(day),
                            subtitle: Text(
                              times[0] == 'Fermé'
                                  ? 'Fermé'
                                  : '${times[0]} - ${times[1]}',
                            ),
                            trailing: const Icon(Icons.edit),
                            onTap: () => _showAvailabilityDialog(day),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Contact
                    const Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTextFormField(
                      controller: _phoneController,
                      label: 'Téléphone *',
                      hintText: '+33 1 23 45 67 89',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le téléphone est requis';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildTextFormField(
                      controller: _emailController,
                      label: 'Email *',
                      hintText: 'contact@medecin.com',
                      keyboardType: TextInputType.emailAddress,
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

                    // Section compte docteur
                    _buildAccountSection(),

                    const SizedBox(height: 24),

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Décrivez le médecin...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Enregistrer',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

extension on FirebaseAuth {
  Future<dynamic> fetchSignInMethodsForEmail(String s) {
    throw UnimplementedError('fetchSignInMethodsForEmail is not implemented.');
  }
}