// lib/presentation/pages/profile/patient_profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/patient_model.dart';
import 'package:doctorpoint/services/patient_service.dart';
import 'package:doctorpoint/core/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

class PatientProfilePage extends StatefulWidget {
  const PatientProfilePage({super.key});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final PatientService _patientService = PatientService();
  final ImagePicker _imagePicker = ImagePicker();

  Patient? _patient;
  bool _isLoading = true;
  bool _isEditing = false;
  File? _selectedImage;
  String? _imageUrl;

  final _formKey = GlobalKey<FormState>();

  // Contrôleurs
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();
  final TextEditingController _emergencyRelationController =
      TextEditingController();
  final TextEditingController _familyHistoryController =
      TextEditingController();

  String? _selectedGender;
  String? _selectedMaritalStatus;
  bool? _isSmoker;
  bool? _isAlcoholConsumer;
  int? _numberOfChildren;

  List<String> _allergies = [];
  List<String> _chronicDiseases = [];
  List<String> _currentMedications = [];
  List<Surgery> _surgeries = [];
  List<Vaccine> _vaccines = [];

  @override
  void initState() {
    super.initState();
    _loadPatientProfile();
  }

  Future<void> _loadPatientProfile() async {
    setState(() => _isLoading = true);

    try {
      final patient = await _patientService.getPatientProfile();
      if (patient != null) {
        setState(() {
          _patient = patient;
          _fillFormData(patient);
        });
      }
    } catch (e) {
      print('Erreur chargement profil: $e');
      _showErrorSnackbar('Erreur lors du chargement du profil');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _fillFormData(Patient patient) {
    _fullNameController.text = patient.fullName;
    _phoneController.text = patient.phone;
    _emailController.text = patient.email;
    _birthDateController.text = patient.birthDate != null
        ? DateFormat('dd/MM/yyyy').format(patient.birthDate!)
        : '';
    _addressController.text = patient.address ?? '';
    _cityController.text = patient.city ?? '';
    _postalCodeController.text = patient.postalCode ?? '';
    _countryController.text = patient.country ?? 'Sénégal';
    _bloodGroupController.text = patient.bloodGroup ?? '';
    _heightController.text = patient.height?.toStringAsFixed(0) ?? '';
    _weightController.text = patient.weight?.toStringAsFixed(1) ?? '';
    _occupationController.text = patient.occupation ?? '';
    _emergencyNameController.text = patient.emergencyContactName ?? '';
    _emergencyPhoneController.text = patient.emergencyContactPhone ?? '';
    _emergencyRelationController.text = patient.emergencyContactRelation ?? '';
    _familyHistoryController.text = patient.familyMedicalHistory ?? '';

    _selectedGender = patient.gender;
    _selectedMaritalStatus = patient.maritalStatus;
    _isSmoker = patient.smoker;
    _isAlcoholConsumer = patient.alcoholConsumer;
    _numberOfChildren = patient.numberOfChildren;

    _allergies = patient.allergies ?? [];
    _chronicDiseases = patient.chronicDiseases ?? [];
    _currentMedications = patient.currentMedications ?? [];
    _surgeries = patient.surgeries ?? [];
    _vaccines = patient.vaccines ?? [];
    _imageUrl = patient.photoUrl;
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la sélection de l\'image');
    }
  }

// Dans patient_profile_page.dart - Méthode _saveProfile
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Vérifier que le patient existe
      if (_patient == null || _patient!.uid.isEmpty) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('Utilisateur non connecté');
        }

        // Créer un patient avec l'ID de l'utilisateur
        _patient = Patient(
          id: currentUser.uid,
          uid: currentUser.uid,
          email: currentUser.email ?? '',
          fullName: currentUser.displayName ?? '',
          phone: currentUser.phoneNumber ?? '',
          profileCompleted: false,
          emailVerified: currentUser.emailVerified,
          createdAt: DateTime.now(),
        );
      }

      // Upload photo si nouvelle
      if (_selectedImage != null) {
        _imageUrl =
            await _patientService.uploadProfilePhoto(_selectedImage!.path);
      }

      // Créer ou mettre à jour le patient
      final patient = Patient(
        id: _patient!.id, // Toujours utiliser l'ID existant
        uid: _patient!.uid,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : _patient!.email,
        fullName: _fullNameController.text.trim().isNotEmpty
            ? _fullNameController.text.trim()
            : _patient!.fullName,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : _patient!.phone,
        gender: _selectedGender,
        birthDate: _birthDateController.text.isNotEmpty
            ? DateFormat('dd/MM/yyyy').parse(_birthDateController.text)
            : _patient!.birthDate,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : _patient!.address,
        city: _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : _patient!.city,
        postalCode: _postalCodeController.text.trim().isNotEmpty
            ? _postalCodeController.text.trim()
            : _patient!.postalCode,
        country: _countryController.text.trim().isNotEmpty
            ? _countryController.text.trim()
            : _patient!.country ?? 'Sénégal',
        bloodGroup: _bloodGroupController.text.trim().isNotEmpty
            ? _bloodGroupController.text.trim()
            : _patient!.bloodGroup,
        allergies: _allergies.isNotEmpty ? _allergies : _patient!.allergies,
        chronicDiseases: _chronicDiseases.isNotEmpty
            ? _chronicDiseases
            : _patient!.chronicDiseases,
        currentMedications: _currentMedications.isNotEmpty
            ? _currentMedications
            : _patient!.currentMedications,
        surgeries: _surgeries.isNotEmpty ? _surgeries : _patient!.surgeries,
        vaccines: _vaccines.isNotEmpty ? _vaccines : _patient!.vaccines,
        emergencyContactName: _emergencyNameController.text.trim().isNotEmpty
            ? _emergencyNameController.text.trim()
            : _patient!.emergencyContactName,
        emergencyContactPhone: _emergencyPhoneController.text.trim().isNotEmpty
            ? _emergencyPhoneController.text.trim()
            : _patient!.emergencyContactPhone,
        emergencyContactRelation:
            _emergencyRelationController.text.trim().isNotEmpty
                ? _emergencyRelationController.text.trim()
                : _patient!.emergencyContactRelation,
        photoUrl: _imageUrl ?? _patient!.photoUrl,
        height: _heightController.text.isNotEmpty
            ? double.tryParse(_heightController.text)
            : _patient!.height,
        weight: _weightController.text.isNotEmpty
            ? double.tryParse(_weightController.text)
            : _patient!.weight,
        smoker: _isSmoker ?? _patient!.smoker,
        alcoholConsumer: _isAlcoholConsumer ?? _patient!.alcoholConsumer,
        occupation: _occupationController.text.trim().isNotEmpty
            ? _occupationController.text.trim()
            : _patient!.occupation,
        maritalStatus: _selectedMaritalStatus ?? _patient!.maritalStatus,
        numberOfChildren: _numberOfChildren ?? _patient!.numberOfChildren,
        familyMedicalHistory: _familyHistoryController.text.trim().isNotEmpty
            ? _familyHistoryController.text.trim()
            : _patient!.familyMedicalHistory,
        profileCompleted: true, // Marquer comme complété
        emailVerified: _patient!.emailVerified,
        createdAt: _patient!.createdAt,
      );

      await _patientService.savePatientProfile(patient);

      setState(() {
        _patient = patient;
        _isEditing = false;
      });

      _showSuccessSnackbar('Profil mis à jour avec succès');
    } catch (e) {
      _showErrorSnackbar('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.1),
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                    : _imageUrl != null && _imageUrl!.isNotEmpty
                        ? Image.network(_imageUrl!, fit: BoxFit.cover)
                        : Icon(
                            Icons.person,
                            size: 60,
                            color: AppTheme.primaryColor,
                          ),
              ),
            ),
            if (_isEditing)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 20),
                  onPressed: _pickImage,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Nom
        Text(
          _patient?.fullName ?? 'Patient',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Email
        if (_patient?.email != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _patient!.email,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),

        // Âge et Genre
        if (_patient?.age != null && _patient!.age > 0 ||
            _patient?.gender != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_patient?.age != null && _patient!.age > 0)
                  Text(
                    '${_patient!.age} ans',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                if (_patient?.age != null &&
                    _patient!.age > 0 &&
                    _patient?.gender != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '•',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                if (_patient?.gender != null)
                  Text(
                    _patient!.gender!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),

        // Localisation
        if (_patient?.city != null || _patient?.country != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _patient!.location,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

        // Groupe sanguin
        if (_patient?.bloodGroup != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade200, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bloodtype, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    'Groupe ${_patient!.bloodGroup!}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Occupation
        if (_patient?.occupation != null && _patient!.occupation!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.work, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    _patient!.occupation!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Statut de vérification email
        if (_patient != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _patient!.emailVerified ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _patient!.emailVerified
                      ? 'Email vérifié'
                      : 'Email non vérifié',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        _patient!.emailVerified ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProfileCompletionIndicator() {
    if (_patient == null || _patient!.profileCompleted) return const SizedBox();

    final missingFields = <String>[];

    if (_patient!.birthDate == null) missingFields.add('Date de naissance');
    if (_patient!.gender == null || _patient!.gender!.isEmpty) {
      missingFields.add('Genre');
    }
    if (_patient!.address == null || _patient!.address!.isEmpty) {
      missingFields.add('Adresse');
    }
    if (_patient!.city == null || _patient!.city!.isEmpty) {
      missingFields.add('Ville');
    }
    if (_patient!.bloodGroup == null || _patient!.bloodGroup!.isEmpty) {
      missingFields.add('Groupe sanguin');
    }

    if (missingFields.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Profil incomplet (${(missingFields.length / 5 * 100).toInt()}%)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pour une meilleure expérience, complétez votre profil:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 4),
          ...missingFields.take(3).map((field) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '• $field',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
              )),
          if (missingFields.length > 3)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '• et ${missingFields.length - 3} autres...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                setState(() => _isEditing = true);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                backgroundColor: Colors.orange.shade100,
              ),
              child: Text(
                'Compléter maintenant',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthInfoSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Informations Médicales',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_isEditing)
                  IconButton(
                    icon: Icon(Icons.edit,
                        size: 20, color: AppTheme.primaryColor),
                    onPressed: () => setState(() => _isEditing = true),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Groupe sanguin
            if (_patient?.bloodGroup != null)
              _buildInfoRow(
                icon: Icons.bloodtype,
                label: 'Groupe sanguin',
                value: _patient!.bloodGroup!,
                color: Colors.red,
              ),

            // Taille et poids
            if (_patient?.height != null || _patient?.weight != null)
              _buildInfoRow(
                icon: Icons.monitor_weight,
                label: 'Taille / Poids',
                value:
                    '${_patient?.height?.toStringAsFixed(0) ?? '--'} cm / ${_patient?.weight?.toStringAsFixed(1) ?? '--'} kg',
                color: Colors.blue,
              ),

            // IMC
            if (_patient?.bmi != null)
              _buildInfoRow(
                icon: Icons.scale,
                label: 'IMC',
                value:
                    '${_patient!.bmi!.toStringAsFixed(1)} (${_patient!.bmiCategory})',
                color: _patient!.bmiCategory == 'Poids normal'
                    ? Colors.green
                    : Colors.orange,
              ),

            // Mode de vie
            if (_isSmoker != null || _isAlcoholConsumer != null)
              const Divider(),

            if (_isSmoker != null)
              _buildInfoRow(
                icon: Icons.smoking_rooms,
                label: 'Fumeur',
                value: _isSmoker! ? 'Oui' : 'Non',
                color: _isSmoker! ? Colors.red : Colors.green,
              ),

            if (_isAlcoholConsumer != null)
              _buildInfoRow(
                icon: Icons.local_drink,
                label: 'Consommation d\'alcool',
                value: _isAlcoholConsumer! ? 'Oui' : 'Non',
                color: _isAlcoholConsumer! ? Colors.orange : Colors.green,
              ),

            // Allergies
            if (_allergies.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text(
                    'Allergies',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _allergies
                        .map((allergy) => Chip(
                              label: Text(allergy),
                              backgroundColor: Colors.red.shade50,
                              labelStyle: TextStyle(color: Colors.red.shade800),
                            ))
                        .toList(),
                  ),
                ],
              ),

            // Maladies chroniques
            if (_chronicDiseases.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text(
                    'Maladies chroniques',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _chronicDiseases
                        .map((disease) => Chip(
                              label: Text(disease),
                              backgroundColor: Colors.orange.shade50,
                              labelStyle:
                                  TextStyle(color: Colors.orange.shade800),
                            ))
                        .toList(),
                  ),
                ],
              ),

            // Médicaments actuels
            if (_currentMedications.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text(
                    'Médicaments actuels',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _currentMedications
                        .map((med) => Chip(
                              label: Text(med),
                              backgroundColor: Colors.blue.shade50,
                              labelStyle:
                                  TextStyle(color: Colors.blue.shade800),
                            ))
                        .toList(),
                  ),
                ],
              ),

            // Antécédents chirurgicaux
            if (_surgeries.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text(
                    'Antécédents chirurgicaux',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._surgeries.map((surgery) => ListTile(
                        leading:
                            Icon(Icons.medical_services, color: Colors.purple),
                        title: Text(surgery.name),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy').format(surgery.date)}${surgery.hospital != null ? ' - ${surgery.hospital}' : ''}',
                        ),
                        trailing: _isEditing
                            ? IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeSurgery(surgery),
                              )
                            : null,
                      )),
                ],
              ),

            // Vaccins
            if (_vaccines.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text(
                    'Vaccinations',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._vaccines.map((vaccine) => ListTile(
                        leading: Icon(Icons.vaccines, color: Colors.green),
                        title: Text(vaccine.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Date: ${DateFormat('dd/MM/yyyy').format(vaccine.date)}'),
                            if (vaccine.nextDoseDate != null)
                              Text(
                                  'Prochaine dose: ${DateFormat('dd/MM/yyyy').format(vaccine.nextDoseDate!)}'),
                          ],
                        ),
                        trailing: _isEditing
                            ? IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeVaccine(vaccine),
                              )
                            : null,
                      )),
                ],
              ),

            // Histoire familiale
            if (_patient?.familyMedicalHistory != null &&
                _patient!.familyMedicalHistory!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text(
                    'Histoire médicale familiale',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _patient!.familyMedicalHistory!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations Personnelles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Statut matrimonial
            if (_patient?.maritalStatus != null)
              _buildInfoRow(
                icon: Icons.family_restroom,
                label: 'Statut matrimonial',
                value: _patient!.maritalStatus!,
                color: Colors.purple,
              ),

            // Nombre d'enfants
            if (_patient?.numberOfChildren != null)
              _buildInfoRow(
                icon: Icons.child_care,
                label: 'Nombre d\'enfants',
                value: _patient!.numberOfChildren!.toString(),
                color: Colors.pink,
              ),

            // Occupation
            if (_patient?.occupation != null &&
                _patient!.occupation!.isNotEmpty)
              _buildInfoRow(
                icon: Icons.work,
                label: 'Profession',
                value: _patient!.occupation!,
                color: Colors.blue,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Coordonnées',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Téléphone
            _buildInfoRow(
              icon: Icons.phone,
              label: 'Téléphone',
              value: _patient?.phone ?? 'Non renseigné',
              color: AppTheme.primaryColor,
            ),

            // Email
            _buildInfoRow(
              icon: Icons.email,
              label: 'Email',
              value: _patient?.email ?? 'Non renseigné',
              color: Colors.blue,
            ),

            // Adresse
            if (_patient?.address != null)
              _buildInfoRow(
                icon: Icons.location_on,
                label: 'Adresse',
                value:
                    '${_patient!.address}, ${_patient!.city} ${_patient!.postalCode}',
                color: Colors.green,
              ),

            // Contact d'urgence
            if (_patient?.emergencyContactName != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text(
                    'Contact d\'urgence',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: Icons.emergency,
                    label: 'Nom',
                    value: _patient!.emergencyContactName!,
                    color: Colors.red,
                  ),
                  if (_patient?.emergencyContactPhone != null)
                    _buildInfoRow(
                      icon: Icons.phone,
                      label: 'Téléphone',
                      value: _patient!.emergencyContactPhone!,
                      color: Colors.red,
                    ),
                  if (_patient?.emergencyContactRelation != null)
                    _buildInfoRow(
                      icon: Icons.group,
                      label: 'Relation',
                      value: _patient!.emergencyContactRelation!,
                      color: Colors.red,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête édition
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _isEditing = false),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Modifier le profil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Informations personnelles
            const Text(
              'Informations personnelles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Nom complet
            _buildFormField(
              controller: _fullNameController,
              label: 'Nom complet *',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ce champ est requis';
                }
                return null;
              },
            ),

            // Genre
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Genre',
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
            ),

            // Date de naissance
            TextFormField(
              controller: _birthDateController,
              decoration: const InputDecoration(
                labelText: 'Date de naissance',
                prefixIcon: Icon(Icons.cake),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      DateTime.now().subtract(const Duration(days: 365 * 30)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  _birthDateController.text =
                      DateFormat('dd/MM/yyyy').format(date);
                }
              },
            ),

            // Statut matrimonial
            DropdownButtonFormField<String>(
              value: _selectedMaritalStatus,
              decoration: const InputDecoration(
                labelText: 'Statut matrimonial',
                prefixIcon: Icon(Icons.family_restroom),
              ),
              items: [
                'Célibataire',
                'Marié(e)',
                'Divorcé(e)',
                'Veuf/Veuve',
                'Union libre'
              ]
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedMaritalStatus = value);
              },
            ),

            // Nombre d'enfants
            TextFormField(
              controller: TextEditingController(
                text: _numberOfChildren?.toString() ?? '',
              ),
              decoration: const InputDecoration(
                labelText: 'Nombre d\'enfants',
                prefixIcon: Icon(Icons.child_care),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _numberOfChildren = int.tryParse(value);
              },
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

            // Téléphone
            _buildFormField(
              controller: _phoneController,
              label: 'Téléphone *',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ce champ est requis';
                }
                return null;
              },
            ),

            // Adresse
            _buildFormField(
              controller: _addressController,
              label: 'Adresse',
              icon: Icons.home,
            ),

            // Ville et code postal
            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    controller: _cityController,
                    label: 'Ville',
                    icon: Icons.location_city,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFormField(
                    controller: _postalCodeController,
                    label: 'Code postal',
                    icon: Icons.numbers,
                  ),
                ),
              ],
            ),

            // Pays
            _buildFormField(
              controller: _countryController,
              label: 'Pays',
              icon: Icons.public,
            ),

            const SizedBox(height: 24),

            // Profession
            const Text(
              'Profession',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildFormField(
              controller: _occupationController,
              label: 'Profession',
              icon: Icons.work,
            ),

            const SizedBox(height: 24),

            // Santé
            const Text(
              'Informations médicales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Groupe sanguin
            DropdownButtonFormField<String>(
              value: _bloodGroupController.text.isNotEmpty
                  ? _bloodGroupController.text
                  : null,
              decoration: const InputDecoration(
                labelText: 'Groupe sanguin',
                prefixIcon: Icon(Icons.bloodtype),
              ),
              items: [
                'A+',
                'A-',
                'B+',
                'B-',
                'AB+',
                'AB-',
                'O+',
                'O-',
                'Non connu'
              ]
                  .map((group) => DropdownMenuItem(
                        value: group,
                        child: Text(group),
                      ))
                  .toList(),
              onChanged: (value) {
                _bloodGroupController.text = value ?? '';
              },
            ),

            // Taille et poids
            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    controller: _heightController,
                    label: 'Taille (cm)',
                    icon: Icons.height,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFormField(
                    controller: _weightController,
                    label: 'Poids (kg)',
                    icon: Icons.monitor_weight,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            // Mode de vie
            const SizedBox(height: 16),
            const Text(
              'Mode de vie',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Fumeur'),
                    leading: Radio<bool>(
                      value: true,
                      groupValue: _isSmoker,
                      onChanged: (value) {
                        setState(() => _isSmoker = value);
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Non-fumeur'),
                    leading: Radio<bool>(
                      value: false,
                      groupValue: _isSmoker,
                      onChanged: (value) {
                        setState(() => _isSmoker = value);
                      },
                    ),
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Consommation d\'alcool'),
                    leading: Radio<bool>(
                      value: true,
                      groupValue: _isAlcoholConsumer,
                      onChanged: (value) {
                        setState(() => _isAlcoholConsumer = value);
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Pas d\'alcool'),
                    leading: Radio<bool>(
                      value: false,
                      groupValue: _isAlcoholConsumer,
                      onChanged: (value) {
                        setState(() => _isAlcoholConsumer = value);
                      },
                    ),
                  ),
                ),
              ],
            ),

            // Allergies
            _buildListSection(
              title: 'Allergies',
              list: _allergies,
              onAdd: () => _showAddDialog('allergy'),
              onRemove: (item) {
                setState(() => _allergies.remove(item));
              },
            ),

            // Maladies chroniques
            _buildListSection(
              title: 'Maladies chroniques',
              list: _chronicDiseases,
              onAdd: () => _showAddDialog('chronic'),
              onRemove: (item) {
                setState(() => _chronicDiseases.remove(item));
              },
            ),

            // Médicaments
            _buildListSection(
              title: 'Médicaments actuels',
              list: _currentMedications,
              onAdd: () => _showAddDialog('medication'),
              onRemove: (item) {
                setState(() => _currentMedications.remove(item));
              },
            ),

            // Antécédents chirurgicaux
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Antécédents chirurgicaux',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addSurgery,
                ),
              ],
            ),

            if (_surgeries.isNotEmpty)
              ..._surgeries.map((surgery) => ListTile(
                    leading: Icon(Icons.medical_services, color: Colors.purple),
                    title: Text(surgery.name),
                    subtitle: Text(
                        '${DateFormat('dd/MM/yyyy').format(surgery.date)}${surgery.hospital != null ? ' - ${surgery.hospital}' : ''}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeSurgery(surgery),
                    ),
                  )),

            // Vaccins
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vaccinations',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addVaccine,
                ),
              ],
            ),

            if (_vaccines.isNotEmpty)
              ..._vaccines.map((vaccine) => ListTile(
                    leading: Icon(Icons.vaccines, color: Colors.green),
                    title: Text(vaccine.name),
                    subtitle: Text(
                        'Date: ${DateFormat('dd/MM/yyyy').format(vaccine.date)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeVaccine(vaccine),
                    ),
                  )),

            // Histoire familiale
            const SizedBox(height: 16),
            const Text(
              'Histoire médicale familiale',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextFormField(
              controller: _familyHistoryController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Antécédents médicaux dans la famille...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // Contact d'urgence
            const Text(
              'Contact d\'urgence',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildFormField(
              controller: _emergencyNameController,
              label: 'Nom du contact',
              icon: Icons.emergency,
            ),

            _buildFormField(
              controller: _emergencyPhoneController,
              label: 'Téléphone du contact',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),

            _buildFormField(
              controller: _emergencyRelationController,
              label: 'Relation (parent, conjoint, etc.)',
              icon: Icons.group,
            ),

            const SizedBox(height: 32),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _isEditing = false);
                    },
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Enregistrer'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildListSection({
    required String title,
    required List<String> list,
    required VoidCallback onAdd,
    required Function(String) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: onAdd,
            ),
          ],
        ),
        if (list.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: list
                .map((item) => Chip(
                      label: Text(item),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => onRemove(item),
                    ))
                .toList(),
          ),
      ],
    );
  }

  void _showAddDialog(String type) {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_getDialogTitle(type)),
          content: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: _getDialogLabel(type),
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    switch (type) {
                      case 'allergy':
                        _allergies.add(controller.text);
                        break;
                      case 'chronic':
                        _chronicDiseases.add(controller.text);
                        break;
                      case 'medication':
                        _currentMedications.add(controller.text);
                        break;
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    ).then((_) {
      focusNode.dispose();
    });
  }

  Future<void> _addSurgery() async {
    final nameController = TextEditingController();
    final hospitalController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ajouter une intervention chirurgicale'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de l\'intervention',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: hospitalController,
                      decoration: const InputDecoration(
                        labelText: 'Hôpital/Clinique',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          selectedDate = date;
                          setState(() {});
                        }
                      },
                      controller: TextEditingController(
                        text: selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                            : '',
                      ),
                    ),
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
                    if (nameController.text.isNotEmpty &&
                        selectedDate != null) {
                      final surgery = Surgery(
                        name: nameController.text,
                        date: selectedDate!,
                        hospital: hospitalController.text.isNotEmpty
                            ? hospitalController.text
                            : null,
                        notes: notesController.text.isNotEmpty
                            ? notesController.text
                            : null,
                      );

                      setState(() {
                        _surgeries.add(surgery);
                      });

                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addVaccine() async {
    final nameController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? selectedDate;
    DateTime? nextDoseDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ajouter un vaccin'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du vaccin',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Date de vaccination',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          selectedDate = date;
                          setState(() {});
                        }
                      },
                      controller: TextEditingController(
                        text: selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                            : '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Date de prochaine dose (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365 * 10)),
                        );
                        if (date != null) {
                          nextDoseDate = date;
                          setState(() {});
                        }
                      },
                      controller: TextEditingController(
                        text: nextDoseDate != null
                            ? DateFormat('dd/MM/yyyy').format(nextDoseDate!)
                            : '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
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
                    if (nameController.text.isNotEmpty &&
                        selectedDate != null) {
                      final vaccine = Vaccine(
                        name: nameController.text,
                        date: selectedDate!,
                        nextDoseDate: nextDoseDate,
                        notes: notesController.text.isNotEmpty
                            ? notesController.text
                            : null,
                      );

                      setState(() {
                        _vaccines.add(vaccine);
                      });

                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeSurgery(Surgery surgery) {
    setState(() {
      _surgeries.remove(surgery);
    });
  }

  void _removeVaccine(Vaccine vaccine) {
    setState(() {
      _vaccines.remove(vaccine);
    });
  }

  String _getDialogTitle(String type) {
    switch (type) {
      case 'allergy':
        return 'Ajouter une allergie';
      case 'chronic':
        return 'Ajouter une maladie chronique';
      case 'medication':
        return 'Ajouter un médicament';
      default:
        return '';
    }
  }

  String _getDialogLabel(String type) {
    switch (type) {
      case 'allergy':
        return 'Nom de l\'allergie';
      case 'chronic':
        return 'Nom de la maladie';
      case 'medication':
        return 'Nom du médicament';
      default:
        return '';
    }
  }

  Widget _buildProfileView() {
    return RefreshIndicator(
      onRefresh: _loadPatientProfile,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildProfileHeader(),
                const SizedBox(height: 20),
                _buildProfileCompletionIndicator(),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildPersonalInfoSection(),
              _buildHealthInfoSection(),
              _buildContactInfoSection(),
              const SizedBox(height: 20),
              // Bouton d'édition
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _isEditing = true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.edit, size: 20),
                    label: const Text('Modifier le profil'),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.security, color: Colors.blue),
                title: const Text('Sécurité du compte'),
                onTap: () {
                  Navigator.pop(context);
                  _showSecurityDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.verified_user, color: Colors.green),
                title: const Text('Vérifier l\'email'),
                onTap: () {
                  Navigator.pop(context);
                  _verifyEmail();
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip, color: Colors.purple),
                title: const Text('Confidentialité'),
                onTap: () {
                  Navigator.pop(context);
                  _showPrivacyDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.help, color: Colors.orange),
                title: const Text('Aide et support'),
                onTap: () {
                  Navigator.pop(context);
                  // Naviguer vers la page d'aide
                  // Navigator.pushNamed(context, '/help');
                },
              ),
              ListTile(
                leading: const Icon(Icons.info, color: Colors.grey),
                title: const Text('À propos'),
                onTap: () {
                  Navigator.pop(context);
                  // Naviguer vers la page à propos
                  // Navigator.pushNamed(context, '/about');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer le compte'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteAccountDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Déconnexion'),
                onTap: () async {
                  Navigator.pop(context);
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  await authProvider.signOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSecurityDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool showPasswords = false;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Changer le mot de passe'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: !showPasswords,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe actuel',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: !showPasswords,
                      decoration: InputDecoration(
                        labelText: 'Nouveau mot de passe',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: !showPasswords,
                      decoration: InputDecoration(
                        labelText: 'Confirmer le nouveau mot de passe',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPasswords
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              showPasswords = !showPasswords;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (newPasswordController.text !=
                              confirmPasswordController.text) {
                            _showErrorSnackbar(
                                'Les mots de passe ne correspondent pas');
                            return;
                          }

                          if (newPasswordController.text.length < 6) {
                            _showErrorSnackbar(
                                'Le mot de passe doit contenir au moins 6 caractères');
                            return;
                          }

                          setState(() => isLoading = true);

                          try {
                            await _patientService.changePassword(
                              currentPasswordController.text,
                              newPasswordController.text,
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              _showSuccessSnackbar(
                                  'Mot de passe changé avec succès');
                            }
                          } catch (e) {
                            _showErrorSnackbar('Erreur: ${e.toString()}');
                          } finally {
                            if (mounted) {
                              setState(() => isLoading = false);
                            }
                          }
                        },
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Changer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _verifyEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await user.sendEmailVerification();
      _showSuccessSnackbar('Email de vérification envoyé');
    } catch (e) {
      _showErrorSnackbar('Erreur: ${e.toString()}');
    }
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confidentialité'),
          content: const SingleChildScrollView(
            child: Text(
              'Vos données médicales sont strictement confidentielles et ne sont partagées qu\'avec votre consentement explicite. '
              'Seuls les professionnels de santé que vous autorisez peuvent accéder à votre dossier médical complet.\n\n'
              'Vous pouvez à tout moment modifier vos préférences de confidentialité et consulter l\'historique des accès à vos données.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le compte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚠️ Cette action est irréversible !\n\n'
                'Toutes vos données seront définitivement supprimées:\n'
                '• Profil patient\n'
                '• Historique médical\n'
                '• Rendez-vous\n'
                '• Photos et documents\n\n'
                'Pour confirmer, entrez votre mot de passe:',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _patientService.deleteAccount();
                  if (mounted) {
                    Navigator.pop(context);
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    await authProvider.signOut();
                  }
                } catch (e) {
                  _showErrorSnackbar('Erreur: ${e.toString()}');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Supprimer définitivement'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _patient == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettingsMenu,
            ),
        ],
      ),
      body: _isEditing ? _buildEditForm() : _buildProfileView(),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _bloodGroupController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _occupationController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _familyHistoryController.dispose();
    super.dispose();
  }
}
