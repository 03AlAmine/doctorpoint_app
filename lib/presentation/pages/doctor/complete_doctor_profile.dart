import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:flutter/material.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CompleteDoctorProfilePage extends StatefulWidget {
  final String doctorId;

  const CompleteDoctorProfilePage({super.key, required this.doctorId});

  @override
  State<CompleteDoctorProfilePage> createState() =>
      _CompleteDoctorProfilePageState();
}

class _CompleteDoctorProfilePageState extends State<CompleteDoctorProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _consultationFeeController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final AuthService _authService = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  File? _selectedImage;
  final bool _isLoading = false;
  bool _isSubmitting = false;
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

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    try {
      final doc = await _db.collection('doctors').doc(widget.doctorId).get();
      if (doc.exists) {
        final data = doc.data()!;

        setState(() {
          _hospitalController.text = data['hospital'] ?? '';
          _experienceController.text = (data['experience'] ?? 0).toString();
          _consultationFeeController.text =
              (data['consultationFee'] ?? 0.0).toString();
          _descriptionController.text = data['description'] ?? '';

          if (data['languages'] != null) {
            _selectedLanguages = List<String>.from(data['languages']);
          }

          if (data['availability'] != null) {
            final avail = data['availability'] as Map<String, dynamic>;
            _availability = avail
                .map((key, value) => MapEntry(key, List<String>.from(value)));
          }
        });
      }
    } catch (e) {
      print('Erreur chargement données: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      // Pour le développement, retourner une URL fictive
      // En production, implémenter Firebase Storage upload
      await Future.delayed(const Duration(seconds: 1));
      return 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d';
    } catch (e) {
      print('Erreur upload image: $e');
      return null;
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Upload l'image si sélectionnée
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage();
      }

      // Validation des données
      final hospital = _hospitalController.text.trim();
      if (hospital.isEmpty) {
        throw Exception('Veuillez renseigner votre établissement');
      }

      final experience = int.tryParse(_experienceController.text) ?? 0;
      if (experience < 0) {
        throw Exception('L\'expérience ne peut pas être négative');
      }

      final consultationFee = double.tryParse(_consultationFeeController.text) ?? 0.0;
      if (consultationFee < 0) {
        throw Exception('Le tarif ne peut pas être négatif');
      }

      // Compléter le profil
      await _authService.completeDoctorProfile(
        doctorId: widget.doctorId,
        hospital: hospital,
        experience: experience,
        consultationFee: consultationFee,
        languages: _selectedLanguages,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        availability: _availability,
        imageUrl: imageUrl,
      );

      // Mettre à jour le statut de l'utilisateur
      await _db.collection('users').doc(widget.doctorId).update({
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Vérifier si tous les documents sont uploadés
      final doctorDoc = await _db.collection('doctors').doc(widget.doctorId).get();
      if (doctorDoc.exists) {
        final doctorData = doctorDoc.data()!;
        final roleData = doctorData['roleData'] as Map<String, dynamic>?;
        final verification = roleData?['verification'] as Map<String, dynamic>?;
        final verificationStatus = verification?['status'] ?? 'pending_documents';

        if (verificationStatus == 'pending_documents') {
          // Rediriger vers la page des documents
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profil complété ! Veuillez maintenant uploader vos documents.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );

            Navigator.pushReplacementNamed(
              context,
              '/doctor-documents',
              arguments: widget.doctorId,
            );
            return;
          }
        }
      }

      // Si les documents sont déjà uploadés, rediriger vers le dashboard
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil complété avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Charger les données du médecin pour le dashboard
        final doctorDoc = await _db.collection('doctors').doc(widget.doctorId).get();
        if (doctorDoc.exists) {
          final doctor = Doctor.fromFirestore(doctorDoc);
          Navigator.pushReplacementNamed(
            context,
            '/doctor-dashboard',
            arguments: doctor,
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('Erreur complétion profil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header avec icône
                    Row(
                      children: [
                        Icon(
                          isClosed ? Icons.event_busy : Icons.event_available,
                          color: isClosed ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isClosed
                              ? 'Journée non travaillée'
                              : 'Journée de travail',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isClosed ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Toggle fermé/ouvert
                    SwitchListTile(
                      title: Text(
                        isClosed ? 'Fermé' : 'Ouvert',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isClosed ? Colors.red : Colors.green,
                        ),
                      ),
                      subtitle: Text(
                        isClosed
                            ? 'Aucun rendez-vous disponible'
                            : 'Acceptez les rendez-vous',
                      ),
                      value: !isClosed,
                      onChanged: (value) {
                        setState(() {
                          isClosed = !value;
                          if (value) {
                            startTime = const TimeOfDay(hour: 9, minute: 0);
                            endTime = const TimeOfDay(hour: 17, minute: 0);
                          } else {
                            startTime = null;
                            endTime = null;
                          }
                        });
                      },
                      secondary: Icon(
                        isClosed ? Icons.block : Icons.check_circle,
                        color: isClosed ? Colors.red : Colors.green,
                      ),
                    ),

                    if (!isClosed) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 10),

                      // Card pour les horaires
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              // Heure d'ouverture
                              InkWell(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: startTime ??
                                        const TimeOfDay(hour: 9, minute: 0),
                                    builder: (context, child) {
                                      return Theme(
                                        data: ThemeData.light().copyWith(
                                          primaryColor: AppTheme.primaryColor,
                                          colorScheme: const ColorScheme.light(
                                            primary: AppTheme.primaryColor,
                                          ),
                                          buttonTheme: const ButtonThemeData(
                                            textTheme: ButtonTextTheme.primary,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (time != null) {
                                    setState(() {
                                      startTime = time;
                                      // Ajuster automatiquement l'heure de fin si nécessaire
                                      if (endTime != null &&
                                          time.hour >= endTime!.hour) {
                                        endTime = TimeOfDay(
                                          hour: time.hour + 1,
                                          minute: time.minute,
                                        );
                                      }
                                    });
                                  }
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.sunny,
                                        color: startTime != null
                                            ? Colors.orange
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Heure d\'ouverture',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            Text(
                                              startTime != null
                                                  ? startTime!.format(context)
                                                  : 'Sélectionner',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: startTime != null
                                                    ? Colors.black
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right,
                                          color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),

                              const Divider(),

                              // Heure de fermeture
                              InkWell(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: endTime ??
                                        const TimeOfDay(hour: 17, minute: 0),
                                  );
                                  if (time != null) {
                                    // Validation : heure de fermeture doit être après heure d'ouverture
                                    if (startTime != null &&
                                        time.hour <= startTime!.hour) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                              'L\'heure de fermeture doit être après l\'heure d\'ouverture'),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } else {
                                      setState(() {
                                        endTime = time;
                                      });
                                    }
                                  }
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.nightlight_round,
                                        color: endTime != null
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Heure de fermeture',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            Text(
                                              endTime != null
                                                  ? endTime!.format(context)
                                                  : 'Sélectionner',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: endTime != null
                                                    ? Colors.black
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right,
                                          color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),

                              // Durée totale
                              if (startTime != null && endTime != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.schedule,
                                          size: 16, color: Colors.green),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Durée : ${_calculateDuration(startTime!, endTime!)}',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
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
                      // Validation finale
                      if (startTime!.hour >= endTime!.hour) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'L\'heure d\'ouverture doit être avant l\'heure de fermeture'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Calculer la durée minimale (au moins 1 heure)
                      final duration =
                          _calculateDurationInHours(startTime!, endTime!);
                      if (duration < 1) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'La journée de travail doit durer au moins 1 heure'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      _availability[day] = [
                        '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}',
                        '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}',
                      ];

                      print(
                          'Horaires du $day enregistrés: ${_availability[day]}');
                    } else if (!isClosed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Veuillez sélectionner les heures de début et de fin'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _calculateDuration(TimeOfDay start, TimeOfDay end) {
    final startInMinutes = start.hour * 60 + start.minute;
    final endInMinutes = end.hour * 60 + end.minute;
    final durationMinutes = endInMinutes - startInMinutes;

    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours h $minutes min';
    } else if (hours > 0) {
      return '$hours h';
    } else {
      return '$minutes min';
    }
  }

  double _calculateDurationInHours(TimeOfDay start, TimeOfDay end) {
    final startInMinutes = start.hour * 60 + start.minute;
    final endInMinutes = end.hour * 60 + end.minute;
    return (endInMinutes - startInMinutes) / 60.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compléter votre profil'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: (_isLoading || _isSubmitting)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Instructions
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📋 Informations requises',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Complétez votre profil professionnel pour être visible par les patients.',
                            style: TextStyle(
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),

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
                                border:
                                    Border.all(color: AppTheme.primaryColor),
                              ),
                              child: _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Center(
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
                            child: const Text('Ajouter une photo de profil'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Informations professionnelles
                    const Text(
                      'Informations professionnelles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildTextFormField(
                      controller: _hospitalController,
                      label: 'Hôpital/Clinique *',
                      hintText: 'Nom de votre établissement',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ce champ est requis';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildTextFormField(
                      controller: _experienceController,
                      label: 'Années d\'expérience *',
                      hintText: '5',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ce champ est requis';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Veuillez entrer un nombre';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildTextFormField(
                      controller: _consultationFeeController,
                      label: 'Tarif consultation (€) *',
                      hintText: '80.00',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ce champ est requis';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Veuillez entrer un montant valide';
                        }
                        return null;
                      },
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          for (var entry in _availability.entries)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    entry.value[0] == 'Fermé'
                                        ? 'Fermé'
                                        : '${entry.value[0]} - ${entry.value[1]}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: entry.value[0] == 'Fermé'
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () =>
                                        _showAvailabilityDialog(entry.key),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
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
                        final isSelected =
                            _selectedLanguages.contains(language);
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
                        hintText:
                            'Décrivez votre expertise, vos spécialités...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Bouton de soumission
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : const Text(
                                'Terminer mon profil',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Information
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Votre profil sera visible par les patients une fois validé par l\'administration.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
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