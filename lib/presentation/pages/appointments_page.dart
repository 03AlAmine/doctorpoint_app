import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  final List<Map<String, dynamic>> _appointments = [
    {
      'id': '1',
      'doctor': Doctor(
        id: '1',
        name: 'Dr. Sarah Johnson',
        specialization: 'Cardiologue',
        rating: 4.8,
        reviews: 120,
        experience: 10,
        hospital: 'Hôpital Saint-Louis',
        department: 'Cardiologie',
        imageUrl: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d',
        isFavorite: true,
        consultationFee: 80.0,
        languages: ['Français', 'Anglais', 'Espagnol'],
      ),
      'date': DateTime.now().add(const Duration(days: 2)),
      'time': '10:00 AM - 11:00 AM',
      'type': 'video',
      'status': 'upcoming',
      'reason': 'Consultation de suivi',
      'symptoms': 'Douleurs thoraciques occasionnelles',
      'price': 85.00,
      'paymentStatus': 'paid',
      'meetingLink': 'https://meet.doctopoint.com/abc123',
    },
    {
      'id': '2',
      'doctor': Doctor(
        id: '3',
        name: 'Dr. Emma Wilson',
        specialization: 'Pédiatre',
        rating: 4.7,
        reviews: 156,
        experience: 12,
        hospital: 'Hôpital Necker',
        department: 'Pédiatrie',
        imageUrl: 'https://images.unsplash.com/photo-1594824434340-7e7dfc37cabb',
        isFavorite: true,
        consultationFee: 65.0,
        languages: ['Français', 'Anglais'],
      ),
      'date': DateTime.now().add(const Duration(hours: 5)),
      'time': '15:30 PM - 16:30 PM',
      'type': 'in_person',
      'status': 'upcoming',
      'reason': 'Vaccination',
      'symptoms': '',
      'price': 65.00,
      'paymentStatus': 'pending',
      'address': '123 Rue de la Santé, Paris',
    },
    {
      'id': '3',
      'doctor': Doctor(
        id: '2',
        name: 'Dr. Michael Chen',
        specialization: 'Dermatologue',
        rating: 4.9,
        reviews: 89,
        experience: 8,
        hospital: 'Clinique du Marais',
        department: 'Dermatologie',
        imageUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2',
        isFavorite: false,
        consultationFee: 70.0,
        languages: ['Français', 'Chinois'],
      ),
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'time': '14:00 PM - 15:00 PM',
      'type': 'video',
      'status': 'completed',
      'reason': 'Examen de la peau',
      'symptoms': 'Éruption cutanée sur le bras',
      'price': 70.00,
      'paymentStatus': 'paid',
      'rating': 5.0,
      'review': 'Très professionnel, diagnostic clair.',
    },
    {
      'id': '4',
      'doctor': Doctor(
        id: '5',
        name: 'Dr. Sophie Martin',
        specialization: 'Dentiste',
        rating: 4.8,
        reviews: 112,
        experience: 7,
        hospital: 'Centre Dentaire Paris',
        department: 'Dentisterie',
        imageUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2',
        isFavorite: true,
        consultationFee: 60.0,
        languages: ['Français', 'Anglais', 'Allemand'],
      ),
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'time': '11:00 AM - 12:00 PM',
      'type': 'in_person',
      'status': 'completed',
      'reason': 'Nettoyage dentaire',
      'symptoms': 'Saignement des gencives',
      'price': 60.00,
      'paymentStatus': 'paid',
      'rating': 4.0,
    },
    {
      'id': '5',
      'doctor': Doctor(
        id: '4',
        name: 'Dr. James Rodriguez',
        specialization: 'Neurologue',
        rating: 4.6,
        reviews: 95,
        experience: 15,
        hospital: 'Hôpital de la Pitié-Salpêtrière',
        department: 'Neurologie',
        imageUrl: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d',
        isFavorite: false,
        consultationFee: 90.0,
        languages: ['Français', 'Espagnol'],
      ),
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'time': '09:00 AM - 10:00 AM',
      'type': 'audio',
      'status': 'cancelled',
      'reason': 'Consultation générale',
      'symptoms': 'Maux de tête persistants',
      'price': 90.00,
      'paymentStatus': 'refunded',
      'cancellationReason': 'Maladie du médecin',
    },
    {
      'id': '6',
      'doctor': Doctor(
        id: '7',
        name: 'Dr. Marie Dubois',
        specialization: 'Gynécologue',
        rating: 4.9,
        reviews: 134,
        experience: 11,
        hospital: 'Hôpital Saint-Vincent',
        department: 'Gynécologie',
        imageUrl: 'https://images.unsplash.com/photo-1594824434340-7e7dfc37cabb',
        isFavorite: true,
        consultationFee: 85.0,
        languages: ['Français', 'Arabe'],
      ),
      'date': DateTime.now().add(const Duration(days: 5)),
      'time': '16:00 PM - 17:00 PM',
      'type': 'video',
      'status': 'upcoming',
      'reason': 'Suivi de grossesse',
      'symptoms': '',
      'price': 85.00,
      'paymentStatus': 'paid',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredAppointments {
    switch (_currentTabIndex) {
      case 0: // À venir
        return _appointments.where((app) => app['status'] == 'upcoming').toList();
      case 1: // Passés
        return _appointments.where((app) => app['status'] == 'completed').toList();
      case 2: // Annulés
        return _appointments.where((app) => app['status'] == 'cancelled').toList();
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mes rendez-vous',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.greyColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'À venir'),
            Tab(text: 'Passés'),
            Tab(text: 'Annulés'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingAppointments(isSmallScreen),
          _buildPastAppointments(isSmallScreen),
          _buildCancelledAppointments(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments(bool isSmallScreen) {
    final upcoming = _filteredAppointments;

    if (upcoming.isEmpty) {
      return _buildEmptyState(
        'Aucun rendez-vous à venir',
        'Prenez votre premier rendez-vous avec un médecin',
        Icons.calendar_today_outlined,
        isSmallScreen,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {});
      },
      child: ListView.builder(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        itemCount: upcoming.length,
        itemBuilder: (context, index) {
          final appointment = upcoming[index];
          final doctor = appointment['doctor'] as Doctor;
          
          return _buildUpcomingAppointmentCard(
            appointment: appointment,
            doctor: doctor,
            isSmallScreen: isSmallScreen,
          );
        },
      ),
    );
  }

  Widget _buildPastAppointments(bool isSmallScreen) {
    final past = _filteredAppointments;

    if (past.isEmpty) {
      return _buildEmptyState(
        'Aucun rendez-vous passé',
        'Vos consultations terminées apparaîtront ici',
        Icons.history_outlined,
        isSmallScreen,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      itemCount: past.length,
      itemBuilder: (context, index) {
        final appointment = past[index];
        final doctor = appointment['doctor'] as Doctor;
        
        return _buildPastAppointmentCard(
          appointment: appointment,
          doctor: doctor,
          isSmallScreen: isSmallScreen,
        );
      },
    );
  }

  Widget _buildCancelledAppointments(bool isSmallScreen) {
    final cancelled = _filteredAppointments;

    if (cancelled.isEmpty) {
      return _buildEmptyState(
        'Aucun rendez-vous annulé',
        'Tous vos rendez-vous sont confirmés',
        Icons.cancel_outlined,
        isSmallScreen,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      itemCount: cancelled.length,
      itemBuilder: (context, index) {
        final appointment = cancelled[index];
        final doctor = appointment['doctor'] as Doctor;
        
        return _buildCancelledAppointmentCard(
          appointment: appointment,
          doctor: doctor,
          isSmallScreen: isSmallScreen,
        );
      },
    );
  }

  Widget _buildUpcomingAppointmentCard({
    required Map<String, dynamic> appointment,
    required Doctor doctor,
    required bool isSmallScreen,
  }) {
    final date = appointment['date'] as DateTime;
    final type = appointment['type'] as String;
    final paymentStatus = appointment['paymentStatus'] as String;
    final isToday = _isToday(date);

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec date
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: isToday ? Colors.orange.shade50 : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSmallScreen ? 12 : 16),
                topRight: Radius.circular(isSmallScreen ? 12 : 16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(date),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: isToday ? Colors.orange.shade800 : AppTheme.primaryColor,
                  ),
                ),
                if (isToday)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12,
                      vertical: isSmallScreen ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Aujourd'hui",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations du médecin
                Row(
                  children: [
                    // Photo du médecin
                    ClipRRect(
                      borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                      child: Container(
                        width: isSmallScreen ? 60 : 70,
                        height: isSmallScreen ? 60 : 70,
                        color: AppTheme.lightGrey,
                        child: doctor.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: doctor.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppTheme.lightGrey,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppTheme.primaryColor),
                                    ),
                                  ),
                                ),
                              )
                            : const Icon(Icons.person, size: 30, color: Colors.white),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctor.name,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 2 : 4),
                          Text(
                            doctor.specialization,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 2 : 4),
                          Text(
                            doctor.hospital,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: AppTheme.greyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 12 : 16),

                // Détails du rendez-vous
                _buildDetailRow(
                  'Heure:',
                  appointment['time'] as String,
                  Icons.access_time,
                  isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),

                _buildDetailRow(
                  'Type:',
                  _getConsultationTypeLabel(type),
                  _getConsultationTypeIcon(type),
                  isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),

                _buildDetailRow(
                  'Motif:',
                  appointment['reason'] as String,
                  Icons.info_outline,
                  isSmallScreen,
                ),

                if (appointment['symptoms'] != null &&
                    (appointment['symptoms'] as String).isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: isSmallScreen ? 8 : 12),
                    child: _buildDetailRow(
                      'Symptômes:',
                      appointment['symptoms'] as String,
                      Icons.health_and_safety_outlined,
                      isSmallScreen,
                    ),
                  ),

                SizedBox(height: isSmallScreen ? 12 : 16),

                // Boutons d'action
                if (type == 'video' && appointment['meetingLink'] != null)
                  _buildActionButton(
                    'Rejoindre la consultation',
                    Icons.videocam,
                    Colors.green,
                    () {
                      _joinVideoConsultation(appointment['meetingLink'] as String);
                    },
                    isSmallScreen,
                  ),

                if (type == 'in_person' && appointment['address'] != null)
                  _buildActionButton(
                    'Voir l\'adresse',
                    Icons.location_on,
                    AppTheme.primaryColor,
                    () {
                      _showAddress(appointment['address'] as String);
                    },
                    isSmallScreen,
                  ),

                SizedBox(height: isSmallScreen ? 8 : 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _rescheduleAppointment(appointment);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.primaryColor),
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                        ),
                        child: Text(
                          'Reprogrammer',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _cancelAppointment(appointment);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                        ),
                        child: Text(
                          'Annuler',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Statut de paiement
                if (paymentStatus == 'pending')
                  Container(
                    margin: EdgeInsets.only(top: isSmallScreen ? 12 : 16),
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.payment,
                          color: Colors.amber.shade800,
                          size: isSmallScreen ? 16 : 18,
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Expanded(
                          child: Text(
                            'Paiement en attente',
                            style: TextStyle(
                              color: Colors.amber.shade800,
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _processPayment(appointment);
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            'Payer maintenant',
                            style: TextStyle(
                              color: Colors.amber.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastAppointmentCard({
    required Map<String, dynamic> appointment,
    required Doctor doctor,
    required bool isSmallScreen,
  }) {
    final date = appointment['date'] as DateTime;
    final rating = appointment['rating'] as double?;

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSmallScreen ? 12 : 16),
                topRight: Radius.circular(isSmallScreen ? 12 : 16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMMM yyyy', 'fr_FR').format(date),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: isSmallScreen ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Terminé',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations du médecin
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                      child: Container(
                        width: isSmallScreen ? 50 : 60,
                        height: isSmallScreen ? 50 : 60,
                        color: AppTheme.lightGrey,
                        child: doctor.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: doctor.imageUrl,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.person, size: 24, color: Colors.white),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctor.name,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            doctor.specialization,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (rating != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 12,
                          vertical: isSmallScreen ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: isSmallScreen ? 14 : 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 12 : 16),

                // Détails
                _buildDetailRow(
                  'Heure:',
                  appointment['time'] as String,
                  Icons.access_time,
                  isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),

                _buildDetailRow(
                  'Type:',
                  _getConsultationTypeLabel(appointment['type'] as String),
                  _getConsultationTypeIcon(appointment['type'] as String),
                  isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),

                // Boutons d'action
                if (rating == null)
                  ElevatedButton(
                    onPressed: () {
                      _rateAppointment(appointment);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      minimumSize: Size(double.infinity, isSmallScreen ? 44 : 48),
                    ),
                    child: Text(
                      'Noter la consultation',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                  ),

                if (appointment['review'] != null)
                  Container(
                    margin: EdgeInsets.only(top: isSmallScreen ? 12 : 16),
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Votre avis:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          appointment['review'] as String,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 15,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: isSmallScreen ? 8 : 12),

                ElevatedButton(
                  onPressed: () {
                    _bookAgain(doctor);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(color: AppTheme.primaryColor),
                    minimumSize: Size(double.infinity, isSmallScreen ? 44 : 48),
                  ),
                  child: Text(
                    'Reprendre rendez-vous',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledAppointmentCard({
    required Map<String, dynamic> appointment,
    required Doctor doctor,
    required bool isSmallScreen,
  }) {
    final date = appointment['date'] as DateTime;
    final cancellationReason = appointment['cancellationReason'] as String?;

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date et statut
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSmallScreen ? 12 : 16),
                topRight: Radius.circular(isSmallScreen ? 12 : 16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMMM yyyy', 'fr_FR').format(date),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: isSmallScreen ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Annulé',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations du médecin
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                      child: Container(
                        width: isSmallScreen ? 50 : 60,
                        height: isSmallScreen ? 50 : 60,
                        color: AppTheme.lightGrey,
                        child: doctor.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: doctor.imageUrl,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.person, size: 24, color: Colors.white),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctor.name,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            doctor.specialization,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: AppTheme.greyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 12 : 16),

                // Détails
                _buildDetailRow(
                  'Heure prévue:',
                  appointment['time'] as String,
                  Icons.access_time,
                  isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),

                _buildDetailRow(
                  'Type:',
                  _getConsultationTypeLabel(appointment['type'] as String),
                  _getConsultationTypeIcon(appointment['type'] as String),
                  isSmallScreen,
                ),

                if (cancellationReason != null)
                  Padding(
                    padding: EdgeInsets.only(top: isSmallScreen ? 8 : 12),
                    child: Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: isSmallScreen ? 18 : 20,
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 16),
                          Expanded(
                            child: Text(
                              'Raison: $cancellationReason',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 15,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                SizedBox(height: isSmallScreen ? 16 : 20),

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _bookAgain(doctor);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.primaryColor),
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 12 : 16,
                          ),
                        ),
                        child: Text(
                          'Reprendre RDV',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _deleteAppointment(appointment);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: Colors.grey.shade700,
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 12 : 16,
                          ),
                        ),
                        child: Text(
                          'Supprimer',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    bool isSmallScreen,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 60 : 80,
            color: AppTheme.lightGrey,
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 24 : 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: AppTheme.greyColor,
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 24 : 32),
          ElevatedButton(
            onPressed: () {
              // Naviguer vers la recherche de médecins
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 32 : 40,
                vertical: isSmallScreen ? 14 : 16,
              ),
            ),
            child: Text(
              'Prendre un rendez-vous',
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

  Widget _buildDetailRow(String label, String value, IconData icon, bool isSmallScreen) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppTheme.greyColor,
          size: isSmallScreen ? 16 : 18,
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: AppTheme.greyColor,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
    bool isSmallScreen,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 20,
          vertical: isSmallScreen ? 12 : 14,
        ),
      ),
      icon: Icon(icon, size: isSmallScreen ? 18 : 20),
      label: Text(
        text,
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getConsultationTypeLabel(String type) {
    switch (type) {
      case 'video':
        return 'Vidéo';
      case 'audio':
        return 'Audio';
      case 'in_person':
        return 'Présentiel';
      default:
        return 'Consultation';
    }
  }

  IconData _getConsultationTypeIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.call;
      case 'in_person':
        return Icons.person;
      default:
        return Icons.medical_services;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // Fonctions d'action
  void _joinVideoConsultation(String meetingLink) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejoindre la consultation'),
        content: const Text('Voulez-vous rejoindre la consultation vidéo maintenant ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Ouvrir le lien de la réunion
            },
            child: const Text('Rejoindre'),
          ),
        ],
      ),
    );
  }

  void _showAddress(String address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adresse du cabinet'),
        content: Text(address),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _rescheduleAppointment(Map<String, dynamic> appointment) {
    // Naviguer vers la page de reprogrammation
  }

  void _cancelAppointment(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le rendez-vous'),
        content: const Text('Êtes-vous sûr de vouloir annuler ce rendez-vous ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                appointment['status'] = 'cancelled';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  void _processPayment(Map<String, dynamic> appointment) {
    // Naviguer vers la page de paiement
  }

  void _rateAppointment(Map<String, dynamic> appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildRatingModal(appointment),
    );
  }

  Widget _buildRatingModal(Map<String, dynamic> appointment) {
    double rating = 0;
    final TextEditingController reviewController = TextEditingController();

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Noter la consultation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: RatingBar.builder(
                  initialRating: rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (newRating) {
                    setState(() {
                      rating = newRating;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Votre avis (optionnel)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reviewController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Partagez votre expérience...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          appointment['rating'] = rating;
                          appointment['review'] = reviewController.text;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Soumettre'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _bookAgain(Doctor doctor) {
    // Naviguer vers la page de réservation avec ce médecin
  }

  void _deleteAppointment(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le rendez-vous'),
        content: const Text('Cette action est irréversible. Continuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _appointments.remove(appointment);
              });
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
}
