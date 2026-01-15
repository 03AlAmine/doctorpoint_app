// ignore_for_file: unused_element, library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctorpoint/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:doctorpoint/presentation/pages/doctor/doctor_agenda_page.dart';
import 'package:doctorpoint/presentation/pages/doctor/doctor_patients_page.dart';
import 'package:doctorpoint/presentation/pages/doctor/doctor_prescriptions_page.dart';
import 'package:doctorpoint/presentation/pages/doctor/doctor_messaging_page.dart';
import 'package:doctorpoint/presentation/pages/doctor/doctor_settings_page.dart';
import 'package:doctorpoint/presentation/pages/doctor/doctor_statistics_page.dart';
import 'package:doctorpoint/presentation/pages/doctor/doctor_documents_page.dart';
import 'package:intl/intl.dart';

class DoctorDashboard extends StatefulWidget {
  final Doctor doctor;

  const DoctorDashboard({super.key, required this.doctor});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isInitialized = false;

  // Pages principales avec leurs widgets
  List<Map<String, dynamic>> get _pages => [
        {
          'title': 'Tableau',
          'icon': Icons.dashboard,
          'page': 'overview',
          'widget': _buildOverviewPage(),
        },
        {
          'title': 'Agenda',
          'icon': Icons.calendar_today,
          'page': 'calendar',
          'widget':
              DoctorAgendaPage(doctor: widget.doctor), // Page agenda améliorée
        },
        {
          'title': 'Patients',
          'icon': Icons.people,
          'page': 'patients',
          'widget': DoctorPatientsPage(doctor: widget.doctor),
        },
        {
          'title': 'Messages',
          'icon': Icons.message,
          'page': 'messaging',
          'widget':
              DoctorMessagingPage(doctor: widget.doctor), // Messagerie complète
        },
      ];

  // Variables pour les données dynamiques
  Map<String, dynamic> _stats = {
    'todayAppointments': 0,
    'totalPatients': 0,
    'pendingAppointments': 0,
    'revenue': 0.0,
  };

