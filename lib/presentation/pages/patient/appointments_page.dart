// lib/presentation/pages/patient/appointments_page.dart
// REDESIGN COMPLET - Style cohérent avec doctor_agenda_page + Fix récupération RDV

import 'package:doctorpoint/services/patient_appointment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ==================== MODÈLE STATISTIQUES PATIENT ====================

class PatientAppointmentStats {
  final int total;
  final int upcoming;
  final int completed;
  final int cancelled;
  final int today;

  PatientAppointmentStats({
    required this.total,
    required this.upcoming,
    required this.completed,
    required this.cancelled,
    required this.today,
  });
}

// ==================== PAGE PRINCIPALE ====================

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  // ✅ FIX : On instancie le service APRÈS avoir récupéré le patientId
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _upcomingAppointments = [];
  List<Map<String, dynamic>> _pastAppointments = [];
  List<Map<String, dynamic>> _cancelledAppointments = [];
  bool _isLoading = true;
  String? _patientId;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _initAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ✅ FIX PRINCIPAL : Récupérer le patientId depuis Firebase Auth avant tout
  Future<void> _initAndLoad() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      _patientId = user.uid;
      await _loadAppointments();
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      print('❌ Erreur initialisation: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAppointments() async {
    if (_patientId == null || _patientId!.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // ✅ FIX : Requête directe Firestore avec patientId explicite
      final snapshot = await _db
          .collection('appointments')
          .where('patientId', isEqualTo: _patientId)
          .orderBy('date', descending: false)
          .get();

      final List<Map<String, dynamic>> upcoming = [];
      final List<Map<String, dynamic>> past = [];
      final List<Map<String, dynamic>> cancelled = [];

      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final appointmentData = <String, dynamic>{
          'id': doc.id,
          ...data,
        };

        // Charger le doctor associé
        final doctorId = data['doctorId']?.toString();
        if (doctorId != null && doctorId.isNotEmpty) {
          try {
            final doctorDoc = await _db.collection('doctors').doc(doctorId).get();
            if (doctorDoc.exists) {
              appointmentData['doctor'] = Doctor.fromFirestore(doctorDoc);
            }
          } catch (e) {
            print('❌ Erreur chargement docteur $doctorId: $e');
          }
        }

        // Parser la date
        DateTime? appointmentDate;
        if (data['date'] is Timestamp) {
          appointmentDate = (data['date'] as Timestamp).toDate();
          appointmentData['date'] =
              DateFormat('yyyy-MM-dd').format(appointmentDate);
        } else if (data['date'] is String) {
          try {
            appointmentDate = DateTime.parse(data['date']);
          } catch (_) {
            final parts = (data['date'] as String).split('-');
            if (parts.length == 3) {
              appointmentDate = DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              );
            }
          }
        }

        final status = (data['status'] ?? 'pending').toString().toLowerCase();

        if (status == 'cancelled') {
          cancelled.add(appointmentData);
        } else if (appointmentDate != null &&
            (appointmentDate.isAfter(now) ||
                _isToday(appointmentDate)) &&
            status != 'completed') {
          upcoming.add(appointmentData);
        } else {
          past.add(appointmentData);
        }
      }

      // Trier les à venir par date croissante
      upcoming.sort((a, b) {
        final dateA = _parseDate(a['date']);
        final dateB = _parseDate(b['date']);
        if (dateA == null || dateB == null) return 0;
        return dateA.compareTo(dateB);
      });

      // Trier les passés par date décroissante
      past.sort((a, b) {
        final dateA = _parseDate(a['date']);
        final dateB = _parseDate(b['date']);
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _upcomingAppointments = upcoming;
          _pastAppointments = past;
          _cancelledAppointments = cancelled;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement rendez-vous: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Erreur de chargement: $e');
      }
    }
  }

  PatientAppointmentStats _calculateStats() {
    final now = DateTime.now();
    int todayCount = 0;

    for (final app in _upcomingAppointments) {
      final date = _parseDate(app['date']);
      if (date != null && _isToday(date)) todayCount++;
    }

    return PatientAppointmentStats(
      total: _upcomingAppointments.length +
          _pastAppointments.length +
          _cancelledAppointments.length,
      upcoming: _upcomingAppointments.length,
      completed: _pastAppointments
          .where((a) => a['status'] == 'completed')
          .length,
      cancelled: _cancelledAppointments.length,
      today: todayCount,
    );
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    final TextEditingController reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 40,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cancel_outlined, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Annuler le rendez-vous',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Veuillez indiquer la raison:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Raison de l\'annulation...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Garder'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, reasonController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Annuler le RDV',
                          style: TextStyle(color: Colors.white),
                        ),
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

    if (result != null && mounted) {
      try {
        await _db.collection('appointments').doc(appointmentId).update({
          'status': 'cancelled',
          'cancellationReason': result,
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelledBy': 'patient',
        });

        _showSuccessSnackBar('Rendez-vous annulé avec succès');
        await _loadAppointments();
      } catch (e) {
        _showErrorSnackBar('Erreur lors de l\'annulation: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: _isLoading
            ? _buildLoadingState()
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverHeader(),
                  SliverToBoxAdapter(child: _buildStatsSection()),
                  SliverToBoxAdapter(child: _buildTabBar()),
                  SliverToBoxAdapter(child: _buildContent()),
                ],
              ),
        floatingActionButton: _currentTabIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () => Navigator.pushNamed(context, '/search'),
                backgroundColor: AppTheme.primaryColor,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Nouveau RDV',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement de vos rendez-vous...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_month,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Mes rendez-vous',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
            onPressed: _loadAppointments,
            tooltip: 'Rafraîchir',
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final stats = _calculateStats();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.35),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Aperçu de vos RDV',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Total: ${stats.total}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.today,
                      value: stats.today.toString(),
                      label: "Aujourd'hui",
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.upcoming,
                      value: stats.upcoming.toString(),
                      label: 'À venir',
                      color: Colors.lightBlue.shade100,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.check_circle,
                      value: stats.completed.toString(),
                      label: 'Terminés',
                      color: Colors.green.shade200,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade500,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.upcoming, size: 16),
                const SizedBox(width: 6),
                const Text('À venir'),
                if (_upcomingAppointments.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _currentTabIndex == 0
                          ? Colors.white.withOpacity(0.3)
                          : AppTheme.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _upcomingAppointments.length.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _currentTabIndex == 0
                            ? Colors.white
                            : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 16),
                SizedBox(width: 6),
                Text('Passés'),
              ],
            ),
          ),
          const Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel_outlined, size: 16),
                SizedBox(width: 6),
                Text('Annulés'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    List<Map<String, dynamic>> items;
    switch (_currentTabIndex) {
      case 0:
        items = _upcomingAppointments
            .where((a) =>
                a['status'] == 'pending' || a['status'] == 'confirmed')
            .toList();
        break;
      case 1:
        items = _pastAppointments;
        break;
      case 2:
        items = _cancelledAppointments;
        break;
      default:
        items = [];
    }

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final appointment = items[index];
        final doctor = appointment['doctor'] as Doctor?;
        return _buildAppointmentCard(appointment: appointment, doctor: doctor);
      },
    );
  }

  Widget _buildEmptyState() {
    final configs = [
      {
        'icon': Icons.calendar_today_outlined,
        'title': 'Aucun rendez-vous à venir',
        'subtitle': 'Prenez votre premier rendez-vous avec un médecin',
        'color': AppTheme.primaryColor,
      },
      {
        'icon': Icons.history_outlined,
        'title': 'Aucun rendez-vous passé',
        'subtitle': 'Vos consultations terminées apparaîtront ici',
        'color': Colors.grey,
      },
      {
        'icon': Icons.cancel_outlined,
        'title': 'Aucun rendez-vous annulé',
        'subtitle': 'Tous vos rendez-vous sont confirmés',
        'color': Colors.red,
      },
    ];

    final config = configs[_currentTabIndex];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: (config['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              config['icon'] as IconData,
              size: 42,
              color: (config['color'] as Color).withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            config['title'] as String,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            config['subtitle'] as String,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          if (_currentTabIndex == 0) ...[
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/search'),
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Trouver un médecin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppointmentCard({
    required Map<String, dynamic> appointment,
    required Doctor? doctor,
  }) {
    final dateStr = appointment['date'] as String? ?? '';
    final date = _parseDate(dateStr);
    final isToday = date != null && _isToday(date);
    final status = (appointment['status'] ?? 'pending').toString();
    final type = (appointment['type'] ?? 'Présentiel').toString();

    Color cardAccent;
    switch (status.toLowerCase()) {
      case 'confirmed':
        cardAccent = Colors.green;
        break;
      case 'completed':
        cardAccent = Colors.blue;
        break;
      case 'cancelled':
        cardAccent = Colors.red;
        break;
      default:
        cardAccent = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isToday
                ? AppTheme.primaryColor.withOpacity(0.15)
                : Colors.black.withOpacity(0.06),
            blurRadius: isToday ? 20 : 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: isToday
            ? Border.all(
                color: AppTheme.primaryColor.withOpacity(0.4),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header dégradé ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isToday
                    ? [Colors.orange.shade400, Colors.orange.shade600]
                    : _currentTabIndex == 2
                        ? [Colors.red.shade400, Colors.red.shade600]
                        : _currentTabIndex == 1
                            ? [Colors.grey.shade400, Colors.grey.shade600]
                            : [
                                AppTheme.primaryColor.withOpacity(0.85),
                                AppTheme.primaryColor,
                              ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(type),
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date != null
                            ? DateFormat('EEEE dd MMMM yyyy', 'fr_FR')
                                .format(date)
                            : dateStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (appointment['time'] != null)
                        Text(
                          'à ${appointment['time']}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isToday)
                        const Text(
                          "Aujourd'hui",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        )
                      else
                        Text(
                          _getStatusText(status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Corps de la carte ──
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (doctor != null)
                  _buildDoctorRow(doctor)
                else
                  _buildUnknownDoctor(),

                const SizedBox(height: 16),

                // Détails en grille
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.access_time,
                        label: 'Heure',
                        value: appointment['time'] ?? '--:--',
                        iconColor: AppTheme.primaryColor,
                      ),
                      const Divider(height: 16),
                      _buildInfoRow(
                        icon: _getTypeIcon(type),
                        label: 'Type',
                        value: type,
                        iconColor: Colors.purple,
                      ),
                      if (appointment['reason'] != null &&
                          appointment['reason'].toString().isNotEmpty) ...[
                        const Divider(height: 16),
                        _buildInfoRow(
                          icon: Icons.info_outline,
                          label: 'Motif',
                          value: appointment['reason'].toString(),
                          iconColor: Colors.orange,
                        ),
                      ],
                      if (appointment['duration'] != null) ...[
                        const Divider(height: 16),
                        _buildInfoRow(
                          icon: Icons.timer_outlined,
                          label: 'Durée',
                          value: '${appointment['duration']} minutes',
                          iconColor: Colors.teal,
                        ),
                      ],
                    ],
                  ),
                ),

                // Statut + montant
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: cardAccent.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        color: cardAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _getStatusText(status),
                          style: TextStyle(
                            color: cardAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (appointment['amount'] != null)
                        Text(
                          '${appointment['amount']?.toStringAsFixed(0)} €',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),

                // Boutons action (uniquement pour les RDV à venir)
                if (_currentTabIndex == 0 &&
                    (status == 'pending' || status == 'confirmed')) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Reprogrammer
                          },
                          icon: const Icon(Icons.edit_calendar, size: 16),
                          label: const Text('Modifier'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.primaryColor),
                            foregroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _cancelAppointment(appointment['id'] as String),
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Annuler'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Bouton noter (passés)
                if (_currentTabIndex == 1 && status == 'completed') ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.star_outline, size: 18),
                      label: const Text('Noter la consultation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],

                // Paiement en attente
                if (appointment['paymentStatus'] == 'pending' &&
                    _currentTabIndex == 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.payment, color: Colors.amber.shade700, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Paiement en attente',
                            style: TextStyle(color: Colors.amber.shade800),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.amber.shade800,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                          child: const Text(
                            'Payer',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorRow(Doctor doctor) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: doctor.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: doctor.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _buildDoctorAvatar(doctor.name),
                  )
                : _buildDoctorAvatar(doctor.name),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dr. ${doctor.name}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                doctor.specialization,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (doctor.hospital.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.local_hospital_outlined,
                        size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        doctor.hospital,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorAvatar(String name) {
    return Container(
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'D',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildUnknownDoctor() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline, color: Colors.grey.shade400, size: 28),
          const SizedBox(width: 12),
          Text(
            'Médecin non renseigné',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(width: 10),
        Text(
          '$label :',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ==================== HELPERS ====================

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      } catch (_) {}
    }
    return null;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'vidéo':
      case 'video':
        return Icons.videocam_rounded;
      case 'audio':
      case 'téléphone':
        return Icons.call_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'completed':
        return Icons.done_all_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.access_time_rounded;
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