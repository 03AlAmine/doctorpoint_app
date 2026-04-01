// lib/presentation/pages/doctor/doctor_agenda_page.dart
// CORRECTION DES ERREURS DE LAYOUT

import 'package:doctorpoint/core/constants/app_colors.dart';
import 'package:doctorpoint/presentation/pages/doctor/doctor_availability_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:doctorpoint/data/models/doctor_availability.dart';
import 'package:doctorpoint/services/appointment_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ==================== MODÈLE POUR LES STATISTIQUES ====================

class AppointmentStats {
  final int total;
  final int today;
  final int pending;
  final int completed;
  final double revenue;

  AppointmentStats({
    required this.total,
    required this.today,
    required this.pending,
    required this.completed,
    required this.revenue,
  });
}

// ==================== CLASSES DE DIALOGUES ====================

class AppointmentDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onStatusChanged;

  const AppointmentDetailsDialog({
    super.key,
    required this.appointment,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(appointment['status']);
    final typeColor = _getTypeColor(appointment['type']);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 50,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête avec dégradé
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    typeColor,
                    typeColor.withOpacity(0.7),
                  ],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getTypeIcon(appointment['type'] ?? 'Présentiel'),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          _getStatusText(appointment['status'] ?? 'pending'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appointment['patient'] ?? 'Patient',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appointment['reason'] ?? 'Consultation',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Corps du dialogue
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: _formatDate(appointment['date']),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.access_time,
                    label: 'Heure',
                    value: appointment['time'] ?? '--:--',
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.medical_services,
                    label: 'Type',
                    value: appointment['type'] ?? 'Présentiel',
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.timer,
                    label: 'Durée',
                    value: '${appointment['duration'] ?? 30} minutes',
                  ),
                  if (appointment['notes'] != null &&
                      appointment['notes'].toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.note,
                      label: 'Notes',
                      value: appointment['notes'].toString(),
                      isMultiline: true,
                    ),
                  ],
                ],
              ),
            ),

            // Boutons d'action
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: AppColors.border,
                          ),
                        ),
                      ),
                      child: Text(
                        'Fermer',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Action pour modifier
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: typeColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Modifier',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Date inconnue';
    try {
      return DateFormat('EEEE d MMMM y', 'fr_FR')
          .format(DateFormat('yyyy-MM-dd').parse(dateStr));
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment:
          isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isMultiline ? 14 : 16,
                  color: AppColors.textPrimary,
                  fontWeight: isMultiline ? FontWeight.w400 : FontWeight.w600,
                  height: isMultiline ? 1.4 : 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Vidéo':
        return Icons.videocam;
      case 'Audio':
        return Icons.call;
      default:
        return Icons.person;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Vidéo':
        return Colors.purple;
      case 'Audio':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'confirmé':
        return Colors.green;
      case 'pending':
      case 'en attente':
        return Colors.orange;
      case 'cancelled':
      case 'annulé':
        return Colors.red;
      case 'completed':
      case 'terminé':
        return Colors.blue;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmé';
      case 'pending':
        return 'En attente';
      case 'cancelled':
        return 'Annulé';
      case 'completed':
        return 'Terminé';
      default:
        return status;
    }
  }
}

class AddAppointmentDialog extends StatefulWidget {
  final Doctor doctor;
  final DateTime date;
  final String time;
  final VoidCallback onAppointmentAdded;

  const AddAppointmentDialog({
    super.key,
    required this.doctor,
    required this.date,
    required this.time,
    required this.onAppointmentAdded,
  });

  @override
  State<AddAppointmentDialog> createState() => _AddAppointmentDialogState();
}

