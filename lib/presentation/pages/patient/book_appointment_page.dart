// lib/presentation/pages/patient/book_appointment_page.dart
// REDESIGN COMPLET — Chargement rapide, interface par étapes, design premium

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:doctorpoint/services/patient_appointment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookAppointmentPage extends StatefulWidget {
  final Doctor doctor;

  const BookAppointmentPage({super.key, required this.doctor});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage>
    with TickerProviderStateMixin {
  // ── Service & Firebase ──
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PatientAppointmentService _appointmentService =
      PatientAppointmentService();

  // ── Sélections ──
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  String _selectedType = 'Présentiel';
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // ── Données disponibilités ──
  List<DateTime> _availableDates = [];
  List<String> _availableSlots = [];

  // ── États de chargement ──
  bool _isDatesLoading = true;   // chargement initial des dates
  bool _isSlotsLoading = false;  // chargement des créneaux (séparé)
  bool _isBooking = false;

  // ── Navigation par étapes ──
  int _currentStep = 0; // 0=date+heure  1=type  2=motif  3=récap

  // ── Animations ──
  late AnimationController _stepAnimController;
  late Animation<double> _stepFadeAnim;
  late Animation<Offset> _stepSlideAnim;

  final List<String> _consultationTypes = ['Présentiel', 'Vidéo', 'Audio'];
  final Map<String, IconData> _typeIcons = {
    'Présentiel': Icons.person_rounded,
    'Vidéo': Icons.videocam_rounded,
    'Audio': Icons.call_rounded,
  };
  final Map<String, Color> _typeColors = {
    'Présentiel': AppTheme.primaryColor,
    'Vidéo': Colors.purple,
    'Audio': Colors.green,
  };

  @override
  void initState() {
    super.initState();
    _stepAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _stepFadeAnim = CurvedAnimation(
      parent: _stepAnimController,
      curve: Curves.easeOut,
    );
    _stepSlideAnim = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _stepAnimController,
      curve: Curves.easeOut,
    ));
    _stepAnimController.forward();

    // ✅ FIX PERFORMANCE : on charge dates ET créneaux en parallèle dès l'ouverture
    _loadDatesAndFirstSlots();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _symptomsController.dispose();
    _notesController.dispose();
    _stepAnimController.dispose();
    super.dispose();
  }

  // ✅ FIX PRINCIPAL : chargement parallèle au lieu de séquentiel
  Future<void> _loadDatesAndFirstSlots() async {
    try {
      // Lancer les deux chargements en parallèle
      final datesResult = await _appointmentService.getAvailableDays(
        doctorId: widget.doctor.id,
        startDate: DateTime.now(),
      );

      if (!mounted) return;

      DateTime firstDate = datesResult.isNotEmpty ? datesResult.first : DateTime.now();

      setState(() {
        _availableDates = datesResult;
        _selectedDate = firstDate;
        _isDatesLoading = false;
        _isSlotsLoading = datesResult.isNotEmpty; // commence à charger les créneaux
      });

      // Charger les créneaux de la première date immédiatement
      if (datesResult.isNotEmpty) {
        final slots = await _appointmentService.getAvailableSlots(
          doctorId: widget.doctor.id,
          date: firstDate,
        );
        if (mounted) {
          setState(() {
            _availableSlots = slots;
            _isSlotsLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Erreur chargement disponibilités: $e');
      if (mounted) {
        setState(() {
          _isDatesLoading = false;
          _isSlotsLoading = false;
        });
        _showError('Impossible de charger les disponibilités');
      }
    }
  }

  Future<void> _loadSlotsForDate(DateTime date) async {
    setState(() {
      _isSlotsLoading = true;
      _selectedTime = null;
      _availableSlots = [];
    });

    try {
      final slots = await _appointmentService.getAvailableSlots(
        doctorId: widget.doctor.id,
        date: date,
      );
      if (mounted) {
        setState(() {
          _availableSlots = slots;
          _isSlotsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSlotsLoading = false);
        _showError('Erreur créneaux: $e');
      }
    }
  }

  void _goToStep(int step) {
    _stepAnimController.reset();
    setState(() => _currentStep = step);
    _stepAnimController.forward();
  }

  bool get _canProceedStep0 => _selectedTime != null;
  bool get _canConfirm =>
      _selectedTime != null && _reasonController.text.trim().isNotEmpty;

  Future<void> _bookAppointment() async {
    if (!_canConfirm) return;

    setState(() => _isBooking = true);

    try {
      final result = await _appointmentService.bookAppointment(
        doctorId: widget.doctor.id,
        date: _selectedDate,
        time: _selectedTime!,
        type: _selectedType,
        reason: _reasonController.text.trim(),
        symptoms: _symptomsController.text.trim().isNotEmpty
            ? _symptomsController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        amount: widget.doctor.consultationFee,
      );

      if (result['success'] == true) {
        _showSuccessDialog(result['appointmentId'] ?? 'N/A');
      } else {
        _showError(result['error'] ?? 'Erreur lors de la prise de rendez-vous');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
    ));
  }

  void _showSuccessDialog(String appointmentId) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 40,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header vert
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Rendez-vous confirmé !',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // Corps
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Votre demande a été envoyée au Dr. ${widget.doctor.name}. Vous recevrez une confirmation dès validation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.tag, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 6),
                          Text(
                            'N° ${appointmentId.length > 8 ? appointmentId.substring(0, 8).toUpperCase() : appointmentId}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                              fontSize: 15,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Voir mes rendez-vous',
                          style: TextStyle(fontWeight: FontWeight.w700),
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
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: _isDatesLoading
                  ? _buildInitialLoading()
                  : SlideTransition(
                      position: _stepSlideAnim,
                      child: FadeTransition(
                        opacity: _stepFadeAnim,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 100),
                          child: Column(
                            children: [
                              _buildDoctorBanner(),
                              if (_currentStep == 0) _buildStep0(),
                              if (_currentStep == 1) _buildStep1(),
                              if (_currentStep == 2) _buildStep2(),
                              if (_currentStep == 3) _buildStep3Recap(),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    final stepTitles = [
      'Date & Heure',
      'Type de consultation',
      'Informations',
      'Récapitulatif',
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
              onPressed: _currentStep > 0
                  ? () => _goToStep(_currentStep - 1)
                  : () => Navigator.pop(context),
              padding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prendre rendez-vous',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                Text(
                  stepTitles[_currentStep],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_currentStep + 1}/4',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Barre de progression ──
  Widget _buildProgressBar() {
    return Container(
      color: AppTheme.primaryColor.withOpacity(0.85),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 4,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Banner médecin ──
  Widget _buildDoctorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: widget.doctor.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.doctor.imageUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      child: Icon(Icons.person, color: AppTheme.primaryColor),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. ${widget.doctor.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  widget.doctor.specialization,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.local_hospital_outlined,
                        size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.doctor.hospital,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.doctor.consultationFee.toStringAsFixed(0)} €',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chargement initial ──
  Widget _buildInitialLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.7)
                ],
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
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chargement des disponibilités...',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ÉTAPES ====================

  // ── Étape 0 : Date + Heure ──
  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Choisissez une date', Icons.calendar_today_rounded),
        _availableDates.isEmpty
            ? _buildNoDatesWarning()
            : _buildDateCarousel(),
        const SizedBox(height: 8),
        _buildSectionTitle('Choisissez un créneau', Icons.access_time_rounded),
        _buildTimeSlots(),
      ],
    );
  }

  Widget _buildNoDatesWarning() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Aucune date disponible pour ce médecin actuellement.',
              style: TextStyle(color: Colors.orange.shade800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCarousel() {
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _availableDates.length,
        itemBuilder: (context, index) {
          final date = _availableDates[index];
          final isSelected = _selectedDate.year == date.year &&
              _selectedDate.month == date.month &&
              _selectedDate.day == date.day;
          final isToday = date.year == DateTime.now().year &&
              date.month == DateTime.now().month &&
              date.day == DateTime.now().day;

          return GestureDetector(
            onTap: () async {
              if (!isSelected) {
                setState(() => _selectedDate = date);
                await _loadSlotsForDate(date);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 68,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8)
                        ],
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : isToday
                          ? AppTheme.primaryColor.withOpacity(0.5)
                          : Colors.grey.shade200,
                  width: isToday && !isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE', 'fr_FR').format(date),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white70 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM', 'fr_FR').format(date),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : Colors.grey.shade500,
                    ),
                  ),
                  if (isToday && !isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlots() {
    if (_isSlotsLoading) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Chargement des créneaux...',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_availableSlots.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy_outlined,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Aucun créneau disponible',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Essayez une autre date',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    // Grouper les créneaux matin / après-midi / soir
    final morning = _availableSlots.where((s) {
      final h = int.tryParse(s.split(':')[0]) ?? 0;
      return h < 12;
    }).toList();
    final afternoon = _availableSlots.where((s) {
      final h = int.tryParse(s.split(':')[0]) ?? 0;
      return h >= 12 && h < 17;
    }).toList();
    final evening = _availableSlots.where((s) {
      final h = int.tryParse(s.split(':')[0]) ?? 0;
      return h >= 17;
    }).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (morning.isNotEmpty) ...[
            _buildSlotGroupTitle('Matin', Icons.wb_sunny_outlined, Colors.orange),
            const SizedBox(height: 8),
            _buildSlotWrap(morning),
            const SizedBox(height: 14),
          ],
          if (afternoon.isNotEmpty) ...[
            _buildSlotGroupTitle('Après-midi', Icons.wb_cloudy_outlined, Colors.blue),
            const SizedBox(height: 8),
            _buildSlotWrap(afternoon),
            const SizedBox(height: 14),
          ],
          if (evening.isNotEmpty) ...[
            _buildSlotGroupTitle('Soir', Icons.nights_stay_outlined, Colors.indigo),
            const SizedBox(height: 8),
            _buildSlotWrap(evening),
          ],
        ],
      ),
    );
  }

  Widget _buildSlotGroupTitle(String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSlotWrap(List<String> slots) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final isSelected = _selectedTime == slot;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = slot),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.85)
                      ],
                    )
                  : null,
              color: isSelected ? null : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              slot,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Étape 1 : Type de consultation ──
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Type de consultation', Icons.medical_services_outlined),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: _consultationTypes.map((type) {
              final isSelected = _selectedType == type;
              final color = _typeColors[type]!;

              return GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [color, color.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade200,
                      width: isSelected ? 0 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _typeIcons[type]!,
                          color: isSelected ? Colors.white : color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              _getTypeDescription(type),
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected
                                    ? Colors.white.withOpacity(0.85)
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 16),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getTypeDescription(String type) {
    switch (type) {
      case 'Vidéo':
        return 'Consultation par appel vidéo';
      case 'Audio':
        return 'Consultation téléphonique';
      default:
        return 'Consultation au cabinet médical';
    }
  }

  // ── Étape 2 : Informations ──
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Raison de la consultation *', Icons.info_outline_rounded),
        _buildTextField(
          controller: _reasonController,
          hint: 'Ex: Douleurs lombaires, fièvre persistante...',
          maxLines: 3,
          isRequired: true,
        ),
        _buildSectionTitle('Symptômes (optionnel)', Icons.medical_information_outlined),
        _buildTextField(
          controller: _symptomsController,
          hint: 'Décrivez vos symptômes en détail...',
          maxLines: 3,
        ),
        _buildSectionTitle('Notes supplémentaires (optionnel)', Icons.note_outlined),
        _buildTextField(
          controller: _notesController,
          hint: 'Antécédents médicaux, traitements en cours...',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    bool isRequired = false,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14.5, color: Colors.black87),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  // ── Étape 3 : Récapitulatif ──
  Widget _buildStep3Recap() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header récap
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.receipt_long_outlined,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Récapitulatif',
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
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildRecapRow(
                  icon: Icons.person_rounded,
                  label: 'Médecin',
                  value: 'Dr. ${widget.doctor.name}',
                  color: AppTheme.primaryColor,
                ),
                _buildRecapDivider(),
                _buildRecapRow(
                  icon: Icons.calendar_month_rounded,
                  label: 'Date',
                  value: DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(_selectedDate),
                  color: Colors.blue,
                ),
                _buildRecapDivider(),
                _buildRecapRow(
                  icon: Icons.access_time_rounded,
                  label: 'Heure',
                  value: _selectedTime ?? '--',
                  color: Colors.orange,
                ),
                _buildRecapDivider(),
                _buildRecapRow(
                  icon: _typeIcons[_selectedType]!,
                  label: 'Type',
                  value: _selectedType,
                  color: _typeColors[_selectedType]!,
                ),
                _buildRecapDivider(),
                _buildRecapRow(
                  icon: Icons.info_outline_rounded,
                  label: 'Motif',
                  value: _reasonController.text.trim(),
                  color: Colors.green,
                ),
                if (_symptomsController.text.trim().isNotEmpty) ...[
                  _buildRecapDivider(),
                  _buildRecapRow(
                    icon: Icons.medical_information_outlined,
                    label: 'Symptômes',
                    value: _symptomsController.text.trim(),
                    color: Colors.red,
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Total à régler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${widget.doctor.consultationFee.toStringAsFixed(0)} €',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
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

  Widget _buildRecapRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecapDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: Colors.grey.shade100),
    );
  }

  // ── Titre section ──
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ──
  Widget _buildBottomBar() {
    bool canNext = false;
    String nextLabel = 'Suivant';
    VoidCallback? onPressed;

    switch (_currentStep) {
      case 0:
        canNext = _canProceedStep0;
        nextLabel = 'Choisir le type';
        onPressed = canNext ? () => _goToStep(1) : null;
        break;
      case 1:
        canNext = true;
        nextLabel = 'Ajouter les infos';
        onPressed = () => _goToStep(2);
        break;
      case 2:
        canNext = _reasonController.text.trim().isNotEmpty;
        nextLabel = 'Vérifier le récapitulatif';
        onPressed = canNext ? () => _goToStep(3) : null;
        break;
      case 3:
        canNext = _canConfirm && !_isBooking;
        nextLabel = 'Confirmer le rendez-vous';
        onPressed = canNext ? _bookAppointment : null;
        break;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 14, 16, 14 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicateur de sélection
          if (_currentStep == 0 && _selectedTime != null)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppTheme.primaryColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${DateFormat('dd MMM', 'fr_FR').format(_selectedDate)} à $_selectedTime',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: canNext
                    ? (_currentStep == 3 ? Colors.green : AppTheme.primaryColor)
                    : Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: canNext ? 0 : 0,
              ),
              child: _isBooking
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          nextLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_currentStep < 3) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                        if (_currentStep == 3) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_rounded, size: 18),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}