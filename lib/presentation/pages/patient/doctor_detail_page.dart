import 'package:doctorpoint/presentation/pages/patient/book_appointment_page.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:doctorpoint/core/providers/doctor_provider.dart';

class DoctorDetailPage extends StatefulWidget {
  final Doctor doctor;

  const DoctorDetailPage({
    super.key,
    required this.doctor,
  });

  @override
  State<DoctorDetailPage> createState() => _DoctorDetailPageState();
}

class _DoctorDetailPageState extends State<DoctorDetailPage> {
  int _selectedTimeSlot = 0;
  DateTime _selectedDate = DateTime.now();
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  final List<String> _doctorImages = [
    'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d',
    'https://images.unsplash.com/photo-1559839734-2b71ea197ec2',
    'https://images.unsplash.com/photo-1537368910025-700350fe46c7',
  ];

  final List<Map<String, dynamic>> _timeSlots = [
    {'time': '09:00 AM - 10:00 AM', 'isAvailable': true},
    {'time': '10:00 AM - 11:00 AM', 'isAvailable': true},
    {'time': '11:00 AM - 12:00 PM', 'isAvailable': false},
    {'time': '02:00 PM - 03:00 PM', 'isAvailable': true},
    {'time': '03:00 PM - 04:00 PM', 'isAvailable': true},
    {'time': '04:00 PM - 05:00 PM', 'isAvailable': true},
  ];

  final List<DateTime> _availableDates = List.generate(
    7,
    (index) => DateTime.now().add(Duration(days: index)),
  );



  @override
  Widget build(BuildContext context) {
    final doctorProvider = Provider.of<DoctorProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec photo du médecin
              _buildDoctorHeader(screenWidth, doctorProvider),

              // Contenu principal
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 20,
                  vertical: isSmallScreen ? 12 : 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom et spécialité
                    Text(
                      widget.doctor.name,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 22 : 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 8),
                    Text(
                      '${widget.doctor.specialization} - ${widget.doctor.hospital}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: AppTheme.greyColor,
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 16 : 20),

                    // Statistiques
                    _buildStatsSection(isSmallScreen),

                    SizedBox(height: isSmallScreen ? 20 : 24),

                    // À propos du médecin
                    _buildAboutSection(isSmallScreen),

                    SizedBox(height: isSmallScreen ? 20 : 24),

                    // Horaires de travail
                    _buildWorkingTimeSection(isSmallScreen),

                    SizedBox(height: isSmallScreen ? 20 : 24),

                    // Calendrier
                    _buildCalendarSection(isSmallScreen),

                    SizedBox(height: isSmallScreen ? 20 : 24),

                    // Créneaux horaires
                    _buildTimeSlotsSection(isSmallScreen),

                    SizedBox(height: isSmallScreen ? 40 : 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Bouton de prise de rendez-vous (MODIFIÉ)
      bottomNavigationBar:
          _buildBookAppointmentButton(isSmallScreen, screenWidth),
    );
  }

  Widget _buildDoctorHeader(double screenWidth, DoctorProvider provider) {
    final isSmallScreen = screenWidth < 360;
    final headerHeight = isSmallScreen ? 280.0 : 320.0;

    return Stack(
      children: [
        // Images carousel
        SizedBox(
          height: headerHeight,
          width: double.infinity,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemCount: _doctorImages.length,
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: _doctorImages[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.lightGrey,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.lightGrey,
                  child:
                      const Icon(Icons.person, size: 100, color: Colors.white),
                ),
              );
            },
          ),
        ),