class _AddAppointmentDialogState extends State<AddAppointmentDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedType = 'Présentiel';
  final List<String> _appointmentTypes = ['Présentiel', 'Vidéo', 'Audio'];
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _patientNameController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 50,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Nouveau rendez-vous',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      DateFormat('EEEE d MMMM', 'fr_FR')
                                          .format(widget.date),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 24,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.time,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
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
                ),

                // Corps du formulaire
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Nom du patient
                        TextFormField(
                          controller: _patientNameController,
                          decoration: InputDecoration(
                            labelText: 'Nom du patient',
                            hintText: 'Entrez le nom complet',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ce champ est requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Type de consultation
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: InputDecoration(
                            labelText: 'Type de consultation',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.medical_services,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 2),
                            ),
                          ),
                          items: _appointmentTypes.map((type) {
                            IconData icon;
                            Color color;
                            switch (type) {
                              case 'Vidéo':
                                icon = Icons.videocam;
                                color = Colors.purple;
                                break;
                              case 'Audio':
                                icon = Icons.call;
                                color = Colors.blue;
                                break;
                              default:
                                icon = Icons.person;
                                color = AppColors.primary;
                            }
                            return DropdownMenuItem(
                              value: type,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(icon, color: color, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(type),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedType = value!);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Raison
                        TextFormField(
                          controller: _reasonController,
                          decoration: InputDecoration(
                            labelText: 'Raison de la consultation',
                            hintText: 'Ex: Douleurs, suivi, etc.',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.description,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 2),
                            ),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        // Notes
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'Notes supplémentaires',
                            hintText: 'Informations complémentaires...',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.note,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 2),
                            ),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),

                // Boutons
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: AppColors.border),
                            ),
                          ),
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _addAppointment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Ajouter',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
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
      ),
    );
  }

  Future<void> _addAppointment() async {
    if (_formKey.currentState!.validate()) {
      try {
        final appointmentService = AppointmentService();

        final tempPatientId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

        await appointmentService.bookAppointment(
          doctorId: widget.doctor.id,
          patientId: tempPatientId,
          date: widget.date,
          time: widget.time,
          type: _selectedType,
          amount: widget.doctor.consultationFee,
          notes: _notesController.text,
          symptoms: _reasonController.text,
        );

        final appointmentsQuery = await FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: widget.doctor.id)
            .where('date',
                isEqualTo: DateFormat('yyyy-MM-dd').format(widget.date))
            .where('time', isEqualTo: widget.time)
            .where('patientId', isEqualTo: tempPatientId)
            .limit(1)
            .get();

        if (appointmentsQuery.docs.isNotEmpty) {
          await appointmentsQuery.docs.first.reference.update({
            'patientName': _patientNameController.text,
          });
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Rendez-vous ajouté avec succès')),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        widget.onAppointmentAdded();
        if (context.mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Erreur: $e')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }
}

// ==================== CLASSE PRINCIPALE ====================

class DoctorAgendaPage extends StatefulWidget {
  final Doctor doctor;

  const DoctorAgendaPage({super.key, required this.doctor});

  @override
  State<DoctorAgendaPage> createState() => _DoctorAgendaPageState();
}

class _DoctorAgendaPageState extends State<DoctorAgendaPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AppointmentService _appointmentService = AppointmentService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  List<Map<String, dynamic>> _allAppointments = [];
  bool _isLoading = true;
  bool _showCalendar = false;
  List<String> _availableTimeSlots = [];
  DoctorAvailability? _doctorAvailability;
  List<DaySchedule> _weeklySchedule = [];
  String _searchQuery = '';
  String _selectedFilter = 'Tous';
  final List<String> _filters = [
    'Tous',
    'Aujourd\'hui',
    'Cette semaine',
    'Confirmés',
    'En attente'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _loadInitialData().then((_) {
      _animationController.forward();
      if (_selectedDay != null) {
        _loadAvailableTimeSlots(_selectedDay!);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadAvailability(),
      _loadAppointments(),
      _loadWeeklySchedule(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadAvailability() async {
    try {
      final doc = await _db
          .collection('doctor_availability')
          .doc(widget.doctor.id)
          .get();

      if (doc.exists) {
        setState(() {
          _doctorAvailability = DoctorAvailability.fromMap({
            ...doc.data()!,
            'doctorId': widget.doctor.id,
          });
        });
      } else {
        _createDefaultAvailability();
      }
    } catch (e) {
      print('Erreur chargement disponibilité: $e');
    }
  }

  void _createDefaultAvailability() {
    final days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
    final defaultSchedule = days.map((day) {
      final isWeekend = day == 'Samedi' || day == 'Dimanche';
      return DaySchedule(
        day: day,
        isAvailable: !isWeekend,
        timeSlots: !isWeekend
            ? [
                TimeSlot(start: '09:00', end: '12:00'),
                TimeSlot(start: '14:00', end: '18:00'),
              ]
            : [],
        breakTimes: !isWeekend
            ? [TimeSlot(start: '12:00', end: '14:00', isBreak: true)]
            : [],
      );
    }).toList();

    setState(() {
      _doctorAvailability = DoctorAvailability(
        doctorId: widget.doctor.id,
        weeklySchedule: defaultSchedule,
        appointmentDuration: 30,
        bufferTime: 5,
      );
    });
  }

  Future<void> _loadWeeklySchedule() async {
    if (_doctorAvailability != null) {
      setState(() {
        _weeklySchedule = _doctorAvailability!.weeklySchedule;
      });
    }
  }

  Future<void> _loadAppointments() async {
    try {
      final snapshot = await _db
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctor.id)
          .orderBy('date', descending: true)
          .orderBy('time', descending: true)
          .get();

      final events = <DateTime, List<Map<String, dynamic>>>{};
      final allAppointments = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final dateStr = data['date'];

        if (dateStr == null) continue;

        final dateParts = dateStr.split('-');
        if (dateParts.length == 3) {
          final year = int.tryParse(dateParts[0]) ?? DateTime.now().year;
          final month = int.tryParse(dateParts[1]) ?? DateTime.now().month;
          final day = int.tryParse(dateParts[2]) ?? DateTime.now().day;

          final appointmentDate = DateTime(year, month, day);

          final patientId = data['patientId'];
          String patientName = data['patientName'] ?? 'Patient';

          if ((patientName == 'Patient' || patientName.isEmpty) &&
              patientId != null) {
            try {
              final userDoc =
                  await _db.collection('users').doc(patientId).get();
              if (userDoc.exists) {
                final userData = userDoc.data()!;
                patientName = userData['fullName'] ?? 'Patient';
              }
            } catch (e) {
              print('Erreur chargement patient: $e');
            }
          }

          final event = {
            'id': doc.id,
            'patient': patientName,
            'patientId': patientId,
            'date': data['date'] ?? '',
            'time': data['time'] ?? '00:00',
            'type': data['type'] ?? 'Présentiel',
            'status': data['status'] ?? 'Pending',
            'duration': data['duration'] ?? 30,
            'reason': data['reason'] ?? data['symptoms'] ?? 'Consultation',
            'notes': data['notes'] ?? '',
            'amount': (data['amount'] ?? 0.0).toDouble(),
            'dateTime': appointmentDate,
          };

          if (events.containsKey(appointmentDate)) {
            events[appointmentDate]!.add(event);
          } else {
            events[appointmentDate] = [event];
          }

          allAppointments.add(event);
        }
      }

      setState(() {
        _events = events;
        _allAppointments = allAppointments;
      });
    } catch (e) {
      print('Erreur chargement rendez-vous: $e');
    }
  }

  Future<void> _loadAvailableTimeSlots(DateTime date) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final slots = await _appointmentService.getAvailableTimeSlots(
        doctorId: widget.doctor.id,
        date: date,
      );

      setState(() {
        _availableTimeSlots = slots;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement créneaux: $e');
      setState(() {
        _isLoading = false;
        _availableTimeSlots = [];
      });
    }
  }

  AppointmentStats _calculateStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayAppointments = _allAppointments.where((app) {
      try {
        final appDate = DateTime.parse(app['date']);
        return appDate.year == today.year &&
            appDate.month == today.month &&
            appDate.day == today.day;
      } catch (e) {
        return false;
      }
    }).toList();

    final pending = _allAppointments
        .where((app) {
          final status = (app['status'] ?? '').toString().toLowerCase();
          return status == 'pending' || status == 'en attente';
        })
        .length;

    final completed = _allAppointments
        .where((app) {
          final status = (app['status'] ?? '').toString().toLowerCase();
          return status == 'completed' || status == 'terminé';
        })
        .length;

    final revenue = _allAppointments
        .where((app) {
          final status = (app['status'] ?? '').toString().toLowerCase();
          return status == 'completed' || status == 'terminé';
        })
        .fold<double>(0.0, (sum, app) => sum + (app['amount'] as double? ?? 0.0));

    return AppointmentStats(
      total: _allAppointments.length,
      today: todayAppointments.length,
      pending: pending,
      completed: completed,
      revenue: revenue,
    );
  }

  List<Map<String, dynamic>> _getFilteredAppointments() {
    var filtered = List<Map<String, dynamic>>.from(_allAppointments);

    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((app) {
        final patient = (app['patient'] ?? '').toString().toLowerCase();
        final reason = (app['reason'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return patient.contains(query) || reason.contains(query);
      }).toList();
    }

    // Filtre par catégorie
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedFilter) {
      case 'Aujourd\'hui':
        filtered = filtered.where((app) {
          try {
            final appDate = DateTime.parse(app['date']);
            return appDate.year == today.year &&
                appDate.month == today.month &&
                appDate.day == today.day;
          } catch (e) {
            return false;
          }
        }).toList();
        break;
      case 'Cette semaine':
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        filtered = filtered.where((app) {
          try {
            final appDate = DateTime.parse(app['date']);
            return appDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                appDate.isBefore(weekEnd.add(const Duration(days: 1)));
          } catch (e) {
            return false;
          }
        }).toList();
        break;
      case 'Confirmés':
        filtered = filtered
            .where((app) {
              final status = (app['status'] ?? '').toString().toLowerCase();
              return status == 'confirmed' || status == 'confirmé';
            })
            .toList();
        break;
      case 'En attente':
        filtered = filtered
            .where((app) {
              final status = (app['status'] ?? '').toString().toLowerCase();
              return status == 'pending' || status == 'en attente';
            })
            .toList();
        break;
    }

    return filtered;
  }

  Widget _buildStatsSection() {
    final stats = _calculateStats();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.accent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
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
                    'Aperçu des rendez-vous',
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
                      icon: Icons.pending_actions,
                      value: stats.pending.toString(),
                      label: 'En attente',
                      color: Colors.orange.shade200,
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.euro,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Revenus du mois: ${stats.revenue.toStringAsFixed(0)} €',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
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

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterBar() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Barre de recherche
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un patient...',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.search,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filtres
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(filter),
                        onSelected: (selected) {
                          setState(() => _selectedFilter = filter);
                        },
                        backgroundColor: Colors.white,
                        selectedColor: AppColors.primary.withOpacity(0.1),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // CORRECTION : Remplacer ListView par Column dans un SingleChildScrollView
  Widget _buildAppointmentsList() {
    final filteredAppointments = _getFilteredAppointments();

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (filteredAppointments.isEmpty) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_busy,
                  size: 60,
                  color: AppColors.primary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Aucun rendez-vous',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Aucun résultat pour "$_searchQuery"'
                    : 'Les rendez-vous apparaîtront ici',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              if (_searchQuery.isNotEmpty) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() => _searchQuery = ''),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Effacer la recherche'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          children: filteredAppointments.asMap().entries.map((entry) {
            return _buildAppointmentCard(entry.value, entry.key);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, int index) {
    final statusColor = _getStatusColor(appointment['status']);
    final typeColor = _getTypeColor(appointment['type']);
    
    DateTime date;
    try {
      date = DateTime.parse(appointment['date']);
    } catch (e) {
      date = DateTime.now();
    }

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showAppointmentDetails(appointment),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Indicateur de date
                  Container(
                    width: 60,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          typeColor.withOpacity(0.1),
                          typeColor.withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('d', 'fr_FR').format(date),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: typeColor,
                          ),
                        ),
                        Text(
                          DateFormat('MMM', 'fr_FR')
                              .format(date)
                              .replaceAll('.', ''),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: typeColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Informations principales
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                appointment['patient'] ?? 'Patient',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(appointment['status']),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              appointment['time'] ?? '--:--',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              _getTypeIcon(appointment['type']),
                              size: 14,
                              color: typeColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              appointment['type'] ?? 'Présentiel',
                              style: TextStyle(
                                fontSize: 13,
                                color: typeColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          appointment['reason'] ?? 'Consultation',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Flèche d'action
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarToggle() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() => _showCalendar = !_showCalendar);
                HapticFeedback.lightImpact();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _showCalendar ? Icons.view_list : Icons.calendar_month,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _showCalendar
                                ? 'Afficher la liste'
                                : 'Afficher le calendrier',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _showCalendar
                                ? 'Retour à la vue liste'
                                : 'Voir tous les rendez-vous par date',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _showCalendar
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    if (!_showCalendar) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                selectedTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                weekendTextStyle: const TextStyle(color: Colors.red),
                outsideDaysVisible: false,
                markerDecoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                markerSize: 6,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: AppColors.primary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: AppColors.primary,
                ),
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) async {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                await _loadAvailableTimeSlots(selectedDay);
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = focusedDay);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.add_circle,
                  label: 'Nouveau RDV',
                  color: AppColors.primary,
                  onTap: () {
                    if (_selectedDay != null &&
                        _availableTimeSlots.isNotEmpty) {
                      _showAddAppointmentDialog(_availableTimeSlots.first);
                    } else {
                      _showNoSlotDialog();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.settings,
                  label: 'Disponibilités',
                  color: AppColors.accent,
                  onTap: showAvailabilitySettings,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoSlotDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber,
                  size: 48,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucun créneau disponible',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Configurez vos disponibilités pour pouvoir ajouter des rendez-vous',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        showAvailabilitySettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Configurer'),
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

  void _showAddAppointmentDialog(String timeSlot) {
    showDialog(
      context: context,
      builder: (context) => AddAppointmentDialog(
        doctor: widget.doctor,
        date: _selectedDay!,
        time: timeSlot,
        onAppointmentAdded: () {
          _loadAppointments();
          _loadAvailableTimeSlots(_selectedDay!);
        },
      ),
    );
  }

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AppointmentDetailsDialog(
        appointment: appointment,
        onStatusChanged: _loadAppointments,
      ),
    );
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Vidéo':
        return Icons.videocam;
      case 'Audio':
        return Icons.call;
      default:
        return Icons.person;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Vidéo':
        return Colors.purple;
      case 'Audio':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'confirmé':
        return Colors.green;
      case 'pending':
      case 'en attente':
        return Colors.orange;
      case 'cancelled':
      case 'annulé':
        return Colors.red;
      case 'completed':
      case 'terminé':
        return Colors.blue;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmé';
      case 'pending':
        return 'En attente';
      case 'cancelled':
        return 'Annulé';
      case 'completed':
        return 'Terminé';
      default:
        return status;
    }
  }

  void showAvailabilitySettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorAvailabilityPage(
          doctor: widget.doctor,
          availability: _doctorAvailability,
          onAvailabilityUpdated: () {
            _loadAvailability();
            _loadWeeklySchedule();
            if (_selectedDay != null) {
              _loadAvailableTimeSlots(_selectedDay!);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Chargement de votre agenda...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildStatsSection(),
                ),
                SliverToBoxAdapter(
                  child: _buildCalendarToggle(),
                ),
                SliverToBoxAdapter(
                  child: _buildCalendar(),
                ),
                SliverToBoxAdapter(
                  child: _buildSearchAndFilterBar(),
                ),
                SliverToBoxAdapter(
                  child: _buildQuickActions(),
                ),
                // CORRECTION : Utiliser SliverList au lieu de SliverToBoxAdapter
                SliverPadding(
                  padding: const EdgeInsets.only(top: 8),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildAppointmentsList(),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}