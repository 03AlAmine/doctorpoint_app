// lib/presentation/pages/patient/appointments_page.dart
import 'package:doctorpoint/services/patient_appointment_service.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;
  final PatientAppointmentService _appointmentService =
      PatientAppointmentService();
  List<Map<String, dynamic>> _upcomingAppointments = [];
  List<Map<String, dynamic>> _pastAppointments = [];
  List<Map<String, dynamic>> _cancelledAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);

    try {
      final [upcoming, past, cancelled] = await Future.wait([
        _appointmentService.getUpcomingAppointments(),
        _appointmentService.getPastAppointments(),
        _getCancelledAppointments(),
      ]);

      setState(() {
        _upcomingAppointments = upcoming;
        _pastAppointments = past;
        _cancelledAppointments = cancelled;
      });
    } catch (e) {
      print('Erreur chargement rendez-vous: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _getCancelledAppointments() async {
    try {
      final appointments = await _appointmentService.getPastAppointments();
      return appointments.where((app) => app['status'] == 'cancelled').toList();
    } catch (e) {
      print('Erreur récupération rendez-vous annulés: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> get _filteredAppointments {
    switch (_currentTabIndex) {
      case 0: // À venir
        return _upcomingAppointments
            .where((app) =>
                app['status'] == 'pending' || app['status'] == 'confirmed')
            .toList();
      case 1: // Passés
        return _pastAppointments
            .where((app) => app['status'] == 'completed')
            .toList();
      case 2: // Annulés
        return _cancelledAppointments;
      default:
        return [];
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _buildCancellationDialog(),
    );

    if (result != null) {
      final cancelResult = await _appointmentService.cancelAppointment(
        appointmentId: appointmentId,
        reason: result,
      );

      if (cancelResult['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous annulé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadAppointments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${cancelResult['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCancellationDialog() {
    final TextEditingController reasonController = TextEditingController();

    return AlertDialog(
      title: const Text('Annuler le rendez-vous'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Veuillez indiquer la raison de l\'annulation:'),
          const SizedBox(height: 16),
          TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Raison de l\'annulation...',
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
          onPressed: () => Navigator.pop(context, reasonController.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Confirmer'),
        ),
      ],
    );
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
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // Naviguer vers la recherche de médecins
              },
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildUpcomingAppointments(bool isSmallScreen) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        itemCount: upcoming.length,
        itemBuilder: (context, index) {
          final appointment = upcoming[index];
          final doctor = appointment['doctor'] as Doctor?;

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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
        final doctor = appointment['doctor'] as Doctor?;

        return _buildPastAppointmentCard(
          appointment: appointment,
          doctor: doctor,
          isSmallScreen: isSmallScreen,
        );
      },
    );
  }

  Widget _buildCancelledAppointments(bool isSmallScreen) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
        final doctor = appointment['doctor'] as Doctor?;

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
    required Doctor? doctor,
    required bool isSmallScreen,
  }) {
    final dateStr = appointment['date'] as String;
    final dateParts = dateStr.split('-');
    final date = dateParts.length == 3
        ? DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]),
            int.parse(dateParts[2]))
        : DateTime.now();

    final isToday = _isToday(date);
    final status = appointment['status'] as String? ?? 'pending';
    final paymentStatus = appointment['paymentStatus'] as String? ?? 'pending';

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
              color: isToday
                  ? Colors.orange.shade50
                  : AppTheme.primaryColor.withOpacity(0.1),
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
                    color: isToday
                        ? Colors.orange.shade800
                        : AppTheme.primaryColor,
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
                if (doctor != null) ...[
                  // Informations du médecin
                  Row(
                    children: [
                      // Photo du médecin
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(isSmallScreen ? 10 : 12),
                        child: Container(
                          width: isSmallScreen ? 60 : 70,
                          height: isSmallScreen ? 60 : 70,
                          color: AppTheme.lightGrey,
                          child: doctor.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: doctor.imageUrl,
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  Icons.person,
                                  size: isSmallScreen ? 24 : 30,
                                  color: Colors.white,
                                ),
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
                ],

                // Détails du rendez-vous
                _buildDetailRow(
                  'Heure:',
                  appointment['time'] as String? ?? '',
                  Icons.access_time,
                  isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),

                _buildDetailRow(
                  'Type:',
                  appointment['type'] as String? ?? 'Présentiel',
                  _getConsultationTypeIcon(
                      appointment['type'] as String? ?? 'Présentiel'),
                  isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),

                _buildDetailRow(
                  'Motif:',
                  appointment['reason'] as String? ?? 'Consultation',
                  Icons.info_outline,
                  isSmallScreen,
                ),

                SizedBox(height: isSmallScreen ? 12 : 16),

                // Statut
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        color: _getStatusColor(status),
                        size: isSmallScreen ? 16 : 18,
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Expanded(
                        child: Text(
                          _getStatusText(status),
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${appointment['amount']?.toStringAsFixed(0)}€',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Boutons d'action
                if (status == 'pending' || status == 'confirmed') ...[
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Reprogrammer
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.primaryColor),
                          ),
                          child: Text('Reprogrammer'),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _cancelAppointment(appointment['id'] as String),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red,
                          ),
                          child: Text('Annuler'),
                        ),
                      ),
                    ],
                  ),
                ],

                // Paiement en attente
                if (paymentStatus == 'pending')
                  Container(
                    margin: EdgeInsets.only(top: isSmallScreen ? 12 : 16),
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius:
                          BorderRadius.circular(isSmallScreen ? 8 : 12),
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
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Payer
                          },
                          child: Text(
                            'Payer',
                            style: TextStyle(
                              color: Colors.amber.shade800,
                              fontWeight: FontWeight.w600,
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
    required Doctor? doctor,
    required bool isSmallScreen,
  }) {
    final dateStr = appointment['date'] as String;
    final dateParts = dateStr.split('-');
    final date = dateParts.length == 3
        ? DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]),
            int.parse(dateParts[2]))
        : DateTime.now();

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
                if (doctor != null) ...[
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(isSmallScreen ? 10 : 12),
                        child: Container(
                          width: isSmallScreen ? 50 : 60,
                          height: isSmallScreen ? 50 : 60,
                          color: AppTheme.lightGrey,
                          child: doctor.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: doctor.imageUrl,
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  Icons.person,
                                  size: isSmallScreen ? 24 : 30,
                                  color: Colors.white,
                                ),
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
                            SizedBox(height: isSmallScreen ? 2 : 4),
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
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                ],
                _buildDetailRow(
                  'Heure:',
                  appointment['time'] as String? ?? '',
                  Icons.access_time,
                  isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                _buildDetailRow(
                  'Type:',
                  appointment['type'] as String? ?? 'Présentiel',
                  _getConsultationTypeIcon(
                      appointment['type'] as String? ?? 'Présentiel'),
                  isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                ElevatedButton(
                  onPressed: () {
                    // Noter la consultation
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    minimumSize: Size(double.infinity, isSmallScreen ? 44 : 48),
                  ),
                  child: Text('Noter la consultation'),
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
    required Doctor? doctor,
    required bool isSmallScreen,
  }) {
    final dateStr = appointment['date'] as String;
    final dateParts = dateStr.split('-');
    final date = dateParts.length == 3
        ? DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]),
            int.parse(dateParts[2]))
        : DateTime.now();

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
                if (doctor != null) ...[
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(isSmallScreen ? 10 : 12),
                        child: Container(
                          width: isSmallScreen ? 50 : 60,
                          height: isSmallScreen ? 50 : 60,
                          color: AppTheme.lightGrey,
                          child: doctor.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: doctor.imageUrl,
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  Icons.person,
                                  size: isSmallScreen ? 24 : 30,
                                  color: Colors.white,
                                ),
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
                            SizedBox(height: isSmallScreen ? 2 : 4),
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
                ],
                _buildDetailRow(
                  'Heure prévue:',
                  appointment['time'] as String? ?? '',
                  Icons.access_time,
                  isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                _buildDetailRow(
                  'Type:',
                  appointment['type'] as String? ?? 'Présentiel',
                  _getConsultationTypeIcon(
                      appointment['type'] as String? ?? 'Présentiel'),
                  isSmallScreen,
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
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: AppTheme.greyColor,
              ),
            ),
            SizedBox(height: isSmallScreen ? 24 : 32),
            ElevatedButton(
              onPressed: () {
                // Naviguer vers la page de recherche de médecins
                Navigator.pushNamed(context, '/search');

                // OU si vous avez une page de recherche directe:
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => SearchPage(),
                //   ),
                // );
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
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, IconData icon, bool isSmallScreen) {
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  IconData _getConsultationTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'vidéo':
        return Icons.videocam;
      case 'audio':
        return Icons.call;
      default:
        return Icons.person;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.access_time;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmé';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return 'En attente';
    }
  }
}
