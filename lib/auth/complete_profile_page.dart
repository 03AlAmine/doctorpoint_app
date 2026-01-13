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
  
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  String? _selectedBloodGroup;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Non connu'
  ];

  final List<String> _genders = ['Homme', 'Femme', 'Autre'];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header avec effet de verre
            SliverAppBar(
              expandedHeight: 240,
              collapsedHeight: 80,
              pinned: true,
              floating: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(constraints.maxHeight > 100 ? 40 : 0),
                        bottomRight: Radius.circular(constraints.maxHeight > 100 ? 40 : 0),
                      ),
                    ),
                    child: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      title: constraints.maxHeight <= 100 
                          ? Text('Complétez votre profil', 
                              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                              ))
                          : null,
                      background: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Presque terminé !',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 28 : 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 32 : 80,
                            ),
                            child: Text(
                              'Complétez votre profil pour profiter pleinement de DoctorPoint',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                color: Colors.white.withOpacity(0.9),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              leading: IconButton(
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Contenu principal
            SliverPadding(
              padding: AppTheme.screenPadding,
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    
                    // Indicateur de progression moderne
                    _buildProgressIndicator(),
                    const SizedBox(height: 40),
                    
                    // Formulaire
                    Container(
                      decoration: AppTheme.cardDecoration,
                      padding: AppTheme.cardPadding,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Message d'erreur élégant
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
                            
                            // Grille responsive pour les champs
                            isSmallScreen 
                                ? _buildFormFieldsVertical()
                                : _buildFormFieldsGrid(),
                            
                            const SizedBox(height: 32),
                            
                            // Information contextuelle
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.infoColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.infoColor.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppTheme.infoColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.info_outline_rounded,
                                      color: AppTheme.infoColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Information importante',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.infoColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Ces informations sont essentielles pour vos rendez-vous médicaux. Vous pourrez les modifier ultérieurement dans les paramètres de votre compte.',
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
                            
                            const SizedBox(height: 40),
                            
                            // Boutons d'action
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progression du profil',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedContainer(
                duration: AppTheme.mediumAnimationDuration,
                curve: AppTheme.easeInOutCubic,
                height: 8,
                width: MediaQuery.of(context).size.width * 0.5,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Étape 2 sur 2',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.greyColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '50% complété',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormFieldsVertical() {
    return Column(
      children: [
        _buildDateField(),
        const SizedBox(height: 20),
        _buildGenderField(),
        const SizedBox(height: 20),
        _buildAddressField(),
        const SizedBox(height: 20),
        _buildCityField(),
        const SizedBox(height: 20),
        _buildBloodGroupField(),
      ],
    );
  }

  Widget _buildFormFieldsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 3,
      children: [
        _buildDateField(),
        _buildGenderField(),
        _buildAddressField(),
        _buildCityField(),
        _buildBloodGroupField(),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Date de naissance *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        TextFormField(
          controller: _birthDateController,
          readOnly: true,
          onTap: () => _selectDate(),
          decoration: InputDecoration(
            hintText: 'JJ/MM/AAAA',
            prefixIcon: Container(
              width: 56,
              alignment: Alignment.center,
              child: Icon(
                Icons.calendar_today_rounded,
                color: AppTheme.primaryColor,
              ),
            ),
            suffixIcon: Container(
              width: 56,
              alignment: Alignment.center,
              child: Icon(
                Icons.expand_more_rounded,
                color: AppTheme.greyColor,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ce champ est requis';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Genre *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: InputDecoration(
            hintText: 'Sélectionner',
            prefixIcon: Container(
              width: 56,
              alignment: Alignment.center,
              child: Icon(
                Icons.person_outline_rounded,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          items: _genders.map((gender) {
            return DropdownMenuItem(
              value: gender,
              child: Text(
                gender,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textColor,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedGender = value);
          },
          validator: (value) {
            if (value == null) {
              return 'Veuillez sélectionner votre genre';
            }
            return null;
          },
          dropdownColor: Colors.white,
          icon: Icon(Icons.expand_more_rounded, color: AppTheme.greyColor),
          borderRadius: BorderRadius.circular(12),
        ),
      ],
    );
  }

  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Adresse *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            hintText: 'Votre adresse complète',
            prefixIcon: Container(
              width: 56,
              alignment: Alignment.center,
              child: Icon(
                Icons.home_outlined,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ce champ est requis';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Ville *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        TextFormField(
          controller: _cityController,
          decoration: InputDecoration(
            hintText: 'Votre ville',
            prefixIcon: Container(
              width: 56,
              alignment: Alignment.center,
              child: Icon(
                Icons.location_city_rounded,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ce champ est requis';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBloodGroupField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Groupe sanguin',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: _selectedBloodGroup,
          decoration: InputDecoration(
            hintText: 'Sélectionner',
            prefixIcon: Container(
              width: 56,
              alignment: Alignment.center,
              child: Icon(
                Icons.bloodtype_outlined,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          items: _bloodGroups.map((group) {
            return DropdownMenuItem(
              value: group,
              child: Text(
                group,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textColor,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedBloodGroup = value);
          },
          dropdownColor: Colors.white,
          icon: Icon(Icons.expand_more_rounded, color: AppTheme.greyColor),
          borderRadius: BorderRadius.circular(12),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return isSmallScreen
        ? Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeProfile,
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
                      : Text(
                          'Terminer mon profil',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _skipForNow,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                  child: Text(
                    'Compléter plus tard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _skipForNow,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    child: Text(
                      'Compléter plus tard',
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
                    onPressed: _isLoading ? null : _completeProfile,
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
                        : Text(
                            'Terminer mon profil',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textColor,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    
    if (date != null) {
      setState(() {
        _selectedBirthDate = date;
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(date);
      });
    }
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
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

      await _db.collection('users').doc(widget.userId).update(updates);
      await _db.collection('patients').doc(widget.userId).update(updates);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Une erreur est survenue. Veuillez réessayer.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _skipForNow() async {
    setState(() => _isLoading = true);

    try {
      await _db.collection('users').doc(widget.userId).update({
        'profileCompleted': false,
        'hasSkippedProfile': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

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
}