        // Overlay gradient
        Container(
          height: headerHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.5),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.3),
              ],
            ),
          ),
        ),

        // Boutons de navigation
        Positioned(
          top: isSmallScreen ? 12 : 16,
          left: isSmallScreen ? 12 : 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: isSmallScreen ? 36 : 40,
                minHeight: isSmallScreen ? 36 : 40,
              ),
            ),
          ),
        ),

        Positioned(
          top: isSmallScreen ? 12 : 16,
          right: isSmallScreen ? 12 : 16,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    widget.doctor.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: widget.doctor.isFavorite ? Colors.red : Colors.black,
                  ),
                  onPressed: () {
                    provider.toggleFavorite(widget.doctor.id);
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: isSmallScreen ? 36 : 40,
                    minHeight: isSmallScreen ? 36 : 40,
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.black),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: isSmallScreen ? 36 : 40,
                    minHeight: isSmallScreen ? 36 : 40,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Indicateurs de page
        Positioned(
          bottom: isSmallScreen ? 16 : 20,
          right: isSmallScreen ? 16 : 20,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            ),
            child: Text(
              '${_currentImageIndex + 1}/${_doctorImages.length}',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          'Patients',
          '1000+',
          Icons.people_outline,
          isSmallScreen,
        ),
        _buildStatItem(
          'Expérience',
          '${widget.doctor.experience} ans',
          Icons.work_outline,
          isSmallScreen,
        ),
        _buildStatItem(
          'Avis',
          '${widget.doctor.reviews}',
          Icons.star_outline,
          isSmallScreen,
        ),
        _buildStatItem(
          'Tarif',
          '\$${widget.doctor.consultationFee}',
          Icons.attach_money_outlined,
          isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildStatItem(
      String title, String value, IconData icon, bool isSmallScreen) {
    return Column(
      children: [
        Container(
          width: isSmallScreen ? 48 : 56,
          height: isSmallScreen ? 48 : 56,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: isSmallScreen ? 20 : 24,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            color: AppTheme.greyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'À propos du médecin',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Text(
          widget.doctor.description ??
              'Dr. ${widget.doctor.name.split(' ').last} est un spécialiste ${widget.doctor.specialization.toLowerCase()} renommé à ${widget.doctor.hospital}. Avec ${widget.doctor.experience} ans d\'expérience, il/elle a traité plus de 1000 patients et a reçu plusieurs prix pour sa contribution exceptionnelle dans son domaine. Il/elle est disponible pour des consultations privées.',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: Colors.grey[600],
            height: 1.5,
          ),
          textAlign: TextAlign.justify,
        ),

        SizedBox(height: isSmallScreen ? 12 : 16),

        // Langues parlées
        Wrap(
          spacing: isSmallScreen ? 8 : 12,
          runSpacing: isSmallScreen ? 8 : 12,
          children: widget.doctor.languages.map((language) {
            return Chip(
              label: Text(language),
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              labelStyle: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWorkingTimeSection(bool isSmallScreen) {
    final Map<String, dynamic> schedule = widget.doctor.availability ??
        {
          'Lundi': ['09:00', '18:00'],
          'Mardi': ['09:00', '18:00'],
          'Mercredi': ['09:00', '18:00'],
          'Jeudi': ['09:00', '18:00'],
          'Vendredi': ['09:00', '18:00'],
          'Samedi': ['09:00', '14:00'],
          'Dimanche': ['Fermé'],
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horaires de travail',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            border: Border.all(color: AppTheme.lightGrey),
          ),
          child: Column(
            children: schedule.entries.map((entry) {
              final isClosed = entry.value[0] == 'Fermé';
              return Padding(
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: AppTheme.textColor,
                      ),
                    ),
                    Text(
                      isClosed
                          ? 'Fermé'
                          : '${entry.value[0]} - ${entry.value[1]}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: isClosed ? Colors.red : AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calendrier',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        SizedBox(
          height: isSmallScreen ? 100 : 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _availableDates.length,
            itemBuilder: (context, index) {
              final date = _availableDates[index];
              final isSelected = _selectedDate.day == date.day;
              final isToday = date.day == DateTime.now().day;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  width: isSmallScreen ? 70 : 80,
                  margin: EdgeInsets.only(
                    right: index == _availableDates.length - 1 ? 0 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                    borderRadius:
                        BorderRadius.circular(isSmallScreen ? 12 : 16),
                    border: Border.all(
                      color: isToday && !isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.lightGrey,
                      width: isToday && !isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(date),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: isSelected ? Colors.white : AppTheme.greyColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 8),
                      Text(
                        DateFormat('dd').format(date),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 24,
                          color: isSelected ? Colors.white : AppTheme.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 8),
                      Text(
                        DateFormat('MMM').format(date),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: isSelected ? Colors.white : AppTheme.greyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotsSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Créneaux horaires disponibles',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        Wrap(
          spacing: isSmallScreen ? 8 : 12,
          runSpacing: isSmallScreen ? 8 : 12,
          children: List.generate(_timeSlots.length, (index) {
            final slot = _timeSlots[index];
            final isSelected = _selectedTimeSlot == index;
            final isAvailable = slot['isAvailable'] as bool;

            return GestureDetector(
              onTap: isAvailable
                  ? () {
                      setState(() {
                        _selectedTimeSlot = index;
                      });
                    }
                  : null,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 20,
                  vertical: isSmallScreen ? 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : isAvailable
                          ? Colors.white
                          : Colors.grey[100],
                  borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : isAvailable
                            ? AppTheme.lightGrey
                            : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  slot['time'] as String,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: isSelected
                        ? Colors.white
                        : isAvailable
                            ? AppTheme.textColor
                            : Colors.grey[400],
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

// Widget _buildBookAppointmentButton corrigé dans DoctorDetailPage.dart
  Widget _buildBookAppointmentButton(bool isSmallScreen, double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: isSmallScreen ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.lightGrey)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tarif de consultation',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: AppTheme.greyColor,
                ),
              ),
              Text(
                '\$${widget.doctor.consultationFee}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // CORRECTION ICI: utiliser widget.doctor au lieu de doctor
                  builder: (context) =>
                      BookAppointmentPage(doctor: widget.doctor),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 24 : 32,
                vertical: isSmallScreen ? 14 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Prendre rendez-vous',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