  List<Map<String, dynamic>> _recentAppointments = [];
  List<Map<String, dynamic>> _upcomingAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialisation sans accès au context
    _loadDoctorData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializePages();
      _isInitialized = true;
    }
  }

  void _initializePages() {
    // Initialiser les pages ici (après que les dépendances sont disponibles)
    _pages[0]['widget'] = _buildOverviewPage();
    _pages[1]['widget'] = DoctorAgendaPage(doctor: widget.doctor);
    _pages[2]['widget'] = DoctorPatientsPage(doctor: widget.doctor);
    _pages[3]['widget'] = DoctorMessagingPage(doctor: widget.doctor);
    // Charger les données
    _loadStatistics();
    _loadRecentAppointments();
    _loadUpcomingAppointments();
  }

  Future<void> _loadDoctorData() async {
    try {
      final doc = await _db.collection('doctors').doc(widget.doctor.id).get();
      if (doc.exists) {
        // Vous pouvez mettre à jour les données du médecin si nécessaire
      }
    } catch (e) {
      print('Erreur chargement données médecin: $e');
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final today = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(today);

      // 1. Rendez-vous du jour
      final todayAppointmentsSnapshot = await _db
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctor.id)
          .where('date', isEqualTo: todayStr)
          .where('status', whereIn: ['confirmed', 'scheduled']).get();

      // 2. Nombre total de patients (patients uniques)
      final appointmentsSnapshot = await _db
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctor.id)
          .get();

      final uniquePatients = <String>{};
      for (var appointment in appointmentsSnapshot.docs) {
        final patientId = appointment['patientId'];
        if (patientId != null && patientId.toString().isNotEmpty) {
          uniquePatients.add(patientId.toString());
        }
      }

      // 3. Rendez-vous en attente
      final pendingSnapshot = await _db
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctor.id)
          .where('status', isEqualTo: 'pending')
          .get();

      // 4. Revenus du mois
      final firstDayOfMonth = DateTime(today.year, today.month, 1);
      final lastDayOfMonth = DateTime(today.year, today.month + 1, 0);
      final firstDayStr = DateFormat('yyyy-MM-dd').format(firstDayOfMonth);
      final lastDayStr = DateFormat('yyyy-MM-dd').format(lastDayOfMonth);

      final revenueSnapshot = await _db
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctor.id)
          .where('date', isGreaterThanOrEqualTo: firstDayStr)
          .where('date', isLessThanOrEqualTo: lastDayStr)
          .where('status', isEqualTo: 'completed')
          .get();

      double monthlyRevenue = 0.0;
      for (var appointment in revenueSnapshot.docs) {
        final fee = appointment['fee'] ?? widget.doctor.consultationFee;
        monthlyRevenue += (fee is num ? fee.toDouble() : 0.0);
      }

      if (mounted) {
        setState(() {
          _stats = {
            'todayAppointments': todayAppointmentsSnapshot.size,
            'totalPatients': uniquePatients.length,
            'pendingAppointments': pendingSnapshot.size,
            'revenue': monthlyRevenue,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur chargement statistiques: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadRecentAppointments() async {
    try {
      final snapshot = await _db
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctor.id)
          .orderBy('date', descending: true)
          .orderBy('time', descending: true)
          .limit(5)
          .get();

      final appointments = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();

// Récupérer les informations du patient
        final patientId = data['patientId'];
        String patientName = 'Patient';
        if (patientId != null) {
          // CORRECTION: Chercher dans 'users' au lieu de 'patients'
          final userDoc =
              await _db.collection('users').doc(patientId.toString()).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            patientName = userData['fullName'] as String? ?? 'Patient';
          }
        }

        appointments.add({
          'id': doc.id,
          'patientName': patientName,
          'date': data['date'] ?? '',
          'time': data['time'] ?? '',
          'type': data['type'] ?? 'Présentiel',
          'status': data['status'] ?? 'Confirmé',
          'reason': data['reason'] ?? 'Consultation',
        });
      }

      if (mounted) {
        setState(() {
          _recentAppointments = appointments;
        });
      }
    } catch (e) {
      print('Erreur chargement rendez-vous récents: $e');
    }
  }

  Future<void> _loadUpcomingAppointments() async {
    try {
      final today = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(today);

      final snapshot = await _db
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctor.id)
          .where('date', isGreaterThanOrEqualTo: todayStr)
          .where('status', whereIn: ['scheduled', 'confirmed'])
          .orderBy('date')
          .orderBy('time')
          .limit(5)
          .get();

      final appointments = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final patientId = data['patientId'];
        String patientName = 'Patient';
        if (patientId != null) {
          final userDoc =
              await _db.collection('patients').doc(patientId.toString()).get();
          if (userDoc.exists) {
            patientName = userDoc['fullName'] ?? 'Patient';
          }
        }

        appointments.add({
          'id': doc.id,
          'patientName': patientName,
          'date': data['date'] ?? '',
          'time': data['time'] ?? '',
          'type': data['type'] ?? 'Présentiel',
          'status': data['status'] ?? 'Programmé',
        });
      }

      if (mounted) {
        setState(() {
          _upcomingAppointments = appointments;
        });
      }
    } catch (e) {
      print('Erreur chargement rendez-vous à venir: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToExtraPage(String page) {
    Widget pageWidget;

    switch (page) {
      case 'prescriptions':
        pageWidget = const DoctorPrescriptionsPage();
        break;
      case 'statistics':
        pageWidget = const DoctorStatisticsPage();
        break;
      case 'documents':
        pageWidget = DoctorDocumentsPage(doctorId: widget.doctor.id);
        break;
      case 'settings':
        pageWidget = DoctorSettingsPage(doctor: widget.doctor);
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => pageWidget),
    );
  }

  Widget _buildOverviewPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = MediaQuery.of(context).size;
        final isMobile = screenSize.width < 600;
        final isTablet = screenSize.width >= 600 && screenSize.width < 1200;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec bienvenue
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: isMobile ? 30 : 40,
                      backgroundColor: Colors.white,
                      backgroundImage: widget.doctor.imageUrl.isNotEmpty
                          ? NetworkImage(widget.doctor.imageUrl)
                          : null,
                      child: widget.doctor.imageUrl.isEmpty
                          ? Icon(
                              Icons.person,
                              size: isMobile ? 30 : 40,
                              color: AppTheme.primaryColor,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour, Dr. ${widget.doctor.name.split(' ').last}',
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.doctor.specialization,
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.doctor.hospital,
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Statistiques en temps réel
              Text(
                'Aujourd\'hui',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 2 : 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) => Container(
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else
                _buildStatsGrid(isMobile),

              const SizedBox(height: 40),

              // Prochains rendez-vous
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Prochains rendez-vous',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 1; // Naviguer vers Agenda
                      });
                    },
                    child: Text(
                      'Voir l\'agenda',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_upcomingAppointments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 48,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun rendez-vous à venir',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vos prochains rendez-vous apparaîtront ici',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildUpcomingAppointmentsList(isMobile),

              const SizedBox(height: 40),

              // Actions rapides
              Text(
                'Actions rapides',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildQuickActionsGrid(isMobile, isTablet),

              const SizedBox(height: 40),

              // Activité récente
              Text(
                'Activité récente',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 16),

              if (_recentAppointments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'Aucune activité récente',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                _buildRecentActivityList(isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(bool isMobile) {
    final stats = [
      {
        'title': 'RDV Aujourd\'hui',
        'value': _stats['todayAppointments'].toString(),
        'icon': Icons.calendar_today,
        'color': Colors.blue,
        'gradient': LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
      },
      {
        'title': 'Patients',
        'value': _stats['totalPatients'].toString(),
        'icon': Icons.people,
        'color': Colors.green,
        'gradient': LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
      },
      {
        'title': 'En attente',
        'value': _stats['pendingAppointments'].toString(),
        'icon': Icons.access_time,
        'color': Colors.orange,
        'gradient': LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
        ),
      },
      {
        'title': 'Revenus',
        'value': '€${_stats['revenue'].toStringAsFixed(0)}',
        'icon': Icons.euro,
        'color': Colors.purple,
        'gradient': LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade600],
        ),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return _buildStatCard(stats[index], isMobile);
      },
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: stat['gradient'] as Gradient,
        boxShadow: [
          BoxShadow(
            color: stat['color'].withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                stat['icon'] as IconData,
                color: Colors.white,
                size: 22,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat['value'].toString(),
                  style: TextStyle(
                    fontSize: isMobile ? 22 : 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['title'].toString(),
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointmentsList(bool isMobile) {
    return Column(
      children: _upcomingAppointments.map((appointment) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.borderColor.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowColor.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(
                appointment['type'] == 'Vidéo'
                    ? Icons.videocam
                    : appointment['type'] == 'Audio'
                        ? Icons.call
                        : Icons.person,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            title: Text(
              appointment['patientName'],
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${appointment['date']} • ${appointment['time']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  appointment['type'],
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: appointment['status'] == 'Confirmé'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                appointment['status'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: appointment['status'] == 'Confirmé'
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActionsGrid(bool isMobile, bool isTablet) {
    final actions = [
      {
        'title': 'Voir agenda',
        'icon': Icons.calendar_month,
        'color': Colors.blue,
        'action': () {
          setState(() {
            _selectedIndex = 1; // Naviguer vers Agenda
          });
        },
      },
      {
        'title': 'Mes patients',
        'icon': Icons.group,
        'color': Colors.green,
        'action': () {
          setState(() {
            _selectedIndex = 2; // Naviguer vers Patients
          });
        },
      },
      {
        'title': 'Prescriptions',
        'icon': Icons.medication,
        'color': Colors.orange,
        'action': () {
          _navigateToExtraPage('prescriptions');
        },
      },
      {
        'title': 'Documents',
        'icon': Icons.description,
        'color': Colors.purple,
        'action': () {
          _navigateToExtraPage('documents');
        },
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile
            ? 2
            : isTablet
                ? 2
                : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isMobile ? 1.1 : 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        return _buildActionCard(actions[index], isMobile);
      },
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: action['action'] as Function(),
          borderRadius: BorderRadius.circular(16),
          splashColor: action['color'].withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        action['color'].withOpacity(0.1),
                        action['color'].withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    action['icon'] as IconData,
                    color: action['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  action['title'].toString(),
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityList(bool isMobile) {
    return Column(
      children: _recentAppointments.map((appointment) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.lightGrey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                radius: 20,
                child: Icon(
                  Icons.calendar_today,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment['patientName'],
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appointment['reason'],
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: AppTheme.textSecondary,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${appointment['date']} • ${appointment['time']}',
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 11,
                        color: AppTheme.textSecondary.withOpacity(0.7),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: appointment['status'] == 'Completed'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appointment['status'],
                  style: TextStyle(
                    fontSize: 10,
                    color: appointment['status'] == 'Completed'
                        ? Colors.green
                        : Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCurrentPage() {
    // Vérifier si les pages sont initialisées
    if (!_isInitialized || _pages[0]['widget'] == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Retourne le widget de la page sélectionnée
    return _pages[_selectedIndex]['widget'] as Widget;
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      // Montrer un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      );

      // Effectuer la déconnexion
      final authService = AuthService();
      await authService.signOut();

      // Fermer l'indicateur de chargement
      Navigator.pop(context);

      // Rediriger vers la page de connexion
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      // Fermer l'indicateur de chargement en cas d'erreur
      Navigator.pop(context);

      // Afficher l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de déconnexion: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pages[_selectedIndex]['title'] as String,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: false,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications - À implémenter'),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _performLogout(context);
              } else {
                _navigateToExtraPage(value);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'prescriptions',
                child: Row(
                  children: [
                    Icon(
                      Icons.medical_services,
                      color: Colors.blue,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text('Prescriptions'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'statistics',
                child: Row(
                  children: [
                    Icon(
                      Icons.bar_chart,
                      color: Colors.green,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text('Statistiques'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'documents',
                child: Row(
                  children: [
                    Icon(
                      Icons.description,
                      color: Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text('Documents'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(
                      Icons.settings,
                      color: Colors.grey,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text('Paramètres'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Déconnexion',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor.withOpacity(0.3),
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: _buildCurrentPage(),
      ),
      bottomNavigationBar: isMobile
          ? Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppTheme.borderColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.white,
                  selectedItemColor: AppTheme.primaryColor,
                  unselectedItemColor: AppTheme.textSecondary.withOpacity(0.6),
                  selectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  elevation: 8,
                  items: _pages.map((page) {
                    return BottomNavigationBarItem(
                      icon: Icon(page['icon'] as IconData),
                      label: page['title'] as String,
                    );
                  }).toList(),
                  onTap: _onItemTapped,
                ),
              ),
            )
          : null,
    );
  }
}
